#if os(macOS)
import XCTest
@testable import ClipboardHistory
import ClipboardCore

class ClipboardHistoryTests: XCTestCase {
    
    func testSettingsPersistence() {
        let settings = Settings.shared
        
        // Save test values
        settings.hotKeyModifiers = [.command, .shift]
        settings.hotKeyCode = 0x08 // 'c' key
        settings.saveSettings()
        
        // Reload settings to test persistence
        settings.loadSettings()
        
        XCTAssertEqual(settings.hotKeyModifiers, [.command, .shift])
        XCTAssertEqual(settings.hotKeyCode, 0x08)
    }
    
    func testHotKeyString() {
        let settings = Settings.shared
        
        settings.hotKeyModifiers = [.control, .shift]
        settings.hotKeyCode = 0x09 // 'v' key
        
        XCTAssertEqual(settings.getHotKeyString(), "⌃⇧V")
        
        settings.hotKeyModifiers = [.command, .option]
        settings.hotKeyCode = 0x08 // 'c' key
        
        XCTAssertEqual(settings.getHotKeyString(), "⌥⌘C")
    }
    
    func testClipboardItemPreview() {
        let longText = String(repeating: "a", count: 200)
        let item = ClipboardItem(content: .text(longText))
        
        XCTAssertEqual(item.preview.count, 100)
        XCTAssertEqual(item.preview, String(repeating: "a", count: 100))
    }
    
    func testClipboardItemEquality() {
        let item1 = ClipboardItem(content: .text("Hello"))
        let item2 = ClipboardItem(content: .text("Hello"))
        let item3 = ClipboardItem(content: .text("World"))
        
        XCTAssertEqual(item1.content, item2.content)
        XCTAssertNotEqual(item1.content, item3.content)
    }
    
    func testPasswordMasking() {
        let settings = Settings.shared
        settings.maskPasswords = true
        
        let passwordItem = ClipboardItem(content: .text("MySecretPassword123!"), sourceApp: "1Password", isPassword: true)
        let normalItem = ClipboardItem(content: .text("Normal text"), sourceApp: "TextEdit", isPassword: false)
        
        XCTAssertEqual(passwordItem.preview, "••••••••")
        XCTAssertEqual(normalItem.preview, "Normal text")
        
        // Test masked content
        switch passwordItem.maskedContent {
        case .text(let maskedText):
            XCTAssertEqual(maskedText, String(repeating: "•", count: 20))
        case .image:
            XCTFail("Expected text content")
        }
        
        // Verify actual content is preserved
        switch passwordItem.content {
        case .text(let actualText):
            XCTAssertEqual(actualText, "MySecretPassword123!")
        case .image:
            XCTFail("Expected text content")
        }
    }
    
    func testPasswordDetection() {
        // Test various password patterns
        XCTAssertTrue(PasswordHeuristics.isLikelyPassword("MyP@ssw0rd123"))
        XCTAssertTrue(PasswordHeuristics.isLikelyPassword("SecurePass#2023"))
        XCTAssertTrue(PasswordHeuristics.isLikelyPassword("xK9$mN2@pL5"))

        // Test non-password patterns
        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("hello world"))
        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("simple"))
        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("12345678"))
        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("ALLCAPS"))
    }
    
    func testExcludedApps() {
        let settings = Settings.shared
        
        // Test default excluded apps
        XCTAssertTrue(settings.excludedApps.contains("1Password"))
        XCTAssertTrue(settings.excludedApps.contains("Bitwarden"))
        
        // Test adding new app
        settings.excludedApps.insert("TestApp")
        settings.saveSettings()
        settings.loadSettings()
        
        XCTAssertTrue(settings.excludedApps.contains("TestApp"))
        
        // Clean up
        settings.excludedApps.remove("TestApp")
        settings.saveSettings()
    }
}
#endif
