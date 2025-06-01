import Foundation
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var clipboardHistory: [ClipboardItem] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let maxHistoryItems = 50
    
    private init() {}
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        
        if changeCount != lastChangeCount {
            lastChangeCount = changeCount
            
            let sourceApp = getCurrentAppName()
            let isFromExcludedApp = Settings.shared.excludedApps.contains(sourceApp ?? "")
            
            if let string = pasteboard.string(forType: .string), !string.isEmpty {
                addToHistory(string, sourceApp: sourceApp, isPassword: isFromExcludedApp || isLikelyPassword(string))
            } else if let image = NSImage(pasteboard: pasteboard) {
                addImageToHistory(image, sourceApp: sourceApp)
            }
        }
    }
    
    private func getCurrentAppName() -> String? {
        return NSWorkspace.shared.frontmostApplication?.localizedName
    }
    
    func isLikelyPassword(_ text: String) -> Bool {
        // Check if text looks like a password
        let hasUpperCase = text.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowerCase = text.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = text.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = text.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let isReasonableLength = text.count >= 8 && text.count <= 128
        let hasNoSpaces = !text.contains(" ")
        let hasNoNewlines = !text.contains("\n")
        
        // Consider it a password if it has mixed characters and reasonable length
        let mixedCharCount = [hasUpperCase, hasLowerCase, hasNumber, hasSpecialChar].filter { $0 }.count
        return isReasonableLength && hasNoSpaces && hasNoNewlines && mixedCharCount >= 3
    }
    
    private func addToHistory(_ text: String, sourceApp: String? = nil, isPassword: Bool = false) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if let existingIndex = clipboardHistory.firstIndex(where: { 
            if case .text(let existingText) = $0.content {
                return existingText == trimmedText
            }
            return false
        }) {
            clipboardHistory.remove(at: existingIndex)
        }
        
        let newItem = ClipboardItem(content: .text(trimmedText), sourceApp: sourceApp, isPassword: isPassword)
        clipboardHistory.insert(newItem, at: 0)
        
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory.removeLast()
        }
    }
    
    private func addImageToHistory(_ image: NSImage, sourceApp: String? = nil) {
        if let existingIndex = clipboardHistory.firstIndex(where: {
            if case .image = $0.content {
                return true
            }
            return false
        }) {
            clipboardHistory.remove(at: existingIndex)
        }
        
        let newItem = ClipboardItem(content: .image(image), sourceApp: sourceApp)
        clipboardHistory.insert(newItem, at: 0)
        
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory.removeLast()
        }
    }
    
    func pasteItem(_ item: ClipboardItem) {
        print("ClipboardManager: Starting paste for item")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Always paste the actual content, not masked
        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
            print("ClipboardManager: Set text to pasteboard: \(string.prefix(50))...")
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
                print("ClipboardManager: Set image to pasteboard")
            }
        }
        
        lastChangeCount = pasteboard.changeCount
        
        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        print("ClipboardManager: Accessibility permissions: \(trusted)")
        
        if !trusted {
            print("ClipboardManager: Requesting accessibility permissions...")
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        print("ClipboardManager: simulatePaste called")
        // Just perform the paste - app activation is handled in ClipboardHistoryView
        performPaste()
    }
    
    private func performPaste() {
        print("ClipboardManager: performPaste called")
        
        // Get the current pasteboard content
        let pasteboard = NSPasteboard.general
        
        // Try direct insertion first for text content
        if let string = pasteboard.string(forType: .string) {
            print("ClipboardManager: Trying direct text insertion")
            
            // Try to insert text directly using accessibility API
            if insertTextDirectly(string) {
                print("ClipboardManager: Direct text insertion successful")
                return
            }
        }
        
        // Try AppleScript method
        let script = """
            tell application "System Events"
                keystroke "v" using command down
            end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("ClipboardManager: AppleScript error: \(error)")
                // Fall back to CGEvent method
                performCGEventPaste()
            } else {
                print("ClipboardManager: AppleScript paste executed successfully")
            }
        } else {
            print("ClipboardManager: Failed to create AppleScript, falling back to CGEvent")
            performCGEventPaste()
        }
    }
    
    private func insertTextDirectly(_ text: String) -> Bool {
        // Try to get the focused element
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if result == .success, let element = focusedElement {
            // Try to set the value directly
            let setResult = AXUIElementSetAttributeValue(element as! AXUIElement, kAXValueAttribute as CFString, text as CFTypeRef)
            
            if setResult == .success {
                return true
            }
            
            // If that fails, try to insert at the selection
            var selectedTextRange: CFTypeRef?
            let rangeResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &selectedTextRange)
            
            if rangeResult == .success {
                // Insert text at current position
                let insertResult = AXUIElementSetAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
                return insertResult == .success
            }
        }
        
        return false
    }
    
    private func performCGEventPaste() {
        print("ClipboardManager: Trying CGEvent paste method")
        
        let source = CGEventSource(stateID: .combinedSessionState)
        source?.localEventsSuppressionInterval = 0.0
        
        // Create key down event for Cmd+V
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        
        // Create key up event
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        
        // Post the events
        let downResult = keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        let upResult = keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        print("ClipboardManager: Key events posted - down: \(String(describing: downResult)), up: \(String(describing: upResult))")
        
        if downResult == nil || upResult == nil {
            print("ClipboardManager: Failed to post key events - check accessibility permissions")
        }
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
    }
}

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: ClipboardContent
    let timestamp = Date()
    let sourceApp: String?
    let isPassword: Bool
    
    init(content: ClipboardContent, sourceApp: String? = nil, isPassword: Bool = false) {
        self.content = content
        self.sourceApp = sourceApp
        self.isPassword = isPassword
    }
    
    var preview: String {
        switch content {
        case .text(let string):
            if isPassword && Settings.shared.maskPasswords {
                return "••••••••"
            }
            let lines = string.components(separatedBy: .newlines)
            let preview = lines.first ?? ""
            return String(preview.prefix(100))
        case .image:
            return "Image"
        }
    }
    
    var maskedContent: ClipboardContent {
        switch content {
        case .text(let string):
            if isPassword && Settings.shared.maskPasswords {
                return .text(String(repeating: "•", count: min(string.count, 20)))
            }
            return content
        case .image:
            return content
        }
    }
}

enum ClipboardContent: Equatable {
    case text(String)
    case image(NSImage)
    
    static func == (lhs: ClipboardContent, rhs: ClipboardContent) -> Bool {
        switch (lhs, rhs) {
        case (.text(let lhsText), .text(let rhsText)):
            return lhsText == rhsText
        case (.image, .image):
            return true
        default:
            return false
        }
    }
}