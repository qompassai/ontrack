use anyhow::{anyhow, Result};
#[cfg(not(target_arch = "wasm32"))]
use reqwest::blocking::Client;
use serde::Deserialize;
#[cfg(not(target_arch = "wasm32"))]
use std::time::Duration;

#[cfg(not(target_arch = "wasm32"))]
use crate::config::OSRM_PUBLIC;
#[cfg(target_arch = "wasm32")]
use crate::config::OSRM_PUBLIC_DEFAULT;
use crate::geocoder::Location;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Backend {
    Osrm,
    Google,
    Haversine,
}

impl Backend {
    pub fn parse(s: &str) -> Result<Self> {
        match s.to_ascii_lowercase().as_str() {
            "osrm" => Ok(Self::Osrm),
            "google" => Ok(Self::Google),
            "haversine" => Ok(Self::Haversine),
            other => Err(anyhow!("invalid backend: {other}")),
        }
    }
}

pub fn haversine(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
    // Precondition: inputs must be valid WGS84 coordinates. Callers that pass
    // `unwrap_or(0.0)` placeholders for unresolved locations are expected to
    // filter those out before reaching this function (see `is_resolved()`).
    debug_assert!(lat1.is_finite() && lng1.is_finite() && lat2.is_finite() && lng2.is_finite());
    debug_assert!((-90.0..=90.0).contains(&lat1) && (-90.0..=90.0).contains(&lat2));
    debug_assert!((-180.0..=180.0).contains(&lng1) && (-180.0..=180.0).contains(&lng2));

    let r = 6_371_000.0_f64;
    let phi1 = lat1.to_radians();
    let phi2 = lat2.to_radians();
    let dphi = (lat2 - lat1).to_radians();
    let dlam = (lng2 - lng1).to_radians();
    let a = (dphi / 2.0).sin().powi(2) + phi1.cos() * phi2.cos() * (dlam / 2.0).sin().powi(2);
    let dist = r * 2.0 * a.sqrt().asin();

    // Postcondition: a distance is never negative and never exceeds half the
    // Earth's circumference (the great-circle max between any two points).
    debug_assert!(dist.is_finite() && dist >= 0.0 && dist <= std::f64::consts::PI * r);
    dist
}

#[cfg(not(target_arch = "wasm32"))]
fn http_client() -> Result<Client> {
    Client::builder()
        .user_agent("ontrack/2.0")
        .timeout(Duration::from_secs(30))
        .build()
        .map_err(|e| anyhow!("http client build: {e}"))
}

#[cfg(target_arch = "wasm32")]
fn http_client_async() -> Result<reqwest::Client> {
    // No `.timeout(..)`: reqwest's fetch backend on wasm has no
    // per-request timeout API (the builder method does not exist there).
    reqwest::Client::builder()
        .user_agent("ontrack/2.0")
        .build()
        .map_err(|e| anyhow!("http client build: {e}"))
}

#[derive(Deserialize)]
struct OsrmResp {
    code: String,
    #[serde(default)]
    message: Option<String>,
    #[serde(default)]
    durations: Option<Vec<Vec<f64>>>,
}

/// Builds the OSRM `/table` request URL shared by both client variants.
fn osrm_table_url(locations: &[&Location], base_url: &str) -> String {
    let coords: Vec<String> = locations
        .iter()
        .map(|l| format!("{},{}", l.lng.unwrap_or(0.0), l.lat.unwrap_or(0.0)))
        .collect();
    format!("{}/table/v1/driving/{}", base_url, coords.join(";"))
}

/// Validates an OSRM table response and extracts the duration matrix.
fn osrm_durations(resp: OsrmResp, n: usize) -> Result<Vec<Vec<f64>>> {
    if resp.code != "Ok" {
        return Err(anyhow!(
            "OSRM error: {}",
            resp.message.unwrap_or_else(|| "unknown".to_string())
        ));
    }
    let durations = resp
        .durations
        .ok_or_else(|| anyhow!("OSRM response missing durations"))?;

    // Postcondition: OSRM must return a square matrix matching the number of
    // coordinates we requested — a malformed/truncated response here would
    // silently corrupt the solver's input otherwise.
    if durations.len() != n || durations.iter().any(|row| row.len() != n) {
        return Err(anyhow!(
            "OSRM matrix shape mismatch: expected {n}x{n}, got {r}x{c}",
            r = durations.len(),
            c = durations.first().map_or(0, |row| row.len())
        ));
    }
    Ok(durations)
}

