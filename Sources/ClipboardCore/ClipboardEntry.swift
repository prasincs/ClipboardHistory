import Foundation

public enum ClipboardContentValue: Equatable {
    case text(String)
    case imageData(Data)
}

public struct ClipboardEntry: Identifiable, Equatable {
    public let id: UUID
    public let content: ClipboardContentValue
    public let timestamp: Date
    public let sourceApp: String?
    public let isPassword: Bool

    public init(id: UUID = UUID(),
                content: ClipboardContentValue,
                timestamp: Date = Date(),
                sourceApp: String? = nil,
                isPassword: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.sourceApp = sourceApp
        self.isPassword = isPassword
    }
}

public extension ClipboardEntry {
    func preview(maskPasswords: Bool) -> String {
        switch content {
        case .text(let string):
            if maskPasswords && isPassword {
                return "••••••••"
            }
            let lines = string.components(separatedBy: .newlines)
            let preview = lines.first ?? ""
            return String(preview.prefix(100))
        case .imageData:
            return "Image"
        }
    }

    func maskedContent(maskPasswords: Bool) -> ClipboardContentValue {
        switch content {
        case .text(let string):
            if maskPasswords && isPassword {
                let maskLength = min(string.count, 20)
                return .text(String(repeating: "•", count: maskLength))
            }
            return content
        case .imageData:
            return content
        }
    }
}
