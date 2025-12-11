use clap::{Arg, Command};
use serpapi_search_rust::serp_api_search::SerpApiSearch;
use std::collections::HashMap;
use std::env;

fn get_language_code(input: &str) -> Option<String> {
    let languages: HashMap<&str, &str> = [
        ("ar", "arabic"),
        ("hy", "armenian"),
        ("bg", "bulgarian"),
        ("ca", "catalan"),
        ("cs", "czech"),
        ("da", "danish"),
        ("de", "german"),
        ("el", "greek"),
        ("en", "english"),
        ("es", "spanish"),
        ("et", "estonian"),
        ("tl", "filipino"),
        ("fi", "finnish"),
        ("fr", "french"),
        ("hr", "croatian"),
        ("hi", "hindi"),
        ("hu", "hungarian"),
        ("id", "indonesian"),
        ("is", "icelandic"),
        ("it", "italian"),
        ("iw", "hebrew"),
        ("he", "hebrew"),
        ("ja", "japanese"),
        ("ko", "korean"),
        ("lt", "lithuanian"),
        ("lv", "latvian"),
        ("nl", "dutch"),
        ("no", "norwegian"),
        ("fa", "persian"),
        ("pl", "polish"),
        ("pt", "portuguese"),
        ("ro", "romanian"),
        ("ru", "russian"),
        ("sk", "slovak"),
        ("sl", "slovenian"),
        ("sr", "serbian"),
        ("sv", "swedish"),
        ("th", "thai"),
        ("tr", "turkish"),
        ("uk", "ukrainian"),
        ("vi", "vietnamese"),
        ("zh-cn", "chinese-simplified"),
        ("zh-tw", "chinese-traditional"),
    ]
    .iter()
    .cloned()
    .collect();

    let input_lower = input.to_lowercase();

    if languages.contains_key(input_lower.as_str()) {
        Some(input_lower)
    } else {
        languages
            .iter()
            .find(|(_, &v)| v.to_lowercase() == input_lower)
            .map(|(k, _)| k.to_string())
    }
}

