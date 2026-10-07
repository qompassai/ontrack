pub mod config;
pub mod exporter;
pub mod geocoder;
pub mod matrix;
pub mod parser;
pub mod solver;

#[cfg(feature = "voice")]
pub mod voice;

pub use exporter::{
    build_fieldmaps_url, build_maps_url, build_maps_url_chunked, build_streetview_embed_url,
    build_streetview_url, build_waze_url, export_csv, format_duration, route_csv_string,
};
pub use geocoder::Location;
#[cfg(not(target_arch = "wasm32"))]
pub use geocoder::{
    geocode_address_google, geocode_address_nominatim, geocode_addresses, get_current_location,
};
#[cfg(target_arch = "wasm32")]
pub use geocoder::{
    geocode_address_google_async, geocode_address_nominatim_async, geocode_addresses_async,
};
#[cfg(not(target_arch = "wasm32"))]
pub use matrix::build_distance_matrix;
#[cfg(target_arch = "wasm32")]
pub use matrix::build_distance_matrix_async;
pub use matrix::{haversine, Backend};
pub use parser::{parse_addresses, parse_addresses_from_bytes};
pub use solver::{solve_open_tsp, solve_tsp, RouteResult, SolverBackend};
