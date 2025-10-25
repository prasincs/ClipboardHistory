#if os(macOS)
import Foundation
import AppKit
import Combine
import ClipboardCore

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published private(set) var clipboardHistory: [ClipboardItem] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let historyBuffer = ClipboardHistoryBuffer(maxItemCount: 50)
    
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
                let isPassword = isFromExcludedApp || PasswordHeuristics.isLikelyPassword(string)
                addToHistory(string, sourceApp: sourceApp, isPassword: isPassword)
            } else if let image = NSImage(pasteboard: pasteboard) {
                addImageToHistory(image, sourceApp: sourceApp)
            }
        }
    }

    private func getCurrentAppName() -> String? {
        return NSWorkspace.shared.frontmostApplication?.localizedName
    }

    private func addToHistory(_ text: String, sourceApp: String? = nil, isPassword: Bool = false) {
        guard historyBuffer.addText(text, sourceApp: sourceApp, isPassword: isPassword) != nil else { return }
        refreshHistory()
    }

    private func addImageToHistory(_ image: NSImage, sourceApp: String? = nil) {
        guard let data = image.tiffRepresentation,
              historyBuffer.addImageData(data, sourceApp: sourceApp) != nil else { return }
        refreshHistory()
    }

    private func refreshHistory() {
        clipboardHistory = historyBuffer.items.compactMap { entry in
            makeClipboardItem(from: entry)
        }
    }

    private func makeClipboardItem(from entry: ClipboardEntry) -> ClipboardItem? {
        switch entry.content {
        case .text(let string):
            return ClipboardItem(entry: entry, content: .text(string))
        case .imageData(let data):
            guard let image = NSImage(data: data) else { return nil }
            return ClipboardItem(entry: entry, content: .image(image))
        }
    }
    
    func pasteItem(_ item: ClipboardItem, targetApp: NSRunningApplication? = nil, directPaste: Bool = false) {
        print("ClipboardManager: Starting paste for item, directPaste: \(directPaste)")
        
        if directPaste {
            // For sticky mode: paste directly without changing clipboard
            directPasteItem(item, targetApp: targetApp)
        } else {
            // Normal mode: use clipboard
            clipboardPasteItem(item, targetApp: targetApp)
        }
    }
    
    private func clipboardPasteItem(_ item: ClipboardItem, targetApp: NSRunningApplication? = nil) {
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
            self.simulatePaste(targetApp: targetApp)
        }
    }
    
    private func directPasteItem(_ item: ClipboardItem, targetApp: NSRunningApplication? = nil) {
        // For sticky mode: insert text directly without changing clipboard
        switch item.content {
        case .text(let string):
            print("ClipboardManager: Direct pasting text: \(string.prefix(50))...")
            
            // First, clear any selection to avoid overwriting
            clearSelection()
            
            // Then, move cursor to the end of current content to avoid overwriting
            moveCursorToEnd()
            
            // Add a space before the new content to separate it
            let textToInsert = " " + string
            
            if insertTextDirectly(textToInsert) {
                print("ClipboardManager: Direct text insertion successful")
            } else {
                print("ClipboardManager: Direct insertion failed, falling back to typing simulation")
                simulateTyping(textToInsert)
            }
        case .image(_):
            // For images, we still need to use the clipboard
            print("ClipboardManager: Images require clipboard, using normal paste")
            clipboardPasteItem(item, targetApp: targetApp)
        }
    }
    
    private func clearSelection() {
        // Send right arrow to clear any selection and position cursor at end of selection
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let rightKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x7C, keyDown: true) // Right Arrow
        rightKeyDown?.post(tap: .cgAnnotatedSessionEventTap)
        
        let rightKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x7C, keyDown: false)
        rightKeyUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Small delay
        Thread.sleep(forTimeInterval: 0.05)
    }
    
    private func moveCursorToEnd() {
        // First try Cmd+End to move to end of document
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Send Cmd+End first
        let endKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x77, keyDown: true) // End key
        endKeyDown?.flags = .maskCommand
        endKeyDown?.post(tap: .cgAnnotatedSessionEventTap)
        
        let endKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x77, keyDown: false)
        endKeyUp?.flags = .maskCommand  
        endKeyUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Small delay
        Thread.sleep(forTimeInterval: 0.05)
        
        // Then send Cmd+Right Arrow as backup
        let rightKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x7C, keyDown: true) // Right Arrow
        rightKeyDown?.flags = .maskCommand
        rightKeyDown?.post(tap: .cgAnnotatedSessionEventTap)
        
        let rightKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x7C, keyDown: false)
        rightKeyUp?.flags = .maskCommand  
        rightKeyUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Longer delay to ensure cursor movement completes
        Thread.sleep(forTimeInterval: 0.15)
    }
    
    private func simulateTyping(_ text: String) {
        // Simulate typing the text character by character
        for char in text {
            let charString = String(char)
            let utf16Array = Array(charString.utf16)
            
            // Create a key event for this character
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
                utf16Array.withUnsafeBufferPointer { buffer in
                    if let ptr = buffer.baseAddress {
                        event.keyboardSetUnicodeString(stringLength: utf16Array.count, unicodeString: ptr)
                    }
                }
                event.post(tap: .cghidEventTap)
                
                let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
                utf16Array.withUnsafeBufferPointer { buffer in
                    if let ptr = buffer.baseAddress {
                        keyUpEvent?.keyboardSetUnicodeString(stringLength: utf16Array.count, unicodeString: ptr)
                    }
                }
                keyUpEvent?.post(tap: .cghidEventTap)
                
                // Small delay between characters
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
    }
    
    private func simulatePaste(targetApp: NSRunningApplication? = nil) {
        print("ClipboardManager: simulatePaste called")
        
        // Check if we need special paste behavior
        let pasteBehavior = getPasteBehaviorForApp(targetApp)
        
        // Just perform the paste - app activation is handled in ClipboardHistoryView
        performPaste(behavior: pasteBehavior)
    }
    
    private func getPasteBehaviorForApp(_ app: NSRunningApplication?) -> PasteBehavior {
        guard let app = app,
              let bundleId = app.bundleIdentifier else {
            return .normal
        }
        
        // Check app-specific behaviors
        for appBehavior in Settings.shared.appPasteBehaviors {
            if appBehavior.appIdentifier == bundleId {
                // If there's a URL pattern, check if current URL matches
                if let urlPattern = appBehavior.urlPattern {
                    if let currentURL = getCurrentBrowserURL(for: app) {
                        if currentURL.contains(urlPattern) {
                            return appBehavior.behavior
                        }
                    }
                    // URL pattern doesn't match, use normal paste
                    return .normal
                } else {
                    // No URL pattern required, use the behavior
                    return appBehavior.behavior
                }
            }
        }
        
        return .normal
    }
    
    private func getCurrentBrowserURL(for app: NSRunningApplication) -> String? {
        // Use AppleScript to get the current URL from the browser
        var script = ""
        
        switch app.bundleIdentifier {
        case "com.google.Chrome":
            script = """
                tell application "Google Chrome"
                    if (count of windows) > 0 then
                        return URL of active tab of front window
                    end if
                end tell
            """
        case "com.apple.Safari":
            script = """
                tell application "Safari"
                    if (count of documents) > 0 then
                        return URL of front document
                    end if
                end tell
            """
        case "org.mozilla.firefox":
            script = """
                tell application "Firefox"
                    if (count of windows) > 0 then
                        return URL of front window
                    end if
                end tell
            """
        default:
            return nil
        }
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            
            if error == nil {
                return result.stringValue
            }
        }
        
        return nil
    }
    
    private func performPaste(behavior: PasteBehavior = .normal) {
        print("ClipboardManager: performPaste called with behavior: \(behavior)")
        
        // Get the current pasteboard content
        let pasteboard = NSPasteboard.general
        
        // Check if this is a URL for Google Docs link behavior
        var isURL = false
        if behavior == .googleDocsLink, let string = pasteboard.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            isURL = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
            
            // If it's not a URL, fall back to normal paste
            if !isURL {
                print("ClipboardManager: Content is not a URL, using normal paste")
                performPaste(behavior: .normal)
                return
            }
        }
        
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
                performCGEventPaste(behavior: behavior)
            } else {
                print("ClipboardManager: AppleScript paste executed successfully")
                
                // If Google Docs link behavior and content is a URL, send Cmd+K after paste
                if behavior == .googleDocsLink, let string = pasteboard.string(forType: .string) {
                    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.performGoogleDocsLinkCommand()
                        }
                    }
                }
            }
        } else {
            print("ClipboardManager: Failed to create AppleScript, falling back to CGEvent")
            performCGEventPaste()
            
            // If Google Docs link behavior and content is a URL, send Cmd+K after paste
            if behavior == .googleDocsLink, let string = pasteboard.string(forType: .string) {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.performGoogleDocsLinkCommand()
                    }
                }
            }
        }
    }
    
    private func insertTextDirectly(_ text: String) -> Bool {
        // Try to get the focused element
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if result == .success, let element = focusedElement {
            // Get the current text content and cursor position
            var currentValue: CFTypeRef?
            let valueResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXValueAttribute as CFString, &currentValue)
            
            var selectedTextRange: CFTypeRef?
            let rangeResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &selectedTextRange)
            
            if valueResult == .success && rangeResult == .success,
               let currentText = currentValue as? String,
               let range = selectedTextRange {
                
                // Extract the cursor position from the range
                var location: CFIndex = 0
                var length: CFIndex = 0
                
                if AXValueGetValue(range as! AXValue, .cfRange, &location) == true {
                    // Insert text at cursor position without replacing selection
                    let insertionIndex = currentText.index(currentText.startIndex, offsetBy: min(location, currentText.count))
                    let newText = String(currentText[..<insertionIndex]) + text + String(currentText[insertionIndex...])
                    
                    // Set the new text
                    let setResult = AXUIElementSetAttributeValue(element as! AXUIElement, kAXValueAttribute as CFString, newText as CFTypeRef)
                    
                    if setResult == .success {
                        // Move cursor to after the inserted text
                        let newCursorPosition = location + text.count
                        var newRange = CFRange(location: newCursorPosition, length: 0)
                        if let axRange = AXValueCreate(.cfRange, &newRange) {
                            AXUIElementSetAttributeValue(element as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, axRange)
                        }
                        return true
                    }
                }
            }
            
            // Fallback: try inserting at selection (this might still replace)
            let insertResult = AXUIElementSetAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
            return insertResult == .success
        }
        
        return false
    }
    
    private func performCGEventPaste(behavior: PasteBehavior = .normal) {
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
        let downResult: Void? = keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        let upResult: Void? = keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        print("ClipboardManager: Key events posted - down: \(String(describing: downResult)), up: \(String(describing: upResult))")
        
        if downResult == nil || upResult == nil {
            print("ClipboardManager: Failed to post key events - check accessibility permissions")
        }
        
        // If Google Docs link behavior and content is a URL, send Cmd+K after paste
        if behavior == .googleDocsLink {
            let pasteboard = NSPasteboard.general
            if let string = pasteboard.string(forType: .string) {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.performGoogleDocsLinkCommand()
                    }
                }
            }
        }
    }
    
    private func performGoogleDocsLinkCommand() {
        print("ClipboardManager: Preparing Google Docs link command")
        
        // Get the URL text to know how many characters to select
        let pasteboard = NSPasteboard.general
        guard let urlString = pasteboard.string(forType: .string) else {
            print("ClipboardManager: No string in pasteboard")
            return
        }
        
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let charCount = trimmedURL.count
        
        // Select the text we just pasted by using Shift+Left Arrow for the number of characters
        let selectScript = """
            tell application "System Events"
                key down shift
                repeat \(charCount) times
                    key code 123
                end repeat
                key up shift
            end tell
        """
        
        if let selectScript = NSAppleScript(source: selectScript) {
            var error: NSDictionary?
            selectScript.executeAndReturnError(&error)
            
            if let error = error {
                print("ClipboardManager: Failed to select text: \(error)")
                // Try CGEvent method
                performCGEventSelectText(charCount: charCount)
            } else {
                print("ClipboardManager: Selected pasted text (\(charCount) characters)")
            }
        } else {
            performCGEventSelectText(charCount: charCount)
        }
        
        // Wait a bit for the selection to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        // Now send Cmd+K
        let linkScript = """
            tell application "System Events"
                keystroke "k" using command down
            end tell
        """
        
        if let appleScript = NSAppleScript(source: linkScript) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("ClipboardManager: AppleScript Cmd+K error: \(error)")
                // Fall back to CGEvent method
                performCGEventCmdK()
            } else {
                print("ClipboardManager: AppleScript Cmd+K executed successfully")
            }
        } else {
            performCGEventCmdK()
        }
    }
    
    private func performCGEventSelectText(charCount: Int) {
        print("ClipboardManager: Selecting \(charCount) characters with CGEvent")
        
        let source = CGEventSource(stateID: .combinedSessionState)
        source?.localEventsSuppressionInterval = 0.0
        
        // Hold Shift key down
        let shiftDown = CGEvent(keyboardEventSource: source, virtualKey: 0x38, keyDown: true)
        shiftDown?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Press Left Arrow for each character
        for _ in 0..<charCount {
            let leftArrowDown = CGEvent(keyboardEventSource: source, virtualKey: 0x7B, keyDown: true)
            leftArrowDown?.flags = .maskShift
            leftArrowDown?.post(tap: .cgAnnotatedSessionEventTap)
            
            let leftArrowUp = CGEvent(keyboardEventSource: source, virtualKey: 0x7B, keyDown: false)
            leftArrowUp?.flags = .maskShift
            leftArrowUp?.post(tap: .cgAnnotatedSessionEventTap)
            
            // Small delay between keypresses
            Thread.sleep(forTimeInterval: 0.001)
        }
        
        // Release Shift key
        let shiftUp = CGEvent(keyboardEventSource: source, virtualKey: 0x38, keyDown: false)
        shiftUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    private func performCGEventCmdK() {
        print("ClipboardManager: Trying CGEvent Cmd+K method")

        let source = CGEventSource(stateID: .combinedSessionState)
        source?.localEventsSuppressionInterval = 0.0
        
        // Create key down event for Cmd+K (0x28 is 'k')
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x28, keyDown: true)
        keyDown?.flags = .maskCommand
        
        // Create key up event
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x28, keyDown: false)
        keyUp?.flags = .maskCommand
        
        // Post the events
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }

    func clearHistory() {
        historyBuffer.clear()
        clipboardHistory.removeAll()
    }
}

struct ClipboardItem: Identifiable {
    let entry: ClipboardEntry
    let content: ClipboardContent

    var id: UUID { entry.id }
    var timestamp: Date { entry.timestamp }
    var sourceApp: String? { entry.sourceApp }
    var isPassword: Bool { entry.isPassword }

    init(entry: ClipboardEntry, content: ClipboardContent) {
        self.entry = entry
        self.content = content
    }

    init(content: ClipboardContent, sourceApp: String? = nil, isPassword: Bool = false) {
        self.content = content
        switch content {
        case .text(let string):
            self.entry = ClipboardEntry(content: .text(string), sourceApp: sourceApp, isPassword: isPassword)
        case .image(let image):
            let data = image.tiffRepresentation ?? Data()
            self.entry = ClipboardEntry(content: .imageData(data), sourceApp: sourceApp, isPassword: isPassword)
        }
    }

    var preview: String {
        entry.preview(maskPasswords: Settings.shared.maskPasswords)
    }

    var maskedContent: ClipboardContent {
        switch entry.maskedContent(maskPasswords: Settings.shared.maskPasswords) {
        case .text(let string):
            return .text(string)
        case .imageData:
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
#endif
