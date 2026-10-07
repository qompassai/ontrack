mod app;
mod views;

#[cfg(not(target_arch = "wasm32"))]
use anyhow::Result;
#[cfg(not(target_arch = "wasm32"))]
use eframe::NativeOptions;

#[cfg(not(target_arch = "wasm32"))]
fn main() -> Result<()> {
    let _ = dotenvy::dotenv();
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let options = NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("OnTrack — TDS Telecom Route Optimizer")
            .with_inner_size([1100.0, 720.0])
            .with_min_inner_size([720.0, 540.0]),
        ..Default::default()
    };

    eframe::run_native(
        "OnTrack",
        options,
        Box::new(|cc| Ok(Box::new(app::OnTrackApp::new(cc)))),
    )
    .map_err(|e| anyhow::anyhow!("eframe error: {e}"))?;
    Ok(())
}

/// Browser entry point: `eframe::WebRunner` renders the same
/// [`app::OnTrackApp`] into the `<canvas id="ontrack_canvas">` declared
/// in `index.html`. There is no process environment or `.env` file in a
/// browser, so settings start from their defaults (see `docs/WEB.md`).
#[cfg(target_arch = "wasm32")]
fn main() {
    use wasm_bindgen::JsCast as _;

    // Surface Rust panics in the browser console instead of leaving a
    // silently frozen canvas, and route `log` output there too.
    console_error_panic_hook::set_once();
    eframe::WebLogger::init(log::LevelFilter::Info).ok();

    let web_options = eframe::WebOptions::default();
    wasm_bindgen_futures::spawn_local(async {
        let document = web_sys::window()
            .expect("no browser window")
            .document()
            .expect("no browser document");
        let canvas = document
            .get_element_by_id("ontrack_canvas")
            .expect("index.html is missing #ontrack_canvas")
            .dyn_into::<web_sys::HtmlCanvasElement>()
            .expect("#ontrack_canvas is not a <canvas> element");

        let start_result = eframe::WebRunner::new()
            .start(
                canvas,
                web_options,
                Box::new(|cc| Ok(Box::new(app::OnTrackApp::new(cc)))),
            )
            .await;

        // Retire the loading overlay: remove it once the app is running,
        // or replace it with the startup error so failures are visible.
        if let Some(loading) = document.get_element_by_id("loading") {
            match start_result {
                Ok(()) => loading.remove(),
                Err(e) => {
                    loading.set_text_content(Some(&format!("Failed to start OnTrack: {e:?}")));
                }
            }
        }
    });
}
