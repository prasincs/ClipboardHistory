import Foundation

public enum PasswordHeuristics {
    public static func isLikelyPassword(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return false
        }

        let hasUpperCase = text.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowerCase = text.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = text.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = text.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let isReasonableLength = text.count >= 8 && text.count <= 128
        let hasNoSpaces = !text.contains(" ")
        let hasNoNewlines = !text.contains("\n")

        let mixedCharCount = [hasUpperCase, hasLowerCase, hasNumber, hasSpecialChar].filter { $0 }.count
        return isReasonableLength && hasNoSpaces && hasNoNewlines && mixedCharCount >= 3
    }
}
