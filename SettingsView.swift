import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var newAppName = ""
    
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
            
            GroupBox(label: Label("Privacy & Security", systemImage: "lock.shield")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Mask passwords in clipboard history", isOn: $settings.maskPasswords)
                        .onChange(of: settings.maskPasswords) { _ in
                            settings.saveSettings()
                        }
                    
                    Text("Excluded Applications")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text("Content from these apps will be masked:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(settings.excludedApps).sorted(), id: \.self) { app in
                                HStack {
                                    Image(systemName: "app.fill")
                                        .foregroundColor(.secondary)
                                    Text(app)
                                    Spacer()
                                    Button(action: {
                                        settings.excludedApps.remove(app)
                                        settings.saveSettings()
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    
                    HStack {
                        TextField("Add app name...", text: $newAppName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addExcludedApp()
                            }
                        
                        Button(action: addExcludedApp) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newAppName.isEmpty)
                    }
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
        .frame(width: 450, height: 600)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func addExcludedApp() {
        let trimmedName = newAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            settings.excludedApps.insert(trimmedName)
            settings.saveSettings()
            newAppName = ""
        }
    }
}

extension Notification.Name {
    static let hotKeyChanged = Notification.Name("hotKeyChanged")
}