import AppKit
import Carbon

/// Represents a combination of a keyboard key and modifier flags that can be registered
/// as a global hot key.
public struct KeyCombo: Equatable {
    public var key: Key
    public var modifiers: NSEvent.ModifierFlags

    public init(key: Key, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = modifiers.intersection([.command, .option, .control, .shift])
    }

    var carbonKeyCode: UInt32 { key.carbonKeyCode }
    var carbonModifiers: UInt32 { modifiers.carbonFlags }
}

extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var result: UInt32 = 0

        if contains(.command) { result |= UInt32(cmdKey) }
        if contains(.option) { result |= UInt32(optionKey) }
        if contains(.control) { result |= UInt32(controlKey) }
        if contains(.shift) { result |= UInt32(shiftKey) }

        return result
    }
}
