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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't treat URLs as passwords
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return false
        }
        
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
    
    func pasteItem(_ item: ClipboardItem, targetApp: NSRunningApplication? = nil) {
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
            self.simulatePaste(targetApp: targetApp)
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