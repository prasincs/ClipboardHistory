#if os(macOS)
import AppKit
import Carbon

/// Lightweight reimplementation of the core bits of the original HotKey library so we can
/// build and test the project in environments without network access. Only the functionality
/// required by ClipboardHistory is provided.
public final class HotKey {
    public typealias Handler = () -> Void

    public var keyDownHandler: Handler?
    public var keyUpHandler: Handler?

    public var keyCombo: KeyCombo? {
        didSet {
            guard keyCombo != oldValue else { return }
            registerHotKey()
        }
    }

    private var hotKeyRef: EventHotKeyRef?
    private let identifier: UInt32

    public init(keyCombo: KeyCombo) {
        self.identifier = HotKey.nextIdentifier()
        self.keyCombo = keyCombo
        HotKey.register(self, id: identifier)
        HotKey.installEventHandler()
        registerHotKey()
    }

    public convenience init(key: Key, modifiers: NSEvent.ModifierFlags) {
        self.init(keyCombo: KeyCombo(key: key, modifiers: modifiers))
    }

    deinit {
        unregisterHotKey()
        HotKey.unregister(identifier: identifier)
    }

    // MARK: - Registration

    private func registerHotKey() {
        unregisterHotKey()

        guard let keyCombo = keyCombo else { return }

        let hotKeyID = EventHotKeyID(signature: HotKey.signature, id: identifier)
        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCombo.carbonKeyCode,
                                         keyCombo.carbonModifiers,
                                         hotKeyID,
                                         GetEventDispatcherTarget(),
                                         0,
                                         &newRef)

        if status == noErr {
            hotKeyRef = newRef
        }
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}

// MARK: - Shared global state

private extension HotKey {
    static let signature: OSType = 0x484B4559 // 'HKEY'

    private static var nextID: UInt32 = 1
    private static var registeredHotKeys: [UInt32: HotKey] = [:]
    private static var eventHandler: EventHandlerRef?

    static func nextIdentifier() -> UInt32 {
        defer { nextID &+= 1 }
        return nextID
    }

    static func register(_ hotKey: HotKey, id: UInt32) {
        registeredHotKeys[id] = hotKey
    }

    static func unregister(identifier: UInt32) {
        registeredHotKeys.removeValue(forKey: identifier)
        if registeredHotKeys.isEmpty, let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    static func installEventHandler() {
        guard eventHandler == nil else { return }

        var eventTypes = [
            EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]

        let count = UInt32(eventTypes.count)

        eventTypes.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            InstallEventHandler(GetEventDispatcherTarget(),
                                hotKeyEventCallback,
                                count,
                                baseAddress,
                                nil,
                                &eventHandler)
        }
    }

    static func handle(event eventRef: EventRef?) -> OSStatus {
        guard let eventRef = eventRef else { return noErr }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(eventRef,
                                       EventParamName(kEventParamDirectObject),
                                       EventParamType(typeEventHotKeyID),
                                       nil,
                                       MemoryLayout<EventHotKeyID>.size,
                                       nil,
                                       &hotKeyID)

        guard status == noErr else { return status }
        guard let hotKey = registeredHotKeys[hotKeyID.id] else { return noErr }

        let eventKind = GetEventKind(eventRef)
        switch eventKind {
        case UInt32(kEventHotKeyPressed):
            hotKey.keyDownHandler?()
        case UInt32(kEventHotKeyReleased):
            hotKey.keyUpHandler?()
        default:
            break
        }

        return noErr
    }
}

private let hotKeyEventCallback: EventHandlerUPP = { _, eventRef, _ in
    HotKey.handle(event: eventRef)
}
#endif
