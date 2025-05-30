import XCTest
@testable import ClipboardHistory

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
}