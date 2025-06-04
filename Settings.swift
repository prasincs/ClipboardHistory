import Foundation
import AppKit
import HotKey

enum PasteBehavior: String, CaseIterable, Codable {
    case normal = "Normal Paste"
    case googleDocsLink = "Paste as Link (Cmd+K)"
    
    var description: String {
        return self.rawValue
    }
}

struct AppPasteBehavior: Codable {
    let appIdentifier: String
    let appName: String
    let urlPattern: String?
    let behavior: PasteBehavior
}

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var hotKeyModifiers: NSEvent.ModifierFlags = [.control, .shift]
    @Published var hotKeyCode: UInt16 = 0x09 // 'v' key
    @Published var excludedApps: Set<String> = ["1Password", "1Password 7", "Bitwarden", "LastPass", "Dashlane", "Keeper", "KeePassXC", "Enpass"]
    @Published var maskPasswords: Bool = true
    @Published var appPasteBehaviors: [AppPasteBehavior] = [
        AppPasteBehavior(
            appIdentifier: "com.google.Chrome",
            appName: "Google Chrome",
            urlPattern: "docs.google.com",
            behavior: .googleDocsLink
        )
    ]
    
    private let hotKeyModifiersKey = "hotKeyModifiers"
    private let hotKeyCodeKey = "hotKeyCode"
    private let excludedAppsKey = "excludedApps"
    private let maskPasswordsKey = "maskPasswords"
    private let appPasteBehaviorsKey = "appPasteBehaviors"
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        if let modifiersRaw = UserDefaults.standard.object(forKey: hotKeyModifiersKey) as? UInt {
            hotKeyModifiers = NSEvent.ModifierFlags(rawValue: modifiersRaw)
        }
        
        if UserDefaults.standard.object(forKey: hotKeyCodeKey) != nil {
            hotKeyCode = UInt16(UserDefaults.standard.integer(forKey: hotKeyCodeKey))
        }
        
        if let savedApps = UserDefaults.standard.array(forKey: excludedAppsKey) as? [String] {
            excludedApps = Set(savedApps)
        }
        
        if UserDefaults.standard.object(forKey: maskPasswordsKey) != nil {
            maskPasswords = UserDefaults.standard.bool(forKey: maskPasswordsKey)
        }
        
        if let data = UserDefaults.standard.data(forKey: appPasteBehaviorsKey),
           let behaviors = try? JSONDecoder().decode([AppPasteBehavior].self, from: data) {
            appPasteBehaviors = behaviors
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(hotKeyModifiers.rawValue, forKey: hotKeyModifiersKey)
        UserDefaults.standard.set(Int(hotKeyCode), forKey: hotKeyCodeKey)
        UserDefaults.standard.set(Array(excludedApps), forKey: excludedAppsKey)
        UserDefaults.standard.set(maskPasswords, forKey: maskPasswordsKey)
        
        if let data = try? JSONEncoder().encode(appPasteBehaviors) {
            UserDefaults.standard.set(data, forKey: appPasteBehaviorsKey)
        }
    }
    
    func getHotKeyString() -> String {
        var keys: [String] = []
        
        if hotKeyModifiers.contains(.control) {
            keys.append("⌃")
        }
        if hotKeyModifiers.contains(.option) {
            keys.append("⌥")
        }
        if hotKeyModifiers.contains(.shift) {
            keys.append("⇧")
        }
        if hotKeyModifiers.contains(.command) {
            keys.append("⌘")
        }
        
        if let keyString = keyCodeToString(hotKeyCode) {
            keys.append(keyString)
        }
        
        return keys.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        switch keyCode {
        case 0x00: return "A"
        case 0x01: return "S"
        case 0x02: return "D"
        case 0x03: return "F"
        case 0x04: return "H"
        case 0x05: return "G"
        case 0x06: return "Z"
        case 0x07: return "X"
        case 0x08: return "C"
        case 0x09: return "V"
        case 0x0B: return "B"
        case 0x0C: return "Q"
        case 0x0D: return "W"
        case 0x0E: return "E"
        case 0x0F: return "R"
        case 0x10: return "Y"
        case 0x11: return "T"
        case 0x12: return "1"
        case 0x13: return "2"
        case 0x14: return "3"
        case 0x15: return "4"
        case 0x16: return "6"
        case 0x17: return "5"
        case 0x18: return "="
        case 0x19: return "9"
        case 0x1A: return "7"
        case 0x1B: return "-"
        case 0x1C: return "8"
        case 0x1D: return "0"
        case 0x1E: return "]"
        case 0x1F: return "O"
        case 0x20: return "U"
        case 0x21: return "["
        case 0x22: return "I"
        case 0x23: return "P"
        case 0x25: return "L"
        case 0x26: return "J"
        case 0x27: return "'"
        case 0x28: return "K"
        case 0x29: return ";"
        case 0x2A: return "\\"
        case 0x2B: return ","
        case 0x2C: return "/"
        case 0x2D: return "N"
        case 0x2E: return "M"
        case 0x2F: return "."
        case 0x32: return "`"
        case 0x24: return "↩"
        case 0x30: return "⇥"
        case 0x31: return "Space"
        case 0x33: return "⌫"
        case 0x35: return "⎋"
        case 0x7A: return "F1"
        case 0x78: return "F2"
        case 0x63: return "F3"
        case 0x76: return "F4"
        case 0x60: return "F5"
        case 0x61: return "F6"
        case 0x62: return "F7"
        case 0x64: return "F8"
        case 0x65: return "F9"
        case 0x6D: return "F10"
        case 0x67: return "F11"
        case 0x6F: return "F12"
        default: return nil
        }
    }
}