#[cfg(not(target_arch = "wasm32"))]
fn osrm_matrix(locations: &[&Location], base_url: &str) -> Result<Vec<Vec<f64>>> {
    let resp: OsrmResp = http_client()?
        .get(osrm_table_url(locations, base_url))
        .query(&[("annotations", "duration,distance")])
        .send()?
        .error_for_status()?
        .json()?;
    osrm_durations(resp, locations.len())
}

#[cfg(target_arch = "wasm32")]
async fn osrm_matrix_async(locations: &[&Location], base_url: &str) -> Result<Vec<Vec<f64>>> {
    let resp: OsrmResp = http_client_async()?
        .get(osrm_table_url(locations, base_url))
        .query(&[("annotations", "duration,distance")])
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;
    osrm_durations(resp, locations.len())
}

#[derive(Deserialize)]
struct GoogleResp {
    status: String,
    rows: Vec<GoogleRow>,
}
#[derive(Deserialize)]
struct GoogleRow {
    elements: Vec<GoogleElem>,
}
#[derive(Deserialize)]
struct GoogleElem {
    status: String,
    #[serde(default)]
    duration: Option<GoogleDur>,
}
#[derive(Deserialize)]
struct GoogleDur {
    value: f64,
}

/// Formats a coordinate range as Google's `lat,lng|lat,lng` list syntax.
fn google_coords(locations: &[&Location]) -> String {
    locations
        .iter()
        .map(|l| format!("{},{}", l.lat.unwrap_or(0.0), l.lng.unwrap_or(0.0)))
        .collect::<Vec<_>>()
        .join("|")
}

/// Merges one Google Distance Matrix batch (origins from row `i`,
/// destinations from column `j`) into the full matrix.
fn apply_google_batch(
    matrix: &mut [Vec<f64>],
    resp: &GoogleResp,
    locations: &[&Location],
    i: usize,
    j: usize,
) -> Result<()> {
    if resp.status != "OK" {
        return Err(anyhow!("Google API error: {}", resp.status));
    }

    for (ri, row) in resp.rows.iter().enumerate() {
        for (ci, elem) in row.elements.iter().enumerate() {
            let val = if elem.status == "OK" {
                elem.duration.as_ref().map(|d| d.value).unwrap_or(0.0)
            } else {
                let a = locations[i + ri];
                let b = locations[j + ci];
                haversine(
                    a.lat.unwrap_or(0.0),
                    a.lng.unwrap_or(0.0),
                    b.lat.unwrap_or(0.0),
                    b.lng.unwrap_or(0.0),
                )
            };
            matrix[i + ri][j + ci] = val;
        }
    }
    Ok(())
}

#[cfg(not(target_arch = "wasm32"))]
fn google_matrix(locations: &[&Location], api_key: &str) -> Result<Vec<Vec<f64>>> {
    let n = locations.len();
    let mut matrix = vec![vec![0.0_f64; n]; n];
    let batch = 10usize;

    for i in (0..n).step_by(batch) {
        let i_end = (i + batch).min(n);
        let origins = google_coords(&locations[i..i_end]);

        for j in (0..n).step_by(batch) {
            let j_end = (j + batch).min(n);
            let dests = google_coords(&locations[j..j_end]);

            let resp: GoogleResp = http_client()?
                .get("https://maps.googleapis.com/maps/api/distancematrix/json")
                .query(&[
                    ("origins", &origins),
                    ("destinations", &dests),
                    ("key", &api_key.to_string()),
                ])
                .send()?
                .error_for_status()?
                .json()?;

            apply_google_batch(&mut matrix, &resp, locations, i, j)?;
        }
    }
    Ok(matrix)
}

#[cfg(target_arch = "wasm32")]
async fn google_matrix_async(locations: &[&Location], api_key: &str) -> Result<Vec<Vec<f64>>> {
    let n = locations.len();
    let mut matrix = vec![vec![0.0_f64; n]; n];
    let batch = 10usize;

    for i in (0..n).step_by(batch) {
        let i_end = (i + batch).min(n);
        let origins = google_coords(&locations[i..i_end]);

        for j in (0..n).step_by(batch) {
            let j_end = (j + batch).min(n);
            let dests = google_coords(&locations[j..j_end]);

            let resp: GoogleResp = http_client_async()?
                .get("https://maps.googleapis.com/maps/api/distancematrix/json")
                .query(&[
                    ("origins", &origins),
                    ("destinations", &dests),
                    ("key", &api_key.to_string()),
                ])
                .send()
                .await?
                .error_for_status()?
                .json()
                .await?;

            apply_google_batch(&mut matrix, &resp, locations, i, j)?;
        }
    }
    Ok(matrix)
}

