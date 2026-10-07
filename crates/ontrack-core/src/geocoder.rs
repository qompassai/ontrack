use anyhow::{anyhow, Result};
#[cfg(not(target_arch = "wasm32"))]
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
#[cfg(not(target_arch = "wasm32"))]
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Location {
    pub address: String,
    pub lat: Option<f64>,
    pub lng: Option<f64>,
}

impl Location {
    pub fn new(address: impl Into<String>) -> Self {
        Self {
            address: address.into(),
            lat: None,
            lng: None,
        }
    }
    pub fn is_resolved(&self) -> bool {
        self.lat.is_some() && self.lng.is_some()
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn http_client() -> Result<Client> {
    Client::builder()
        .user_agent("ontrack/2.0 (TDS Telecom field router)")
        .timeout(Duration::from_secs(10))
        .build()
        .map_err(|e| anyhow!("http client build: {e}"))
}

#[derive(Deserialize)]
struct NominatimHit {
    lat: String,
    lon: String,
}

#[cfg(not(target_arch = "wasm32"))]
pub fn geocode_address_nominatim(addr: &str) -> Result<Location> {
    let client = http_client()?;
    let resp: Vec<NominatimHit> = client
        .get("https://nominatim.openstreetmap.org/search")
        .query(&[("q", addr), ("format", "json"), ("limit", "1")])
        .send()?
        .error_for_status()?
        .json()?;

    let mut loc = Location::new(addr);
    if let Some(hit) = resp.first() {
        loc.lat = hit.lat.parse().ok();
        loc.lng = hit.lon.parse().ok();
    }
    Ok(loc)
}

#[derive(Deserialize)]
struct GoogleGeoResp {
    status: String,
    results: Vec<GoogleGeoResult>,
}
#[derive(Deserialize)]
struct GoogleGeoResult {
    geometry: GoogleGeoGeom,
}
#[derive(Deserialize)]
struct GoogleGeoGeom {
    location: LatLng,
}
#[derive(Deserialize)]
struct LatLng {
    lat: f64,
    lng: f64,
}

#[cfg(not(target_arch = "wasm32"))]
pub fn geocode_address_google(addr: &str, api_key: &str) -> Result<Location> {
    let client = http_client()?;
    let resp: GoogleGeoResp = client
        .get("https://maps.googleapis.com/maps/api/geocode/json")
        .query(&[("address", addr), ("key", api_key)])
        .send()?
        .error_for_status()?
        .json()?;

    let mut loc = Location::new(addr);
    if resp.status == "OK" {
        if let Some(r) = resp.results.first() {
            loc.lat = Some(r.geometry.location.lat);
            loc.lng = Some(r.geometry.location.lng);
        }
    }
    Ok(loc)
}

#[cfg(not(target_arch = "wasm32"))]
pub fn geocode_addresses(
    addresses: &[String],
    use_google: bool,
    google_api_key: Option<&str>,
    mut progress: Option<&mut dyn FnMut(usize, usize)>,
) -> Vec<Location> {
    let key = google_api_key.unwrap_or("");
    let total = addresses.len();
    let mut out = Vec::with_capacity(total);

    for (i, addr) in addresses.iter().enumerate() {
        let result = if use_google && !key.is_empty() {
            geocode_address_google(addr, key)
        } else {
            geocode_address_nominatim(addr)
        };
        out.push(result.unwrap_or_else(|_| Location::new(addr.clone())));
        if let Some(cb) = progress.as_deref_mut() {
            cb(i + 1, total);
        }
    }
    out
}

#[cfg(not(target_arch = "wasm32"))]
#[derive(Deserialize)]
struct IpApiResp {
    status: String,
    lat: Option<f64>,
    lon: Option<f64>,
}

/// IP-based coarse location. Native only: the endpoint is plain HTTP,
/// which browsers block as mixed content from an HTTPS page, and the
/// browser build offers no replacement permission flow.
#[cfg(not(target_arch = "wasm32"))]
pub fn get_current_location() -> Option<Location> {
    let client = http_client().ok()?;
    let resp: IpApiResp = client
        .get("http://ip-api.com/json/?fields=lat,lon,status")
        .send()
        .ok()?
        .json()
        .ok()?;
    if resp.status == "success" {
        Some(Location {
            address: "Current Location".to_string(),
            lat: resp.lat,
            lng: resp.lon,
        })
    } else {
        None
    }
}

// ---------------------------------------------------------------------------
// Async variants for the browser build.
//
// `reqwest::blocking` does not exist on wasm32; reqwest's async client is
// backed by the browser fetch API there. These functions mirror the
// blocking ones above request-for-request. Nominatim, Google, and the
// public OSRM router all send `Access-Control-Allow-Origin: *`, so the
// browser build can call them directly (verified 2026-10-06).
// ---------------------------------------------------------------------------

#[cfg(target_arch = "wasm32")]
fn http_client_async() -> Result<reqwest::Client> {
    // No `.timeout(..)`: reqwest's fetch backend on wasm has no
    // per-request timeout API (the builder method does not exist there).
    reqwest::Client::builder()
        .user_agent("ontrack/2.0 (TDS Telecom field router)")
        .build()
        .map_err(|e| anyhow!("http client build: {e}"))
}

#[cfg(target_arch = "wasm32")]
pub async fn geocode_address_nominatim_async(addr: &str) -> Result<Location> {
    let client = http_client_async()?;
    let resp: Vec<NominatimHit> = client
        .get("https://nominatim.openstreetmap.org/search")
        .query(&[("q", addr), ("format", "json"), ("limit", "1")])
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;

    let mut loc = Location::new(addr);
    if let Some(hit) = resp.first() {
        loc.lat = hit.lat.parse().ok();
        loc.lng = hit.lon.parse().ok();
    }
    Ok(loc)
}

#[cfg(target_arch = "wasm32")]
pub async fn geocode_address_google_async(addr: &str, api_key: &str) -> Result<Location> {
    let client = http_client_async()?;
    let resp: GoogleGeoResp = client
        .get("https://maps.googleapis.com/maps/api/geocode/json")
        .query(&[("address", addr), ("key", api_key)])
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;

    let mut loc = Location::new(addr);
    if resp.status == "OK" {
        if let Some(r) = resp.results.first() {
            loc.lat = Some(r.geometry.location.lat);
            loc.lng = Some(r.geometry.location.lng);
        }
    }
    Ok(loc)
}

/// Async counterpart of [`geocode_addresses`] for the browser build.
#[cfg(target_arch = "wasm32")]
pub async fn geocode_addresses_async(
    addresses: &[String],
    use_google: bool,
    google_api_key: Option<&str>,
    mut progress: Option<&mut dyn FnMut(usize, usize)>,
) -> Vec<Location> {
    let key = google_api_key.unwrap_or("");
    let total = addresses.len();
    let mut out = Vec::with_capacity(total);

    for (i, addr) in addresses.iter().enumerate() {
        let result = if use_google && !key.is_empty() {
            geocode_address_google_async(addr, key).await
        } else {
            geocode_address_nominatim_async(addr).await
        };
        out.push(result.unwrap_or_else(|_| Location::new(addr.clone())));
        if let Some(cb) = progress.as_deref_mut() {
            cb(i + 1, total);
        }
    }
    out
}
