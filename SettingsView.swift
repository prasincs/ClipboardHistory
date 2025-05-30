import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 10)
            
            GroupBox(label: Label("Keyboard Shortcut", systemImage: "keyboard")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Global shortcut to show clipboard history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HotKeyRecorderView(
                        modifiers: $settings.hotKeyModifiers,
                        keyCode: $settings.hotKeyCode,
                        onRecorded: {
                            settings.saveSettings()
                            NotificationCenter.default.post(
                                name: .hotKeyChanged,
                                object: nil
                            )
                        }
                    )
                    .frame(height: 30)
                }
                .padding(.vertical, 8)
            }
            
            GroupBox(label: Label("Clipboard History", systemImage: "doc.on.clipboard")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Maximum items to store:")
                        Spacer()
                        Text("50")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Button(action: {
                        ClipboardManager.shared.clearHistory()
                        showingAlert = true
                        alertMessage = "Clipboard history has been cleared"
                    }) {
                        Label("Clear History", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
            
            GroupBox(label: Label("About", systemImage: "info.circle")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Clipboard History")
                        .font(.headline)
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("A simple clipboard manager for macOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Done") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 450, height: 500)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

extension Notification.Name {
    static let hotKeyChanged = Notification.Name("hotKeyChanged")
}