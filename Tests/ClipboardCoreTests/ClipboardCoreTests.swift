import XCTest
import ClipboardCore

final class ClipboardCoreTests: XCTestCase {
    func testPreviewMasksPasswordsWhenEnabled() {
        let entry = ClipboardEntry(
            content: .text("SuperSecretPassword!"),
            isPassword: true
        )

        XCTAssertEqual(entry.preview(maskPasswords: true), "••••••••")
        XCTAssertEqual(entry.preview(maskPasswords: false), "SuperSecretPassword!")
    }

    func testPreviewTruncatesLongText() {
        let text = String(repeating: "a", count: 200)
        let entry = ClipboardEntry(content: .text(text))

        XCTAssertEqual(entry.preview(maskPasswords: false).count, 100)
        XCTAssertEqual(entry.preview(maskPasswords: false), String(repeating: "a", count: 100))
    }

    func testMaskedContentLimitsLength() {
        let password = String(repeating: "b", count: 50)
        let entry = ClipboardEntry(content: .text(password), isPassword: true)

        guard case .text(let masked) = entry.maskedContent(maskPasswords: true) else {
            XCTFail("Expected text content")
            return
        }

        XCTAssertEqual(masked, String(repeating: "•", count: 20))
    }

    func testPasswordHeuristics() {
        XCTAssertTrue(PasswordHeuristics.isLikelyPassword("MyP@ssw0rd123"))
        XCTAssertTrue(PasswordHeuristics.isLikelyPassword("SecurePass#2023"))
        XCTAssertTrue(PasswordHeuristics.isLikelyPassword("xK9$mN2@pL5"))

        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("hello world"))
        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("simple"))
        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("12345678"))
        XCTAssertFalse(PasswordHeuristics.isLikelyPassword("ALLCAPS"))
    }

    func testHistoryBufferMaintainsCapacity() {
        let buffer = ClipboardHistoryBuffer(maxItemCount: 3)
        _ = buffer.addText("1", sourceApp: nil, isPassword: false)
        _ = buffer.addText("2", sourceApp: nil, isPassword: false)
        _ = buffer.addText("3", sourceApp: nil, isPassword: false)
        _ = buffer.addText("4", sourceApp: nil, isPassword: false)

        XCTAssertEqual(buffer.items.count, 3)
        XCTAssertEqual(buffer.items.map { entry in
            guard case .text(let value) = entry.content else {
                XCTFail("Expected text content")
                return ""
            }
            return value
        }, ["4", "3", "2"])
    }
}
