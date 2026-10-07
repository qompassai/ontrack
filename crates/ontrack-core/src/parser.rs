use std::io::{Cursor, Read, Seek};
use std::path::Path;

use anyhow::{anyhow, Context, Result};
use calamine::{open_workbook_auto, open_workbook_auto_from_rs, Data, Reader, Sheets};

pub fn parse_addresses<P: AsRef<Path>>(path: P) -> Result<Vec<String>> {
    let path = path.as_ref();
    match extension_of(path).as_str() {
        "csv" => parse_csv(path),
        "xlsx" | "xls" | "xlsm" | "xlsb" | "ods" => parse_excel(path),
        other => Err(anyhow!("unsupported file extension: .{other}")),
    }
}

/// Parses addresses from in-memory file contents.
///
/// This is the browser build's counterpart to [`parse_addresses`]: a web
/// page cannot hand the app a filesystem path, so the file picker passes
/// the picked file's name (for its extension) and bytes instead.
pub fn parse_addresses_from_bytes(file_name: &str, bytes: &[u8]) -> Result<Vec<String>> {
    match extension_of(Path::new(file_name)).as_str() {
        "csv" => parse_csv_reader(Cursor::new(bytes.to_vec())),
        "xlsx" | "xls" | "xlsm" | "xlsb" | "ods" => parse_excel_bytes(bytes),
        other => Err(anyhow!("unsupported file extension: .{other}")),
    }
}

fn extension_of(path: &Path) -> String {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|s| s.to_ascii_lowercase())
        .unwrap_or_default()
}

fn parse_csv(path: &Path) -> Result<Vec<String>> {
    let file =
        std::fs::File::open(path).with_context(|| format!("opening CSV {}", path.display()))?;
    parse_csv_reader(file)
}

fn parse_csv_reader<R: Read>(reader: R) -> Result<Vec<String>> {
    let mut rdr = csv::ReaderBuilder::new()
        .has_headers(true)
        .flexible(true)
        .from_reader(reader);

    let headers = rdr.headers()?.clone();
    let idx = headers
        .iter()
        .position(|h| h.trim().eq_ignore_ascii_case("address"))
        .ok_or_else(|| anyhow!("CSV is missing an 'address' column"))?;

    let mut out = Vec::new();
    for rec in rdr.records() {
        let rec = rec?;
        if let Some(v) = rec.get(idx) {
            let v = v.trim();
            if !v.is_empty() {
                out.push(v.to_string());
            }
        }
    }
    Ok(out)
}

fn parse_excel(path: &Path) -> Result<Vec<String>> {
    let mut wb =
        open_workbook_auto(path).with_context(|| format!("opening workbook {}", path.display()))?;
    extract_excel_addresses(&mut wb)
}

fn parse_excel_bytes(bytes: &[u8]) -> Result<Vec<String>> {
    let mut wb = open_workbook_auto_from_rs(Cursor::new(bytes.to_vec()))
        .map_err(|e| anyhow!("opening workbook from uploaded bytes: {e}"))?;
    extract_excel_addresses(&mut wb)
}

fn extract_excel_addresses<RS: Read + Seek>(wb: &mut Sheets<RS>) -> Result<Vec<String>> {
    let sheet_name = wb
        .sheet_names()
        .first()
        .cloned()
        .ok_or_else(|| anyhow!("workbook has no sheets"))?;
    let range = wb
        .worksheet_range(&sheet_name)
        .with_context(|| format!("reading sheet {sheet_name}"))?;

    let mut rows = range.rows();
    let header = rows.next().ok_or_else(|| anyhow!("workbook is empty"))?;
    let idx = header
        .iter()
        .position(|c| matches!(c, Data::String(s) if s.trim().eq_ignore_ascii_case("address")))
        .ok_or_else(|| anyhow!("workbook is missing an 'address' column"))?;

    let mut out = Vec::new();
    for row in rows {
        if let Some(cell) = row.get(idx) {
            let s = match cell {
                Data::String(s) => s.trim().to_string(),
                Data::Float(f) => f.to_string(),
                Data::Int(i) => i.to_string(),
                Data::DateTime(dt) => dt.to_string(),
                Data::Bool(b) => b.to_string(),
                _ => String::new(),
            };
            if !s.is_empty() {
                out.push(s);
            }
        }
    }
    Ok(out)
}
