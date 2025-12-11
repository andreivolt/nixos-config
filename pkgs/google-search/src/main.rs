
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
        ("zh-cn", "chinese simplified"),
        ("zh-tw", "chinese traditional"),
    ].iter().cloned().collect();

    let input_lower = input.to_lowercase();

    // Check if input matches a language code
    if languages.contains_key(input_lower.as_str()) {
        return Some(format!("lang_{}", input_lower));
    }

    // Check if input matches a language name
    for (code, name) in &languages {
        if input_lower == *name {
            return Some(format!("lang_{}", code));
        }
    }

    None
}

fn get_country_code(input: &str) -> Option<String> {
    let countries: HashMap<&str, &str> = [
        ("af", "afghanistan"),
        ("al", "albania"),
        ("dz", "algeria"),
        ("as", "american samoa"),
        ("ad", "andorra"),
        ("ao", "angola"),
        ("ai", "anguilla"),
        ("aq", "antarctica"),
        ("ag", "antigua & barbuda"),
        ("ar", "argentina"),
        ("am", "armenia"),
        ("aw", "aruba"),
        ("au", "australia"),
        ("at", "austria"),
        ("az", "azerbaijan"),
        ("bs", "bahamas"),
        ("bh", "bahrain"),
        ("bd", "bangladesh"),
        ("bb", "barbados"),
        ("by", "belarus"),
        ("be", "belgium"),
        ("bz", "belize"),
        ("bj", "benin"),
        ("bm", "bermuda"),
        ("bt", "bhutan"),
        ("bo", "bolivia"),
        ("ba", "bosnia & herzegovina"),
        ("bw", "botswana"),
        ("bv", "bouvet island"),
        ("br", "brazil"),
        ("io", "british indian ocean territory"),
        ("vg", "british virgin islands"),
        ("bn", "brunei"),
        ("bg", "bulgaria"),
        ("bf", "burkina faso"),
        ("bi", "burundi"),
        ("kh", "cambodia"),
        ("cm", "cameroon"),
        ("ca", "canada"),
        ("cv", "cape verde"),
        ("ky", "cayman islands"),
        ("cf", "central african republic"),
        ("td", "chad"),
        ("cl", "chile"),
        ("cn", "china"),
        ("cx", "christmas island"),
        ("cc", "cocos islands"),
        ("co", "colombia"),
        ("km", "comoros"),
        ("cg", "congo brazzaville"),
        ("cd", "congo kinshasa"),
        ("ck", "cook islands"),
        ("cr", "costa rica"),
        ("ci", "cote divoire"),
        ("hr", "croatia"),
        ("cu", "cuba"),
        ("cy", "cyprus"),
        ("cz", "czechia"),
        ("dk", "denmark"),
        ("dj", "djibouti"),
        ("dm", "dominica"),
        ("do", "dominican republic"),
        ("tp", "east timor"),
        ("ec", "ecuador"),
        ("eg", "egypt"),
        ("sv", "el salvador"),
        ("gq", "equatorial guinea"),
        ("er", "eritrea"),
        ("ee", "estonia"),
        ("et", "ethiopia"),
        ("eu", "european union"),
        ("fk", "falkland islands"),
        ("fo", "faroe islands"),
        ("fj", "fiji"),
        ("fi", "finland"),
        ("fr", "france"),
        ("fx", "france metropolitan"),
        ("gf", "french guiana"),
        ("pf", "french polynesia"),
        ("tf", "french southern territories"),
        ("ga", "gabon"),
        ("gm", "gambia"),
        ("ge", "georgia"),
        ("de", "germany"),
        ("gh", "ghana"),
        ("gi", "gibraltar"),
        ("gr", "greece"),
        ("gl", "greenland"),
        ("gd", "grenada"),
        ("gp", "guadeloupe"),
        ("gu", "guam"),
        ("gt", "guatemala"),
        ("gn", "guinea"),
        ("gw", "guinea-bissau"),
        ("gy", "guyana"),
        ("ht", "haiti"),
        ("hm", "heard island"),
        ("hn", "honduras"),
        ("hk", "hong kong"),
        ("hu", "hungary"),
        ("is", "iceland"),
        ("in", "india"),
        ("id", "indonesia"),
        ("ir", "iran"),
        ("iq", "iraq"),
        ("ie", "ireland"),
        ("il", "israel"),
        ("it", "italy"),
        ("jm", "jamaica"),
        ("jp", "japan"),
        ("jo", "jordan"),
        ("kz", "kazakhstan"),
        ("ke", "kenya"),
        ("ki", "kiribati"),
        ("kw", "kuwait"),
        ("kg", "kyrgyzstan"),
        ("la", "laos"),
        ("lv", "latvia"),
        ("lb", "lebanon"),
        ("ls", "lesotho"),
        ("lr", "liberia"),
        ("ly", "libya"),
        ("li", "liechtenstein"),
        ("lt", "lithuania"),
        ("lu", "luxembourg"),
        ("mo", "macao"),
        ("mg", "madagascar"),
        ("mw", "malawi"),
        ("my", "malaysia"),
        ("mv", "maldives"),
        ("ml", "mali"),
        ("mt", "malta"),
        ("mh", "marshall islands"),
        ("mq", "martinique"),
        ("mr", "mauritania"),
        ("mu", "mauritius"),
        ("yt", "mayotte"),
        ("mx", "mexico"),
        ("fm", "micronesia"),
        ("md", "moldova"),
        ("mc", "monaco"),
        ("mn", "mongolia"),
        ("ms", "montserrat"),
        ("ma", "morocco"),
        ("mz", "mozambique"),
        ("mm", "myanmar"),
        ("na", "namibia"),
        ("nr", "nauru"),
        ("np", "nepal"),
        ("nl", "netherlands"),
        ("an", "netherlands antilles"),
        ("nc", "new caledonia"),
        ("nz", "new zealand"),
        ("ni", "nicaragua"),
        ("ne", "niger"),
        ("ng", "nigeria"),
        ("nu", "niue"),
        ("nf", "norfolk island"),
        ("kp", "north korea"),
        ("mk", "north macedonia"),
        ("mp", "northern mariana islands"),
        ("no", "norway"),
        ("om", "oman"),
        ("pk", "pakistan"),
        ("pw", "palau"),
        ("ps", "palestine"),
        ("pa", "panama"),
        ("pg", "papua new guinea"),
        ("py", "paraguay"),
        ("pe", "peru"),
        ("ph", "philippines"),
        ("pn", "pitcairn islands"),
        ("pl", "poland"),
        ("pt", "portugal"),
        ("pr", "puerto rico"),
        ("qa", "qatar"),
        ("re", "reunion"),
        ("ro", "romania"),
        ("ru", "russia"),
        ("rw", "rwanda"),
        ("ws", "samoa"),
        ("sm", "san marino"),
        ("st", "sao tome & principe"),
        ("sa", "saudi arabia"),
        ("sn", "senegal"),
        ("rs", "serbia"),
        ("cs", "serbia and montenegro"),
        ("sc", "seychelles"),
        ("sl", "sierra leone"),
        ("sg", "singapore"),
        ("sk", "slovakia"),
        ("si", "slovenia"),
        ("sb", "solomon islands"),
        ("so", "somalia"),
        ("za", "south africa"),
        ("gs", "south georgia"),
        ("kr", "south korea"),
        ("es", "spain"),
        ("lk", "sri lanka"),
        ("sh", "st helena"),
        ("kn", "st kitts & nevis"),
        ("lc", "st lucia"),
        ("pm", "st pierre & miquelon"),
        ("vc", "st vincent & grenadines"),
        ("sd", "sudan"),
        ("sr", "suriname"),
        ("sj", "svalbard & jan mayen"),
        ("sz", "swaziland"),
        ("se", "sweden"),
        ("ch", "switzerland"),
        ("sy", "syria"),
        ("tw", "taiwan"),
        ("tj", "tajikistan"),
        ("tz", "tanzania"),
        ("th", "thailand"),
        ("tg", "togo"),
        ("tk", "tokelau"),
        ("to", "tonga"),
        ("tt", "trinidad & tobago"),
        ("tn", "tunisia"),
        ("tr", "turkey"),
        ("tm", "turkmenistan"),
        ("tc", "turks & caicos islands"),
        ("tv", "tuvalu"),
        ("um", "us outlying islands"),
        ("vi", "us virgin islands"),
        ("ug", "uganda"),
        ("ua", "ukraine"),
        ("ae", "united arab emirates"),
        ("uk", "united kingdom"),
        ("gb", "united kingdom"),
        ("us", "united states"),
        ("uy", "uruguay"),
        ("uz", "uzbekistan"),
        ("vu", "vanuatu"),
        ("va", "vatican city"),
        ("ve", "venezuela"),
        ("vn", "vietnam"),
        ("wf", "wallis & futuna"),
        ("eh", "western sahara"),
        ("ye", "yemen"),
        ("yu", "yugoslavia"),
        ("zm", "zambia"),
        ("zw", "zimbabwe"),
    ].iter().cloned().collect();

    let input_lower = input.to_lowercase();

    if countries.contains_key(input_lower.as_str()) {
        return Some(format!("country{}", input_lower.to_uppercase()));
    }

    for (code, name) in &countries {
        if input_lower == *name {
            return Some(format!("country{}", code.to_uppercase()));
        }
    }

    None
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let matches = Command::new("google-search")
        .version("0.1.0")
        .about("A CLI tool for Google search using SerpApi")
        .arg(
            Arg::new("query")
                .value_name("QUERY")
                .help("Search query")
                .required(true)
                .index(1),
        )
        .arg(
            Arg::new("location")
                .short('l')
                .long("location")
                .value_name("LOCATION")
                .help("Geographic location for the search"),
        )
        .arg(
            Arg::new("encoded-location")
                .long("encoded-location")
                .value_name("UULE")
                .help("Google encoded location (can't be used with --location)"),
        )
        .arg(
            Arg::new("place-id")
                .long("place-id")
                .value_name("LUDOCID")
                .help("Google CID (customer identifier) of a place"),
        )
        .arg(
            Arg::new("location-signature")
                .long("location-signature")
                .value_name("LSIG")
                .help("Force knowledge graph map view"),
        )
        .arg(
            Arg::new("knowledge-graph-id")
                .long("knowledge-graph-id")
                .value_name("KGMID")
                .help("Google Knowledge Graph ID"),
        )
        .arg(
            Arg::new("search-info")
                .long("search-info")
                .value_name("SI")
                .help("Cached search parameters"),
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
                .help("Google domain to use")
                .default_value("google.com"),
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
                .help("Limit search to specific countries (e.g., us,de or france,germany)"),
        )
        .arg(
            Arg::new("language-restrict")
                .long("language-restrict")
                .value_name("LANGUAGES")
                .help("Limit search to specific languages (e.g., en,fr or english,french)"),
        )
        .arg(
            Arg::new("advanced-search")
                .long("advanced-search")
                .value_name("TBS")
                .help("Advanced search parameters (to be searched)"),
        )
        .arg(
            Arg::new("no-autocorrect")
                .long("no-autocorrect")
                .help("Exclude auto-corrected results")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("filter")
                .long("filter")
                .help("Enable similar/omitted result filters (default)")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("no-filter")
                .long("no-filter")
                .help("Disable similar/omitted result filters")
                .action(clap::ArgAction::SetTrue)
                .conflicts_with("filter"),
        )
        .arg(
            Arg::new("search-type")
                .long("search-type")
                .value_name("TYPE")
                .help("Search type: images, local, videos, news, shopping, patents")
                .value_parser(["images", "local", "videos", "news", "shopping", "patents"]),
        )
        .arg(
            Arg::new("count")
                .short('c')
                .long("count")
                .value_name("COUNT")
                .help("Total number of results to return (will make multiple requests if > 100)")
                .default_value("10"),
        )
        .arg(
            Arg::new("no-cache")
                .long("no-cache")
                .help("Force fresh results (don't use cache)")
                .action(clap::ArgAction::SetTrue),
        )
        .get_matches();

    let query = matches.get_one::<String>("query").unwrap();
    let total_desired: usize = matches.get_one::<String>("count").unwrap().parse().unwrap_or(10);

    let api_key = env::var("SERPAPI_API_KEY")
        .map_err(|_| "SERPAPI_API_KEY environment variable is required")?;

    println!("Searching for: {}", query);

    const MAX_RESULTS_PER_REQUEST: usize = 100;
    let requests_needed = (total_desired + MAX_RESULTS_PER_REQUEST - 1) / MAX_RESULTS_PER_REQUEST;

    let mut params = HashMap::<String, String>::new();
    params.insert("q".to_string(), query.clone());

    // Add all optional parameters if provided, mapping readable flags to API parameters
    if let Some(location) = matches.get_one::<String>("location") {
        params.insert("location".to_string(), location.clone());
        println!("Location: {}", location);
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

    if let Some(kgmid) = matches.get_one::<String>("knowledge-graph-id") {
        params.insert("kgmid".to_string(), kgmid.clone());
        println!("Knowledge Graph ID: {}", kgmid);
    }

    if let Some(si) = matches.get_one::<String>("search-info") {
        params.insert("si".to_string(), si.clone());
        println!("Search Info: {}", si);
    }

    if let Some(ibp) = matches.get_one::<String>("layout-params") {
        params.insert("ibp".to_string(), ibp.clone());
        println!("Layout Params: {}", ibp);
    }

    if let Some(uds) = matches.get_one::<String>("filter-string") {
        params.insert("uds".to_string(), uds.clone());
        println!("Filter String: {}", uds);
    }

    if let Some(google_domain) = matches.get_one::<String>("domain") {
        params.insert("google_domain".to_string(), google_domain.clone());
        println!("Google Domain: {}", google_domain);
    }

    if let Some(gl) = matches.get_one::<String>("country") {
        params.insert("gl".to_string(), gl.clone());
        println!("Country: {}", gl);
    }

    if let Some(hl) = matches.get_one::<String>("language") {
        params.insert("hl".to_string(), hl.clone());
        println!("Language: {}", hl);
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

    // Handle no-autocorrect flag
    if matches.get_flag("no-autocorrect") {
        params.insert("nfpr".to_string(), "1".to_string());
        println!("No Auto-correct: enabled");
    }

    // Handle filter flags
    if matches.get_flag("no-filter") {
        params.insert("filter".to_string(), "0".to_string());
        println!("Similar Filter: disabled");
    } else if matches.get_flag("filter") {
        params.insert("filter".to_string(), "1".to_string());
        println!("Similar Filter: enabled");
    } else {
        // Default to enabled
        params.insert("filter".to_string(), "1".to_string());
    }

    if let Some(search_type) = matches.get_one::<String>("search-type") {
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

    for request_num in 0..requests_needed {
        let current_start = request_num * MAX_RESULTS_PER_REQUEST;
        let remaining_results = total_desired - all_organic_results.len();
        let current_count = std::cmp::min(MAX_RESULTS_PER_REQUEST, remaining_results);

        // Stop if we already have enough results
        if all_organic_results.len() >= total_desired {
            break;
        }


        let mut request_params = params.clone();
        request_params.insert("start".to_string(), current_start.to_string());
        request_params.insert("num".to_string(), current_count.to_string());

        let search = SerpApiSearch::google(request_params, api_key.clone());

        match search.json().await {
            Ok(results) => {
                // Collect organic results
                if let Some(organic_results) = results.get("organic_results") {
                    if let Some(organic_array) = organic_results.as_array() {
                        for result in organic_array {
                            if all_organic_results.len() < total_desired {
                                all_organic_results.push(result.clone());
                            }
                        }
                    }
                }

                // Collect local results (only from first request to avoid duplicates)
                if request_num == 0 {
                    if let Some(local_results) = results.get("local_results") {
                        if let Some(places) = local_results.get("places") {
                            if let Some(places_array) = places.as_array() {
                                all_local_places = places_array.to_vec();
                            }
                        }
                    }

                    // Knowledge graph and related questions (only from first request)
                    knowledge_graph_result = results.get("knowledge_graph").cloned();
                    related_questions_result = results.get("related_questions").cloned();
                }
            }
            Err(e) => {
                eprintln!("Error in request {}: {}", request_num + 1, e);
                if request_num == 0 {
                    // If first request fails, exit
                    std::process::exit(1);
                } else {
                    // For subsequent requests, just continue with what we have
                    break;
                }
            }
        }
    }

    // Display all collected results
    if !all_organic_results.is_empty() {
        println!("Found {} organic results:\n", all_organic_results.len());

        for (i, result) in all_organic_results.iter().enumerate() {
            if let (Some(title), Some(link), Some(snippet)) = (
                result.get("title").and_then(|t| t.as_str()),
                result.get("link").and_then(|l| l.as_str()),
                result.get("snippet").and_then(|s| s.as_str()),
            ) {
                println!("{}. {}", i + 1, title);
                println!("   Link: {}", link);
                println!("   Snippet: {}", snippet);
                println!();
            }
        }
    } else {
        println!("No organic results found.");
    }

    if !all_local_places.is_empty() {
        println!("Local results ({} places):", all_local_places.len());
        for (i, place) in all_local_places.iter().enumerate() {
            if let (Some(title), Some(address)) = (
                place.get("title").and_then(|t| t.as_str()),
                place.get("address").and_then(|a| a.as_str()),
            ) {
                println!("{}. {}", i + 1, title);
                println!("   Address: {}", address);
                if let Some(rating) = place.get("rating").and_then(|r| r.as_f64()) {
                    println!("   Rating: {:.1}", rating);
                }
                println!();
            }
        }
    }

    if let Some(knowledge_graph) = knowledge_graph_result {
        if let Some(title) = knowledge_graph.get("title").and_then(|t| t.as_str()) {
            println!("Knowledge Graph:");
            println!("Title: {}", title);
            if let Some(description) = knowledge_graph.get("description").and_then(|d| d.as_str()) {
                println!("Description: {}", description);
            }
            println!();
        }
    }

    if let Some(related_questions) = related_questions_result {
        if let Some(questions_array) = related_questions.as_array() {
            if !questions_array.is_empty() {
                println!("Related Questions:");
                for question in questions_array {
                    if let Some(q) = question.get("question").and_then(|q| q.as_str()) {
                        println!("• {}", q);
                    }
                }
                println!();
            }
        }
    }

    Ok(())
}