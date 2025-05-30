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
            
            if let string = pasteboard.string(forType: .string), !string.isEmpty {
                addToHistory(string)
            } else if let image = NSImage(pasteboard: pasteboard) {
                addImageToHistory(image)
            }
        }
    }
    
    private func addToHistory(_ text: String) {
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
        
        let newItem = ClipboardItem(content: .text(trimmedText))
        clipboardHistory.insert(newItem, at: 0)
        
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory.removeLast()
        }
    }
    
    private func addImageToHistory(_ image: NSImage) {
        if let existingIndex = clipboardHistory.firstIndex(where: {
            if case .image = $0.content {
                return true
            }
            return false
        }) {
            clipboardHistory.remove(at: existingIndex)
        }
        
        let newItem = ClipboardItem(content: .image(image))
        clipboardHistory.insert(newItem, at: 0)
        
        if clipboardHistory.count > maxHistoryItems {
            clipboardHistory.removeLast()
        }
    }
    
    func pasteItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        }
        
        lastChangeCount = pasteboard.changeCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
    }
}

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: ClipboardContent
    let timestamp = Date()
    
    var preview: String {
        switch content {
        case .text(let string):
            let lines = string.components(separatedBy: .newlines)
            let preview = lines.first ?? ""
            return String(preview.prefix(100))
        case .image:
            return "Image"
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