fn get_country_code(input: &str) -> Option<String> {
    let countries: HashMap<&str, &str> = [
        ("us", "united states"),
        ("uk", "united kingdom"),
        ("fr", "france"),
        ("de", "germany"),
        ("es", "spain"),
        ("it", "italy"),
        ("ca", "canada"),
        ("au", "australia"),
        ("jp", "japan"),
        ("cn", "china"),
        ("in", "india"),
        ("br", "brazil"),
        ("ru", "russia"),
        ("mx", "mexico"),
        ("kr", "korea"),
        ("nl", "netherlands"),
        ("se", "sweden"),
        ("no", "norway"),
        ("dk", "denmark"),
        ("fi", "finland"),
        ("pl", "poland"),
        ("tr", "turkey"),
        ("ar", "argentina"),
        ("cl", "chile"),
        ("co", "colombia"),
        ("pe", "peru"),
        ("ve", "venezuela"),
        ("za", "south africa"),
        ("eg", "egypt"),
        ("sa", "saudi arabia"),
        ("ae", "united arab emirates"),
        ("il", "israel"),
        ("th", "thailand"),
        ("id", "indonesia"),
        ("my", "malaysia"),
        ("sg", "singapore"),
        ("ph", "philippines"),
        ("vn", "vietnam"),
        ("nz", "new zealand"),
        ("pt", "portugal"),
        ("gr", "greece"),
        ("cz", "czech republic"),
        ("be", "belgium"),
        ("ch", "switzerland"),
        ("at", "austria"),
        ("ie", "ireland"),
        ("ua", "ukraine"),
        ("ro", "romania"),
        ("hu", "hungary"),
        ("bg", "bulgaria"),
        ("hr", "croatia"),
        ("rs", "serbia"),
    ]
    .iter()
    .cloned()
    .collect();

    let input_lower = input.to_lowercase();

    if countries.contains_key(input_lower.as_str()) {
        Some(format!("country{}", input_lower.to_uppercase()))
    } else {
        countries
            .iter()
            .find(|(_, &v)| v.to_lowercase() == input_lower)
            .map(|(k, _)| format!("country{}", k.to_uppercase()))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let matches = Command::new("web-search-rs")
        .version("1.0")
        .author("Search the web using Google or Yandex via SerpApi")
        .about("Search Google or Yandex using SerpApi")
        .arg(
            Arg::new("query")
                .help("Search query")
                .required(true)
                .index(1),
        )
        .arg(
            Arg::new("engine")
                .short('e')
                .long("engine")
                .value_name("ENGINE")
                .help("Search engine to use (google or yandex)")
                .default_value("google"),
        )
        .arg(
            Arg::new("count")
                .short('n')
                .long("count")
                .value_name("COUNT")
                .help("Total number of results to return (will make multiple requests if > 100)")
                .default_value("10"),
        )
        .arg(
            Arg::new("location")
                .long("location")
                .value_name("LOCATION")
                .help("Location for search (Google only, e.g., 'United States')"),
        )
        .arg(
            Arg::new("encoded-location")
                .long("encoded-location")
                .value_name("UULE")
                .help("Google encoded location parameter"),
        )
        .arg(
            Arg::new("place-id")
                .long("place-id")
                .value_name("LUDOCID")
                .help("Google place ID for location-based searches"),
        )
        .arg(
            Arg::new("location-signature")
                .long("location-signature")
                .value_name("LSIG")
                .help("Google location signature"),
        )
        .arg(
            Arg::new("geo-parameters")
                .long("geo-parameters")
                .value_name("LCI")
                .help("Google geographic parameters"),
        )
        .arg(
            Arg::new("coordinates")
                .long("coordinates")
                .value_name("LLI")
                .help("Google coordinates parameter"),
        )
        .arg(
            Arg::new("layout-params")
                .long("layout-params")
                .value_name("IBP")
                .help("Render layouts and expansions"),
        )
        .arg(
            Arg::new("filter-string")
                .long("filter-string")
                .value_name("UDS")
                .help("Filter search string"),
        )
        .arg(
            Arg::new("domain")
                .long("domain")
                .value_name("DOMAIN")
                .help("Google domain to use (Google only)"),
        )
        .arg(
            Arg::new("country")
                .long("country")
                .value_name("COUNTRY")
                .help("Country code (e.g., us, uk, fr)"),
        )
        .arg(
            Arg::new("language")
                .long("language")
                .value_name("LANGUAGE")
                .help("Language code (e.g., en, es, fr)"),
        )
        .arg(
            Arg::new("country-restrict")
                .long("country-restrict")
                .value_name("COUNTRIES")
                .help("Restrict results to specific countries (comma-separated, Google only)"),
        )
        .arg(
            Arg::new("language-restrict")
                .long("language-restrict")
                .value_name("LANGUAGES")
                .help("Restrict results to specific languages (comma-separated, Google only)"),
        )
        .arg(
            Arg::new("advanced-search")
                .long("advanced-search")
                .value_name("TBS")
                .help("Advanced search parameters (Google only)"),
        )
        .arg(
            Arg::new("no-autocorrect")
                .long("no-autocorrect")
                .help("Disable autocorrection of search query (Google only)")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("no-filter")
                .long("no-filter")
                .help("Disable duplicate content filter (Google only)")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("safe-search")
                .long("safe-search")
                .help("Enable safe search (Google only)")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("page")
                .short('p')
                .long("page")
                .value_name("PAGE")
                .help("Page number (0-indexed)")
                .default_value("0"),
        )
        .arg(
            Arg::new("search-type")
                .short('t')
                .long("search-type")
                .value_name("TYPE")
                .help("Search type (web, images, videos, news, shopping, local, patents)")
                .default_value("web"),
        )
        .arg(
            Arg::new("no-cache")
                .long("no-cache")
                .help("Force fresh results (don't use cache)")
                .action(clap::ArgAction::SetTrue),
        )
        .get_matches();

    let query = matches.get_one::<String>("query").unwrap();
    let engine = matches.get_one::<String>("engine").unwrap();
    let total_desired: usize = matches.get_one::<String>("count").unwrap().parse().unwrap_or(10);

    let api_key = env::var("SERPAPI_API_KEY")?;

    println!("Searching {} for: {}", engine, query);

    // Yandex typically returns ~10 results per page, Google can return up to 100
    let max_per_page = if engine == "yandex" { 10 } else { 100 };
    let requests_needed = (total_desired + max_per_page - 1) / max_per_page;

    let mut params = HashMap::<String, String>::new();

    // Set engine-specific parameters
    if engine == "yandex" {
        params.insert("engine".to_string(), "yandex".to_string());
        params.insert("text".to_string(), query.clone());
    } else {
        // Google is default
        params.insert("q".to_string(), query.clone());
    }

    // Add all optional parameters if provided, mapping readable flags to API parameters
    if let Some(location) = matches.get_one::<String>("location") {
        if engine == "google" {
            params.insert("location".to_string(), location.clone());
            println!("Location: {}", location);
        }
    }

    if let Some(uule) = matches.get_one::<String>("encoded-location") {
        params.insert("uule".to_string(), uule.clone());
        println!("Encoded Location: {}", uule);
    }

    if let Some(ludocid) = matches.get_one::<String>("place-id") {
        params.insert("ludocid".to_string(), ludocid.clone());
        println!("Place ID: {}", ludocid);
    }

    if let Some(lsig) = matches.get_one::<String>("location-signature") {
        params.insert("lsig".to_string(), lsig.clone());
        println!("Location Signature: {}", lsig);
    }

    if let Some(lci) = matches.get_one::<String>("geo-parameters") {
        params.insert("lci".to_string(), lci.clone());
        println!("Geo Parameters: {}", lci);
    }

    if let Some(lli) = matches.get_one::<String>("coordinates") {
        params.insert("lli".to_string(), lli.clone());
        println!("Coordinates: {}", lli);
    }

    if let Some(ibp) = matches.get_one::<String>("layout-params") {
        params.insert("ibp".to_string(), ibp.clone());
        println!("Layout Params: {}", ibp);
    }

    if let Some(uds) = matches.get_one::<String>("filter-string") {
        params.insert("uds".to_string(), uds.clone());
        println!("Filter String: {}", uds);
    }

    if let Some(domain) = matches.get_one::<String>("domain") {
        if engine == "google" {
            params.insert("google_domain".to_string(), domain.clone());
            println!("Google Domain: {}", domain);
        } else if engine == "yandex" {
            params.insert("yandex_domain".to_string(), domain.clone());
            println!("Yandex Domain: {}", domain);
        }
    }

    if let Some(country) = matches.get_one::<String>("country") {
        if engine == "google" {
            params.insert("gl".to_string(), country.clone());
            println!("Country: {}", country);
        } else if engine == "yandex" {
            params.insert("lr".to_string(), country.clone());
            println!("Location (lr): {}", country);
        }
    }

    if let Some(language) = matches.get_one::<String>("language") {
        if engine == "google" {
            params.insert("hl".to_string(), language.clone());
        } else if engine == "yandex" {
            params.insert("lang".to_string(), language.clone());
        }
        println!("Language: {}", language);
    }

    if let Some(cr_input) = matches.get_one::<String>("country-restrict") {
        let countries: Vec<String> = cr_input
            .split(',')
            .filter_map(|country| get_country_code(country.trim()))
            .collect();

        if !countries.is_empty() {
            let cr_value = countries.join("|");
            params.insert("cr".to_string(), cr_value.clone());
            println!("Country Restrict: {}", cr_value);
        } else {
            eprintln!("Warning: No valid countries found in '{}'", cr_input);
        }
    }

    if let Some(lr_input) = matches.get_one::<String>("language-restrict") {
        let languages: Vec<String> = lr_input
            .split(',')
            .filter_map(|lang| get_language_code(lang.trim()))
            .collect();

        if !languages.is_empty() {
            let lr_value = languages.join("|");
            params.insert("lr".to_string(), lr_value.clone());
            println!("Language Restrict: {}", lr_value);
        } else {
            eprintln!("Warning: No valid languages found in '{}'", lr_input);
        }
    }

    if let Some(tbs) = matches.get_one::<String>("advanced-search") {
        params.insert("tbs".to_string(), tbs.clone());
        println!("Advanced Search: {}", tbs);
    }

    // Handle no-autocorrect flag (Google only)
    if matches.get_flag("no-autocorrect") {
        if engine == "google" {
            params.insert("nfpr".to_string(), "1".to_string());
            println!("No Auto-correct: enabled");
        }
    }

    // Handle filter flags
    if matches.get_flag("no-filter") {
        if engine == "google" {
            params.insert("filter".to_string(), "0".to_string());
            println!("Filter: disabled");
        }
    }

    if matches.get_flag("safe-search") {
        if engine == "google" {
            params.insert("safe".to_string(), "active".to_string());
            println!("Safe Search: enabled");
        }
    }

    // Handle search type
    if let Some(search_type) = matches.get_one::<String>("search-type") {
        if search_type != "web" && engine == "google" {
            let tbm_value = match search_type.as_str() {
                "images" => "isch",
                "local" => "lcl",
                "videos" => "vid",
                "news" => "nws",
                "shopping" => "shop",
                "patents" => "pts",
                _ => search_type,
            };
            params.insert("tbm".to_string(), tbm_value.to_string());
            println!("Search Type: {} ({})", search_type, tbm_value);
        }
    }

    // We'll set start and num dynamically in the loop below

    if matches.get_flag("no-cache") {
        params.insert("no_cache".to_string(), "true".to_string());
        println!("No Cache: true");
    }

    println!("---");

    let mut all_organic_results = Vec::new();
    let mut all_local_places = Vec::new();
    let mut knowledge_graph_result = None;
    let mut related_questions_result = None;
    let mut current_start = 0;
    let mut request_num = 0;

    loop {
        // Stop if we already have enough results
        if all_organic_results.len() >= total_desired {
            break;
        }

        let mut request_params = params.clone();

        if engine == "yandex" {
            // Yandex uses 'p' for pagination (0-based page number)
            request_params.insert("p".to_string(), request_num.to_string());
        } else {
            // Google uses 'start' and 'num'
            request_params.insert("start".to_string(), current_start.to_string());
            request_params.insert("num".to_string(), max_per_page.to_string());
        }

        let search = if engine == "yandex" {
            SerpApiSearch::new("yandex".to_string(), request_params, api_key.clone())
        } else {
            SerpApiSearch::google(request_params, api_key.clone())
        };

        match search.json().await {
            Ok(results) => {
                // Collect organic results
                let mut results_in_this_request = 0;
                if let Some(organic_results) = results.get("organic_results") {
                    if let Some(organic_array) = organic_results.as_array() {
                        results_in_this_request = organic_array.len();
                        for result in organic_array {
                            if all_organic_results.len() < total_desired {
                                all_organic_results.push(result.clone());
                            }
                        }
                    }
                }

                // If we got no results, there are no more pages
                if results_in_this_request == 0 {
                    break;
                }

                // For first page only, collect supplementary data
                if request_num == 0 {
                    // Collect local results (places)
                    if let Some(local_results) = results.get("local_results") {
                        if let Some(places) = local_results.get("places") {
                            if let Some(places_array) = places.as_array() {
                                for place in places_array {
                                    all_local_places.push(place.clone());
                                }
                            }
                        }
                    }

                    // Collect knowledge graph (only from first page)
                    if let Some(kg) = results.get("knowledge_graph") {
                        knowledge_graph_result = Some(kg.clone());
                    }

                    // Collect related questions (only from first page)
                    if let Some(rq) = results.get("related_questions") {
                        related_questions_result = Some(rq.clone());
                    }
                }

                // Increment pagination counters for next request
                request_num += 1;
                if engine == "google" {
                    current_start += results_in_this_request;
                }
            }
            Err(error) => {
                eprintln!("Error: {:?}", error);
                if request_num == 0 {
                    return Err(error);
                } else {
                    break;
                }
            }
        }
    }

    // Display results
    if all_organic_results.is_empty() {
        println!("No organic results found.");
    } else {
        println!("Found {} organic results:\n", all_organic_results.len());
        for (i, result) in all_organic_results.iter().enumerate() {
            let title = result.get("title")
                .and_then(|v| v.as_str())
                .unwrap_or("(No title)");
            let link = result.get("link")
                .and_then(|v| v.as_str())
                .unwrap_or("(No link)");
            let snippet = result.get("snippet")
                .and_then(|v| v.as_str())
                .unwrap_or("(No snippet)");

            println!("{}. {}", i + 1, title);
            println!("   Link: {}", link);
            println!("   Snippet: {}\n", snippet);
        }
    }

    // Display local results if any
    if !all_local_places.is_empty() {
        println!("Local results ({} places):", all_local_places.len());
        for (i, place) in all_local_places.iter().enumerate() {
            let title = place.get("title")
                .and_then(|v| v.as_str())
                .unwrap_or("(No title)");
            let address = place.get("address")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let rating = place.get("rating")
                .and_then(|v| v.as_f64())
                .map(|r| r.to_string())
                .unwrap_or_default();

            println!("{}. {}", i + 1, title);
            if !address.is_empty() {
                println!("   Address: {}", address);
            }
            if !rating.is_empty() {
                println!("   Rating: {}", rating);
            }
            println!();
        }
    }

    // Display knowledge graph if available
    if let Some(kg) = knowledge_graph_result {
        println!("Knowledge Graph:");
        if let Some(title) = kg.get("title").and_then(|v| v.as_str()) {
            println!("Title: {}", title);
        }
        if let Some(description) = kg.get("description").and_then(|v| v.as_str()) {
            println!("Description: {}", description);
        }
        println!();
    }

    // Display related questions if available
    if let Some(rq) = related_questions_result {
        if let Some(questions) = rq.as_array() {
            if !questions.is_empty() {
                println!("Related Questions:");
                for question in questions {
                    if let Some(q) = question.get("question").and_then(|v| v.as_str()) {
                        println!("- {}", q);
                        if let Some(a) = question.get("snippet").and_then(|v| v.as_str()) {
                            println!("  {}", a);
                        }
                    }
                }
                println!();
            }
        }
    }

    Ok(())
}
