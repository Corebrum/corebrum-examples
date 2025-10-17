// Copyright (c) 2024 Corebrum Team. All Rights Reserved.
// Licensed under All Rights Reserved License.
// See LICENSE file for details.

// WASM Factorial Implementation for URL-based execution
// This will be compiled to WebAssembly and hosted on a URL

use wasm_bindgen::prelude::*;

// Import the `console.log` function from the browser
#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);
}

// Define a macro to make console.log easier to use
macro_rules! console_log {
    ($($t:tt)*) => (log(&format_args!($($t)*).to_string()))
}

// Export a function that can be called from JavaScript
#[wasm_bindgen]
pub fn factorial(n: u32) -> u64 {
    if n == 0 || n == 1 {
        return 1;
    }
    
    let mut result: u64 = 1;
    for i in 2..=n {
        result *= i as u64;
    }
    
    result
}

// Export a function that computes factorial and returns JSON-like result
#[wasm_bindgen]
pub fn compute_factorial_with_metadata(n: u32, worker_id: &str) -> String {
    let start_time = js_sys::Date::now();
    
    let factorial_result = factorial(n);
    
    let end_time = js_sys::Date::now();
    let computation_time_ms = (end_time - start_time) as u32;
    
    // Create a JSON-like result string
    let result = format!(
        r#"{{"factorial":{},"input_number":{},"computation_time_ms":{},"worker_id":"{}","method":"wasm_url","timestamp":"{}"}}"#,
        factorial_result,
        n,
        computation_time_ms,
        worker_id,
        js_sys::Date::new_0().to_iso_string().as_string().unwrap_or("unknown".to_string())
    );
    
    console_log!("WASM Factorial (URL) computed: {}", result);
    result
}

// Export a function to get the WASM module info
#[wasm_bindgen]
pub fn get_module_info() -> String {
    r#"{"name":"factorial_wasm_url","version":"1.0","description":"WebAssembly factorial computation from URL","language":"rust","target":"wasm32","source":"url"}"#.to_string()
}

// This function is called when the WASM module is instantiated
#[wasm_bindgen(start)]
pub fn main() {
    console_log!("WASM Factorial (URL) module loaded successfully!");
}