fn haversine_matrix(locations: &[&Location]) -> Vec<Vec<f64>> {
    // Precondition: every location passed here must already be resolved —
    // `build_distance_matrix` filters unresolved locations before calling.
    debug_assert!(locations.iter().all(|l| l.is_resolved()));

    let n = locations.len();
    let mut m = vec![vec![0.0_f64; n]; n];
    for i in 0..n {
        for j in (i + 1)..n {
            let d = haversine(
                locations[i].lat.unwrap_or(0.0),
                locations[i].lng.unwrap_or(0.0),
                locations[j].lat.unwrap_or(0.0),
                locations[j].lng.unwrap_or(0.0),
            );
            m[i][j] = d;
            m[j][i] = d;
        }
    }

    // Postcondition: distance matrix is square and the diagonal is zero.
    debug_assert!(m.len() == n && m.iter().all(|row| row.len() == n));
    debug_assert!((0..n).all(|i| m[i][i] == 0.0));
    m
}

/// The subset of `locations` that geocoding resolved to coordinates.
fn resolved_locations(locations: &[Location]) -> Result<Vec<&Location>> {
    let resolved: Vec<&Location> = locations.iter().filter(|l| l.is_resolved()).collect();
    if resolved.is_empty() {
        return Err(anyhow!("no geocoded locations available to build matrix"));
    }
    Ok(resolved)
}

/// Extracts a usable Google API key or explains why the backend can't run.
fn google_key(google_api_key: Option<&str>) -> Result<&str> {
    google_api_key
        .filter(|k| !k.is_empty())
        .ok_or_else(|| anyhow!("Google backend requires an API key"))
}

/// Enforces the square-matrix postcondition every backend must satisfy:
/// whichever backend produced the matrix, callers (the solver) rely
/// absolutely on it being an n x n square — enforce that contract here
/// once rather than trusting every backend individually.
fn check_square(matrix: Vec<Vec<f64>>, n: usize) -> Vec<Vec<f64>> {
    assert!(
        matrix.len() == n && matrix.iter().all(|row| row.len() == n),
        "distance matrix backend returned a non-square {}x{} matrix for {} locations",
        matrix.len(),
        matrix.first().map_or(0, |row| row.len()),
        n
    );
    matrix
}

#[cfg(not(target_arch = "wasm32"))]
pub fn build_distance_matrix(
    locations: &[Location],
    backend: Backend,
    osrm_url: Option<&str>,
    google_api_key: Option<&str>,
) -> Result<Vec<Vec<f64>>> {
    let resolved = resolved_locations(locations)?;
    let n = resolved.len();

    let matrix = match backend {
        Backend::Osrm => osrm_matrix(&resolved, osrm_url.unwrap_or(OSRM_PUBLIC)),
        Backend::Google => google_matrix(&resolved, google_key(google_api_key)?),
        Backend::Haversine => Ok(haversine_matrix(&resolved)),
    }?;

    Ok(check_square(matrix, n))
}

/// Async counterpart of [`build_distance_matrix`] for the browser build,
/// where reqwest runs on the fetch API. Same backends, same postcondition.
#[cfg(target_arch = "wasm32")]
pub async fn build_distance_matrix_async(
    locations: &[Location],
    backend: Backend,
    osrm_url: Option<&str>,
    google_api_key: Option<&str>,
) -> Result<Vec<Vec<f64>>> {
    let resolved = resolved_locations(locations)?;
    let n = resolved.len();

    let matrix = match backend {
        Backend::Osrm => {
            osrm_matrix_async(&resolved, osrm_url.unwrap_or(OSRM_PUBLIC_DEFAULT)).await
        }
        Backend::Google => google_matrix_async(&resolved, google_key(google_api_key)?).await,
        Backend::Haversine => Ok(haversine_matrix(&resolved)),
    }?;

    Ok(check_square(matrix, n))
}
