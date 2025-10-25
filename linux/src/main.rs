mod clipboard;
mod history;
mod password;
mod wofi;

use std::env;
use std::error::Error;
use std::io;
use std::thread;
use std::time::Duration;

use clipboard::{read_clipboard, write_clipboard};
use history::History;
use password::is_likely_password;
use wofi::select_entry;

const DEFAULT_HISTORY_SIZE: usize = 50;
const POLL_INTERVAL_MS: u64 = 400;

fn main() {
    if let Err(err) = entrypoint() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn entrypoint() -> Result<(), Box<dyn Error>> {
    let mut args: Vec<String> = env::args().skip(1).collect();
    let command = args.first().cloned();

    match command.as_deref() {
        Some("daemon") => run_daemon(),
        Some("select") => {
            // Remove the command name before parsing options
            let _ = args.remove(0);
            match SelectCommand::parse(&args)? {
                SelectCommand::Run(options) => run_select(options),
                SelectCommand::Help => {
                    print_select_usage();
                    Ok(())
                }
            }
        }
        Some("print") => run_print(),
        Some("clear") => run_clear(),
        Some("help") | None => {
            print_usage();
            Ok(())
        }
        Some(cmd) => {
            eprintln!("unknown command: {cmd}");
            print_usage();
            Err("invalid command".into())
        }
    }
}

fn run_daemon() -> Result<(), Box<dyn Error>> {
    let mut history = History::load(DEFAULT_HISTORY_SIZE)?;
    let mut last_snapshot = history.items().first().map(|entry| entry.content.clone());

    loop {
        match read_clipboard() {
            Ok(Some(current)) => {
                if Some(&current) != last_snapshot.as_ref() {
                    let is_password = is_likely_password(&current);
                    if history.add_text(&current, is_password)? {
                        last_snapshot = Some(current);
                    }
                }
            }
            Ok(None) => {}
            Err(err) => {
                eprintln!("clipboard error: {err}");
                thread::sleep(Duration::from_secs(2));
                continue;
            }
        }

        thread::sleep(Duration::from_millis(POLL_INTERVAL_MS));
    }

    #[allow(unreachable_code)]
    Ok(())
}

fn run_select(options: SelectOptions) -> Result<(), Box<dyn Error>> {
    let mut history = History::load(DEFAULT_HISTORY_SIZE)?;
    let mut last_index = None;

    loop {
        let items = history.items();
        if items.is_empty() {
            println!("Clipboard history is empty.");
            return Ok(());
        }

        let selection = select_entry(items, last_index)?;
        let Some(index) = selection else {
            return Ok(());
        };

        if index >= items.len() {
            if !options.sticky {
                return Ok(());
            }
            last_index = None;
            continue;
        }

        let entry = &items[index];
        write_clipboard(&entry.content)?;

        if !options.sticky {
            return Ok(());
        }

        last_index = Some(index);
        // Reload history to reflect any daemon updates between selections.
        history = History::load(DEFAULT_HISTORY_SIZE)?;
    }
}

fn run_print() -> Result<(), Box<dyn Error>> {
    let history = History::load(DEFAULT_HISTORY_SIZE)?;
    for (index, entry) in history.items().iter().enumerate() {
        let preview = entry.preview(true);
        println!("{index}: {preview}");
    }
    Ok(())
}

fn run_clear() -> Result<(), Box<dyn Error>> {
    let mut history = History::load(DEFAULT_HISTORY_SIZE)?;
    history.clear()?;
    println!("Clipboard history cleared.");
    Ok(())
}

fn print_usage() {
    println!("ClipboardHistory Linux frontend");
    println!("\nUsage:");
    println!(
        "  clipboard-history-linux daemon            # Monitor the clipboard and record history"
    );
    println!(
        "  clipboard-history-linux select [options] # Show the history in wofi and copy selection"
    );
    println!("  clipboard-history-linux print             # Print the masked history to stdout");
    println!("  clipboard-history-linux clear             # Clear stored history");
    println!("\nRun 'clipboard-history-linux select --help' to see selector options.");
}

fn print_select_usage() {
    println!("ClipboardHistory Linux selector");
    println!("\nOptions:");
    println!("  --sticky    Keep the selector open for sequential pastes");
    println!("  --help      Show this message");
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct SelectOptions {
    sticky: bool,
}

#[derive(Debug)]
enum SelectCommand {
    Run(SelectOptions),
    Help,
}

impl SelectCommand {
    fn parse(args: &[String]) -> Result<Self, Box<dyn Error>> {
        let mut sticky = false;

        for arg in args {
            match arg.as_str() {
                "--sticky" => sticky = true,
                "--help" | "-h" => return Ok(SelectCommand::Help),
                other => {
                    return Err(format!("unknown select option: {other}").into());
                }
            }
        }

        Ok(SelectCommand::Run(SelectOptions { sticky }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::Path;

    #[test]
    fn usage_prints_without_panic() {
        print_usage();
    }

    #[test]
    fn history_adds_items() -> io::Result<()> {
        let base = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join("test-data")
            .join("main_history");
        let _ = fs::remove_dir_all(&base);
        fs::create_dir_all(&base).unwrap();
        std::env::set_var("XDG_DATA_HOME", &base);

        let mut history = History::load(5)?;
        history.clear()?;
        assert!(history.add_text("hello", false)?);
        assert_eq!(history.items().len(), 1);
        Ok(())
    }

    #[test]
    fn parse_sticky_option() {
        let args = vec!["--sticky".to_string()];
        let command = SelectCommand::parse(&args).expect("failed to parse sticky option");
        match command {
            SelectCommand::Run(options) => assert!(options.sticky),
            SelectCommand::Help => panic!("expected to run selector"),
        }
    }

    #[test]
    fn parse_help_option() {
        let args = vec!["--help".to_string()];
        let command = SelectCommand::parse(&args).expect("failed to parse help option");
        match command {
            SelectCommand::Run(_) => panic!("expected help"),
            SelectCommand::Help => {}
        }
    }

    #[test]
    fn parse_rejects_unknown_flags() {
        let args = vec!["--unknown".to_string()];
        let err = SelectCommand::parse(&args).unwrap_err();
        assert_eq!(err.to_string(), "unknown select option: --unknown");
    }
}
