use std::io::{self, Write};
use std::process::{Command, Stdio};

pub fn read_clipboard() -> io::Result<Option<String>> {
    let output = Command::new("wl-paste")
        .arg("--no-newline")
        .output();

    let output = match output {
        Ok(output) => output,
        Err(err) => {
            return Err(io::Error::new(
                io::ErrorKind::NotFound,
                format!("failed to run wl-paste: {err}"),
            ))
        }
    };

    if !output.status.success() {
        return Ok(None);
    }

    let text = String::from_utf8_lossy(&output.stdout).to_string();
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return Ok(None);
    }

    Ok(Some(trimmed.to_string()))
}

pub fn write_clipboard(text: &str) -> io::Result<()> {
    let mut child = Command::new("wl-copy")
        .stdin(Stdio::piped())
        .spawn()
        .map_err(|err| io::Error::new(io::ErrorKind::NotFound, format!("failed to run wl-copy: {err}")))?;

    if let Some(stdin) = child.stdin.as_mut() {
        stdin.write_all(text.as_bytes())?;
    }

    let status = child.wait()?;
    if status.success() {
        Ok(())
    } else {
        Err(io::Error::new(
            io::ErrorKind::Other,
            format!("wl-copy exited with status {status}"),
        ))
    }
}
