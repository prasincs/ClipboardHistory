use std::io::{self, Write};
use std::process::{Command, Stdio};

use crate::history::Entry;

pub fn select_entry(entries: &[Entry]) -> io::Result<Option<usize>> {
    if entries.is_empty() {
        return Ok(None);
    }

    let mut input = String::new();
    for (index, entry) in entries.iter().enumerate() {
        let preview = entry.preview(true).replace('\t', "    ");
        input.push_str(&format!("{index}\t{preview}\n"));
    }

    let mut child = Command::new("wofi")
        .args(["--dmenu", "--prompt", "Clipboard"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .map_err(|err| io::Error::new(io::ErrorKind::NotFound, format!("failed to run wofi: {err}")))?;

    if let Some(stdin) = child.stdin.as_mut() {
        stdin.write_all(input.as_bytes())?;
    }

    let output = child.wait_with_output()?;
    if !output.status.success() {
        return Ok(None);
    }

    let selection = String::from_utf8_lossy(&output.stdout);
    let index_part = selection.split_whitespace().next().unwrap_or_default();
    if index_part.is_empty() {
        return Ok(None);
    }

    match index_part.parse::<usize>() {
        Ok(index) => Ok(Some(index)),
        Err(_) => Ok(None),
    }
}
