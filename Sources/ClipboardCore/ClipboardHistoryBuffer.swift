import Foundation

public final class ClipboardHistoryBuffer {
    public private(set) var items: [ClipboardEntry]
    public let maxItemCount: Int

    public init(maxItemCount: Int = 50, items: [ClipboardEntry] = []) {
        self.maxItemCount = max(maxItemCount, 0)
        self.items = []
        items.forEach { _ = appendEntry($0) }
    }

    @discardableResult
    public func addText(_ text: String, sourceApp: String?, isPassword: Bool) -> ClipboardEntry? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        removeDuplicateText(trimmed)
        let entry = ClipboardEntry(content: .text(trimmed), sourceApp: sourceApp, isPassword: isPassword)
        appendEntry(entry)
        return entry
    }

    @discardableResult
    public func addImageData(_ data: Data, sourceApp: String?) -> ClipboardEntry? {
        guard !data.isEmpty else { return nil }

        removeExistingImage()
        let entry = ClipboardEntry(content: .imageData(data), sourceApp: sourceApp, isPassword: false)
        appendEntry(entry)
        return entry
    }

    public func clear() {
        items.removeAll()
    }

    @discardableResult
    private func appendEntry(_ entry: ClipboardEntry) -> ClipboardEntry {
        items.insert(entry, at: 0)
        trimIfNeeded()
        return entry
    }

    private func trimIfNeeded() {
        if items.count > maxItemCount {
            items.removeLast(items.count - maxItemCount)
        }
    }

    private func removeDuplicateText(_ text: String) {
        if let existingIndex = items.firstIndex(where: { entry in
            if case .text(let existing) = entry.content {
                return existing == text
            }
            return false
        }) {
            items.remove(at: existingIndex)
        }
    }

    private func removeExistingImage() {
        if let existingIndex = items.firstIndex(where: { entry in
            if case .imageData = entry.content {
                return true
            }
            return false
        }) {
            items.remove(at: existingIndex)
        }
    }
}
