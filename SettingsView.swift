#if os(macOS)
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var newAppName = ""
    @State private var showingPasteConfigSheet = false
    @State private var editingPasteBehavior: AppPasteBehavior?
    
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
                    
                    Toggle("Show clipboard at cursor (Experimental)", isOn: $settings.showAtCursor)
                        .onChange(of: settings.showAtCursor) { _ in
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
            
            GroupBox(label: Label("App-Specific Paste Behaviors", systemImage: "keyboard.badge.ellipsis")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configure special paste behaviors for specific apps and websites")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(settings.appPasteBehaviors, id: \.appIdentifier) { behavior in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(behavior.appName)
                                            .font(.headline)
                                        if let urlPattern = behavior.urlPattern {
                                            Text("URL: \(urlPattern)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(behavior.behavior.description)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Button(action: {
                                        if let index = settings.appPasteBehaviors.firstIndex(where: { $0.appIdentifier == behavior.appIdentifier }) {
                                            settings.appPasteBehaviors.remove(at: index)
                                            settings.saveSettings()
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    
                    Button(action: {
                        showingPasteConfigSheet = true
                    }) {
                        Label("Add App Behavior", systemImage: "plus.circle")
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
                    
                    #if DEBUG
                    Divider()
                    
                    Button("Reset First Launch") {
                        UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
                        showingAlert = true
                        alertMessage = "First launch flag has been reset. Restart the app to see the welcome message."
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                    #endif
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
        .frame(width: 450, height: 700)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingPasteConfigSheet) {
            AppPasteBehaviorSheet(isPresented: $showingPasteConfigSheet)
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

struct AppPasteBehaviorSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var settings = Settings.shared
    
    @State private var selectedApp = ""
    @State private var selectedBundleId = ""
    @State private var urlPattern = ""
    @State private var selectedBehavior: PasteBehavior = .normal
    @State private var requiresURL = false
    
    let commonApps = [
        ("Google Chrome", "com.google.Chrome"),
        ("Safari", "com.apple.Safari"),
        ("Firefox", "org.mozilla.firefox"),
        ("Microsoft Edge", "com.microsoft.edgemac"),
        ("Arc", "company.thebrowser.Browser")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add App-Specific Paste Behavior")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Application:")
                    .font(.subheadline)
                
                Picker("Application", selection: $selectedApp) {
                    Text("Select an app...").tag("")
                    ForEach(commonApps, id: \.0) { app in
                        Text(app.0).tag(app.0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedApp) { newValue in
                    if let app = commonApps.first(where: { $0.0 == newValue }) {
                        selectedBundleId = app.1
                    }
                }
                
                if !selectedApp.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Require specific URL pattern", isOn: $requiresURL)
                        
                        if requiresURL {
                            TextField("URL pattern (e.g., docs.google.com)", text: $urlPattern)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .help("Enter a URL pattern that must match for this behavior to apply")
                        }
                        
                        Text("Paste Behavior:")
                            .font(.subheadline)
                        
                        Picker("Behavior", selection: $selectedBehavior) {
                            ForEach(PasteBehavior.allCases, id: \.self) { behavior in
                                Text(behavior.description).tag(behavior)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        
                        if selectedBehavior == .googleDocsLink {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("This will paste URLs and then press Cmd+K to create a link in Google Docs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Only applies to content starting with http:// or https://")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Add") {
                    addBehavior()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedApp.isEmpty || (requiresURL && urlPattern.isEmpty))
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
    
    private func addBehavior() {
        let behavior = AppPasteBehavior(
            appIdentifier: selectedBundleId,
            appName: selectedApp,
            urlPattern: requiresURL ? urlPattern : nil,
            behavior: selectedBehavior
        )

        // Remove any existing behavior for this app
        settings.appPasteBehaviors.removeAll { $0.appIdentifier == selectedBundleId }

        // Add the new behavior
        settings.appPasteBehaviors.append(behavior)
        settings.saveSettings()

        isPresented = false
    }
}
#endif
