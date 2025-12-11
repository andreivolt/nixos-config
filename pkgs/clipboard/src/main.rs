use anyhow::{Result, bail, Context};
use clap::Parser;
use std::{
    collections::HashSet,
    io::{Write, IsTerminal},
    process::{Command, Stdio},
};
use rusqlite::Connection;

#[derive(Parser)]
#[command(about = "Browse and manage Maccy clipboard history with interactive selection")]
struct Args {
    #[arg(short, long, help = "Copy selected item to clipboard")]
    copy: bool,

    #[arg(short, long, help = "Echo selected item to stdout (default)")]
    echo: bool,

    #[arg(short, long, help = "Limit number of items shown")]
    number: Option<usize>,

    #[arg(short, long, help = "Pre-filter items containing search term")]
    search: Option<String>,

    #[arg(long, help = "Show items in reverse chronological order")]
    reverse: bool,

    #[arg(long, help = "Allow duplicate items")]
    no_unique: bool,
}


fn get_maccy_data() -> Result<Vec<String>> {
    let maccy_db = dirs::home_dir()
        .context("Could not find home directory")?
        .join("Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy/Storage.sqlite");

    if !maccy_db.exists() {
        bail!("Maccy database not found");
    }

    let conn = Connection::open(&maccy_db)?;

    let mut stmt = conn.prepare("SELECT CAST(hic.ZVALUE AS TEXT) FROM ZHISTORYITEM hi JOIN ZHISTORYITEMCONTENT hic ON hi.Z_PK = hic.ZITEM WHERE hic.ZTYPE = 'public.utf8-plain-text' GROUP BY hi.Z_PK ORDER BY hi.ZLASTCOPIEDAT DESC")?;
    let items: Vec<String> = stmt.query_map([], |row| {
        let value: String = row.get(0)?;
        Ok(value)
    })?
    .filter_map(|r| r.ok())
    .filter(|s| !s.is_empty())
    .collect();

    Ok(items)
}

fn filter_items(
    items: Vec<String>,
    search: Option<&str>,
    number: Option<usize>,
    reverse: bool,
    unique: bool,
) -> Vec<String> {
    let mut items = items;

    if unique {
        let mut seen = HashSet::new();
        items = items.into_iter()
            .filter(|item| seen.insert(item.clone()))
            .collect();
    }

    if let Some(search_term) = search {
        let search_lower = search_term.to_lowercase();
        items.retain(|item| item.to_lowercase().contains(&search_lower));
    }

    if reverse {
        items.reverse();
    }

    if let Some(n) = number {
        items.truncate(n);
    }

    items
}

fn run_fzf(items: &[String], _copy_mode: bool) -> Result<String> {
    if items.is_empty() {
        bail!("No items found");
    }

    let encoded_items: Vec<String> = items.iter()
        .map(|item| item.replace('\n', "\\n").replace('\t', "\\t"))
        .collect();

    let keybinds = vec![
        "ctrl-y:execute-silent(echo -n {} | sed 's/\\\\n/\\n/g; s/\\\\t/\\t/g' | pbcopy)+abort",
        "ctrl-e:execute(echo -n {} | sed 's/\\\\n/\\n/g; s/\\\\t/\\t/g' | pbcopy && osascript -e 'tell app \"System Events\" to keystroke \"v\" using command down')+abort",
        "ctrl-d:execute-silent(echo 'Delete not implemented yet')+abort",
    ];

    let mut cmd = Command::new("fzf");
    cmd.arg("--preview")
        .arg("echo {} | sed 's/\\\\n/\\n/g; s/\\\\t/\\t/g' | fold -s -w 80")
        .arg("--preview-window")
        .arg("up:wrap")
        .arg("--bind")
        .arg(keybinds.join(","))
        .arg("--height")
        .arg("80%")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped());

    let mut child = cmd.spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(encoded_items.join("\n").as_bytes())?;
    }

    let output = child.wait_with_output()?;

    if !output.status.success() {
        std::process::exit(1);
    }

    let encoded_result = String::from_utf8(output.stdout)?.trim().to_string();
    Ok(encoded_result.replace("\\n", "\n").replace("\\t", "\t"))
}

fn output_result(selection: &str, copy_mode: bool) -> Result<()> {
    if selection.is_empty() {
        return Ok(());
    }

    if copy_mode {
        let mut cmd = Command::new("pbcopy")
            .stdin(Stdio::piped())
            .spawn()?;

        if let Some(mut stdin) = cmd.stdin.take() {
            stdin.write_all(selection.as_bytes())?;
        }
        cmd.wait()?;

        if let Ok(mut hs) = Command::new("hs")
            .arg("-c")
            .arg(format!("hs.alert.show('Copied ' .. [[{}]])", selection))
            .spawn()
        {
            let _ = hs.wait();
        }
    } else {
        println!("{}", selection);
    }

    Ok(())
}

fn main() -> Result<()> {
    let args = Args::parse();

    let items = get_maccy_data()?;
    let filtered_items = filter_items(
        items,
        args.search.as_deref(),
        args.number,
        args.reverse,
        !args.no_unique,
    );

    // If stdout is not a terminal (being piped), output all items instead of using fzf
    if !std::io::stdout().is_terminal() {
        for item in &filtered_items {
            println!("{}", item);
        }
        return Ok(());
    }

    let selection = run_fzf(&filtered_items, args.copy)?;
    output_result(&selection, args.copy)?;

    Ok(())
}
