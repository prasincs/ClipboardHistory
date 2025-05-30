import SwiftUI
import HotKey

@main
struct ClipboardHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager.shared
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Clipboard History") {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var hotKey: HotKey?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusBar()
        setupPopover()
        setupHotKey()
        setupMenu()
        
        ClipboardManager.shared.startMonitoring()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotKeyChanged),
            name: .hotKeyChanged,
            object: nil
        )
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Try to load custom icon, fallback to SF Symbol
            if let customIcon = NSImage(named: "MenuBarIcon") {
                customIcon.isTemplate = true
                button.image = customIcon
            } else {
                button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
            }
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    func setupMenu() {
        // Don't set menu here, we'll create it on demand
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Clipboard History", action: #selector(showPopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        return menu
    }
    
    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ClipboardHistoryView())
    }
    
    func setupHotKey() {
        let settings = Settings.shared
        
        guard settings.hotKeyCode != 0,
              let key = keyCodeToKey(settings.hotKeyCode) else {
            return
        }
        
        var modifiers: NSEvent.ModifierFlags = []
        if settings.hotKeyModifiers.contains(.control) { modifiers.insert(.control) }
        if settings.hotKeyModifiers.contains(.option) { modifiers.insert(.option) }
        if settings.hotKeyModifiers.contains(.shift) { modifiers.insert(.shift) }
        if settings.hotKeyModifiers.contains(.command) { modifiers.insert(.command) }
        
        hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.showPopover()
        }
    }
    
    @objc func hotKeyChanged() {
        hotKey = nil
        setupHotKey()
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            // Close popover if it's open
            if popover.isShown {
                popover.performClose(nil)
            }
            
            // Show menu
            let menu = createMenu()
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            
            // Remove menu after showing to allow left-click to work
            DispatchQueue.main.async { [weak self] in
                self?.statusItem.menu = nil
            }
        } else {
            togglePopover()
        }
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }
    
    @objc func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.center()
            settingsWindow?.title = "Settings"
            settingsWindow?.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func keyCodeToKey(_ keyCode: UInt16) -> Key? {
        switch keyCode {
        case 0x00: return .a
        case 0x01: return .s
        case 0x02: return .d
        case 0x03: return .f
        case 0x04: return .h
        case 0x05: return .g
        case 0x06: return .z
        case 0x07: return .x
        case 0x08: return .c
        case 0x09: return .v
        case 0x0B: return .b
        case 0x0C: return .q
        case 0x0D: return .w
        case 0x0E: return .e
        case 0x0F: return .r
        case 0x10: return .y
        case 0x11: return .t
        case 0x12: return .one
        case 0x13: return .two
        case 0x14: return .three
        case 0x15: return .four
        case 0x16: return .six
        case 0x17: return .five
        case 0x18: return .equal
        case 0x19: return .nine
        case 0x1A: return .seven
        case 0x1B: return .minus
        case 0x1C: return .eight
        case 0x1D: return .zero
        case 0x1E: return .rightBracket
        case 0x1F: return .o
        case 0x20: return .u
        case 0x21: return .leftBracket
        case 0x22: return .i
        case 0x23: return .p
        case 0x25: return .l
        case 0x26: return .j
        case 0x27: return .quote
        case 0x28: return .k
        case 0x29: return .semicolon
        case 0x2A: return .backslash
        case 0x2B: return .comma
        case 0x2C: return .slash
        case 0x2D: return .n
        case 0x2E: return .m
        case 0x2F: return .period
        case 0x32: return .grave
        case 0x24: return .return
        case 0x30: return .tab
        case 0x31: return .space
        case 0x33: return .delete
        case 0x35: return .escape
        case 0x7A: return .f1
        case 0x78: return .f2
        case 0x63: return .f3
        case 0x76: return .f4
        case 0x60: return .f5
        case 0x61: return .f6
        case 0x62: return .f7
        case 0x64: return .f8
        case 0x65: return .f9
        case 0x6D: return .f10
        case 0x67: return .f11
        case 0x6F: return .f12
        default: return nil
        }
    }
}