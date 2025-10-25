#if os(macOS)
import SwiftUI
import AppKit

struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var modifiers: NSEvent.ModifierFlags
    @Binding var keyCode: UInt16
    let onRecorded: () -> Void
    
    func makeNSView(context: Context) -> HotKeyRecorderNSView {
        let view = HotKeyRecorderNSView()
        view.delegate = context.coordinator
        view.updateDisplay(modifiers: modifiers, keyCode: keyCode)
        return view
    }
    
    func updateNSView(_ nsView: HotKeyRecorderNSView, context: Context) {
        nsView.updateDisplay(modifiers: modifiers, keyCode: keyCode)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, HotKeyRecorderDelegate {
        let parent: HotKeyRecorderView
        
        init(_ parent: HotKeyRecorderView) {
            self.parent = parent
        }
        
        func hotKeyRecorded(modifiers: NSEvent.ModifierFlags, keyCode: UInt16) {
            parent.modifiers = modifiers
            parent.keyCode = keyCode
            parent.onRecorded()
        }
    }
}

protocol HotKeyRecorderDelegate: AnyObject {
    func hotKeyRecorded(modifiers: NSEvent.ModifierFlags, keyCode: UInt16)
}

class HotKeyRecorderNSView: NSView {
    weak var delegate: HotKeyRecorderDelegate?
    private var isRecording = false
    private var currentModifiers: NSEvent.ModifierFlags = []
    private var currentKeyCode: UInt16 = 0
    
    private let textField: NSTextField = {
        let field = NSTextField()
        field.isEditable = false
        field.isSelectable = false
        field.isBordered = true
        field.bezelStyle = .roundedBezel
        field.alignment = .center
        field.font = .systemFont(ofSize: 14)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let clearButton: NSButton = {
        let button = NSButton()
        button.bezelStyle = .rounded
        button.title = "Clear"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(textField)
        addSubview(clearButton)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        clearButton.target = self
        clearButton.action = #selector(clearHotKey)
    }
    
    func updateDisplay(modifiers: NSEvent.ModifierFlags, keyCode: UInt16) {
        currentModifiers = modifiers
        currentKeyCode = keyCode
        textField.stringValue = Settings.shared.getHotKeyString()
    }
    
    @objc private func clearHotKey() {
        currentModifiers = []
        currentKeyCode = 0
        textField.stringValue = "Click to record shortcut"
        delegate?.hotKeyRecorded(modifiers: [], keyCode: 0)
    }
    
    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            isRecording = true
            textField.stringValue = "Press your shortcut..."
            textField.textColor = .systemBlue
            window?.makeFirstResponder(self)
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        let modifiers = event.modifierFlags.intersection([.control, .option, .shift, .command])
        
        if !modifiers.isEmpty && event.keyCode != 0 {
            currentModifiers = modifiers
            currentKeyCode = event.keyCode
            isRecording = false
            textField.textColor = .labelColor
            updateDisplay(modifiers: modifiers, keyCode: event.keyCode)
            delegate?.hotKeyRecorded(modifiers: modifiers, keyCode: event.keyCode)
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }
        
        let modifiers = event.modifierFlags.intersection([.control, .option, .shift, .command])
        var modifierString = ""
        
        if modifiers.contains(.control) { modifierString += "⌃" }
        if modifiers.contains(.option) { modifierString += "⌥" }
        if modifiers.contains(.shift) { modifierString += "⇧" }
        if modifiers.contains(.command) { modifierString += "⌘" }
        
        textField.stringValue = modifierString.isEmpty ? "Press your shortcut..." : modifierString
    }
}
#endif
