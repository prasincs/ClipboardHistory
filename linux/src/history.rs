use std::env;
use std::fs::{self, File};
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

const MAGIC: &[u8; 4] = b"CHST";
const VERSION: u8 = 1;

#[derive(Clone, Debug)]
pub struct Entry {
    pub timestamp: i64,
    pub content: String,
    pub is_password: bool,
}

impl Entry {
    pub fn new(content: String, is_password: bool) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64;
        Self {
            timestamp,
            content,
            is_password,
        }
    }

    pub fn preview(&self, mask_passwords: bool) -> String {
        if mask_passwords && self.is_password {
            return "••••••••".to_string();
        }

        self
            .content
            .lines()
            .next()
            .unwrap_or_default()
            .chars()
            .take(100)
            .collect::<String>()
    }
}

pub struct History {
    items: Vec<Entry>,
    max_items: usize,
    path: PathBuf,
}

impl History {
    pub fn load(max_items: usize) -> io::Result<Self> {
        let path = history_file_path();
        let mut history = Self {
            items: Vec::new(),
            max_items,
            path,
        };

        history.items = history.read_entries()?;
        history.truncate_if_needed();
        Ok(history)
    }

    pub fn items(&self) -> &[Entry] {
        &self.items
    }

    pub fn add_text(&mut self, text: &str, is_password: bool) -> io::Result<bool> {
        let trimmed = text.trim();
        if trimmed.is_empty() {
            return Ok(false);
        }

        if let Some(index) = self
            .items
            .iter()
            .position(|entry| entry.content == trimmed)
        {
            self.items.remove(index);
        }

        let entry = Entry::new(trimmed.to_string(), is_password);
        self.items.insert(0, entry);
        self.truncate_if_needed();
        self.save()?;
        Ok(true)
    }

    pub fn clear(&mut self) -> io::Result<()> {
        self.items.clear();
        self.save()
    }

    fn truncate_if_needed(&mut self) {
        if self.items.len() > self.max_items {
            self.items.truncate(self.max_items);
        }
    }

    fn save(&self) -> io::Result<()> {
        if let Some(parent) = self.path.parent() {
            fs::create_dir_all(parent)?;
        }

        let mut file = File::create(&self.path)?;
        file.write_all(MAGIC)?;
        file.write_all(&[VERSION])?;

        for entry in &self.items {
            file.write_all(&entry.timestamp.to_le_bytes())?;
            file.write_all(&[entry.is_password as u8])?;
            let bytes = entry.content.as_bytes();
            let len = bytes.len() as u32;
            file.write_all(&len.to_le_bytes())?;
            file.write_all(bytes)?;
        }

        Ok(())
    }

    fn read_entries(&self) -> io::Result<Vec<Entry>> {
        if !self.path.exists() {
            return Ok(Vec::new());
        }

        let mut file = File::open(&self.path)?;
        let mut header = [0u8; 5];
        if file.read_exact(&mut header).is_err() {
            return Ok(Vec::new());
        }

        if &header[0..4] != MAGIC || header[4] != VERSION {
            return Ok(Vec::new());
        }

        let mut items = Vec::new();
        loop {
            let mut timestamp_bytes = [0u8; 8];
            match file.read_exact(&mut timestamp_bytes) {
                Ok(()) => {}
                Err(err) if err.kind() == io::ErrorKind::UnexpectedEof => break,
                Err(err) => return Err(err),
            }

            let timestamp = i64::from_le_bytes(timestamp_bytes);

            let mut password_flag = [0u8; 1];
            file.read_exact(&mut password_flag)?;
            let is_password = password_flag[0] != 0;

            let mut len_bytes = [0u8; 4];
            file.read_exact(&mut len_bytes)?;
            let len = u32::from_le_bytes(len_bytes) as usize;

            let mut buffer = vec![0u8; len];
            file.read_exact(&mut buffer)?;
            let content = String::from_utf8_lossy(&buffer).to_string();

            items.push(Entry {
                timestamp,
                content,
                is_password,
            });
        }

        Ok(items)
    }
}

fn history_file_path() -> PathBuf {
    let base = data_home();
    base.join("clipboard-history").join("history.dat")
}

fn data_home() -> PathBuf {
    if let Ok(dir) = env::var("XDG_DATA_HOME") {
        if !dir.is_empty() {
            return PathBuf::from(dir);
        }
    }

    if let Ok(home) = env::var("HOME") {
        return Path::new(&home).join(".local/share");
    }

    PathBuf::from(".")
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::Path;

    fn setup_temp_home(suffix: &str) -> PathBuf {
        let base = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("target")
            .join("test-data")
            .join(suffix);
        let _ = fs::remove_dir_all(&base);
        fs::create_dir_all(&base).unwrap();
        std::env::set_var("XDG_DATA_HOME", &base);
        base
    }

    #[test]
    fn adds_entries_and_limits_size() {
        let dir = setup_temp_home("history_limit");
        let history_path = dir.join("clipboard-history/history.dat");
        if history_path.exists() {
            fs::remove_file(&history_path).unwrap();
        }

        let mut history = History::load(2).unwrap();
        history.clear().unwrap();
        history.add_text("first", false).unwrap();
        history.add_text("second", false).unwrap();
        history.add_text("third", false).unwrap();

        assert_eq!(history.items().len(), 2);
        assert_eq!(history.items()[0].content, "third");
        assert_eq!(history.items()[1].content, "second");
    }

    #[test]
    fn deduplicates_existing_text() {
        let dir = setup_temp_home("history_dedupe");
        let history_path = dir.join("clipboard-history/history.dat");
        if history_path.exists() {
            fs::remove_file(&history_path).unwrap();
        }

        let mut history = History::load(10).unwrap();
        history.clear().unwrap();
        history.add_text("hello", false).unwrap();
        history.add_text("world", false).unwrap();
        history.add_text("hello", false).unwrap();

        assert_eq!(history.items().len(), 2);
        assert_eq!(history.items()[0].content, "hello");
    }
}
