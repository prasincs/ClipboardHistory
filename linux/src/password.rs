pub fn is_likely_password(text: &str) -> bool {
    let trimmed = text.trim();
    if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        return false;
    }

    let has_upper = text.chars().any(|c| c.is_ascii_uppercase());
    let has_lower = text.chars().any(|c| c.is_ascii_lowercase());
    let has_number = text.chars().any(|c| c.is_ascii_digit());
    let has_special = text.chars().any(|c| !c.is_ascii_alphanumeric());

    let length = text.chars().count();
    let has_no_spaces = !text.chars().any(|c| c == ' ');
    let has_no_newlines = !text.contains('\n');

    let mixed_count = [has_upper, has_lower, has_number, has_special]
        .iter()
        .filter(|&&v| v)
        .count();

    length >= 8 && length <= 128 && has_no_spaces && has_no_newlines && mixed_count >= 3
}

#[cfg(test)]
mod tests {
    use super::is_likely_password;

    #[test]
    fn detects_password_like_strings() {
        assert!(is_likely_password("P@ssw0rd!"));
        assert!(is_likely_password("ComplexPass123$"));
    }

    #[test]
    fn ignores_links_and_simple_text() {
        assert!(!is_likely_password("https://example.com"));
        assert!(!is_likely_password("hello world"));
        assert!(!is_likely_password("short"));
    }
}
