// #################################################################
// /qompassai/ontrack/crates/ontrack-core/src/config.rs
// Qompass AI Config
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// #################################################################


//! Global configuration and defaults for the ONTrack application.
//!
//! This module defines the app name/version, organization, and
//! environment-driven settings for external services like OSRM,
//! Google Maps, ArcGIS, and Whisper.

use std::env;

/// Human-readable name of the ONTrack application.
pub const APP_NAME: &str = "OnTrack";

/// Semver version string for ONTrack releases.
pub const APP_VERSION: &str = "2.0.0";

/// Organization name used in UI and metadata.
pub const ORG_NAME: &str = "TDS Telecom";

/// Default public OSRM endpoint used when no `OSRM_BASE_URL` is set.
///
/// This is a free, public router that ONTrack can use for distance
/// and travel time calculations if you don't provide your own OSRM instance.
pub const OSRM_PUBLIC: &str = "http://router.project-osrm.org";

/// Runtime configuration for ONTrack.
///
/// This struct gathers all settings that can be controlled via
/// environment variables or sensible defaults:
/// - `google_maps_api_key`: optional API key for Google Maps.
/// - `osrm_base_url`: base URL for the OSRM routing service.
/// - `arcgis_item_id`: optional ArcGIS item identifier used for map data.
/// - `whisper_model`: model name used for Whisper speech recognition.
#[derive(Debug, Clone)]
pub struct Settings {
    /// Optional API key for Google Maps integrations.
    ///
    /// If empty, ONTrack will rely on OSRM and other data sources
    /// that don't require authenticated access to Google Maps.
    pub google_maps_api_key: String,

    /// Base URL for the OSRM routing service.
    ///
    /// Defaults to [`OSRM_PUBLIC`] when `OSRM_BASE_URL` is not set.
    pub osrm_base_url: String,

    /// ArcGIS item identifier used to fetch map layers or metadata.
    ///
    /// If empty, ONTrack will skip ArcGIS-specific integrations.
    pub arcgis_item_id: String,

    /// Whisper model name used for speech recognition.
    ///
    /// Defaults to `"base"` when `ONTRACK_WHISPER_MODEL` is not set.
    pub whisper_model: String,
}

impl Default for Settings {
    /// Returns a `Settings` instance with all fields set to reasonable defaults.
    ///
    /// Environment variables are not read here; this simply uses:
    /// - empty strings for optional keys and IDs
    /// - [`OSRM_PUBLIC`] for `osrm_base_url`
    /// - `"base"` for `whisper_model`
    fn default() -> Self {
        Self {
            google_maps_api_key: String::new(),
            osrm_base_url: OSRM_PUBLIC.to_string(),
            arcgis_item_id: String::new(),
            whisper_model: "base".to_string(),
        }
    }
}

impl Settings {
    /// Builds a `Settings` instance from environment variables.
    ///
    /// It loads a `.env` file via `dotenvy` (if present), then reads:
    /// - `GOOGLE_MAPS_API_KEY` → `google_maps_api_key` (empty if unset)
    /// - `OSRM_BASE_URL` → `osrm_base_url` (falls back to [`OSRM_PUBLIC`])
    /// - `ARCGIS_ITEM_ID` → `arcgis_item_id` (empty if unset)
    /// - `ONTRACK_WHISPER_MODEL` → `whisper_model` (falls back to `"base"`)
    pub fn from_env() -> Self {
        let _ = dotenvy::dotenv();

        Self {
            google_maps_api_key: env::var("GOOGLE_MAPS_API_KEY").unwrap_or_default(),
            osrm_base_url: env::var("OSRM_BASE_URL").unwrap_or_else(|_| OSRM_PUBLIC.to_string()),
            arcgis_item_id: env::var("ARCGIS_ITEM_ID").unwrap_or_default(),
            whisper_model: env::var("ONTRACK_WHISPER_MODEL").unwrap_or_else(|_| "base".to_string()),
        }
    }
}
