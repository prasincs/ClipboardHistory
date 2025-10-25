#if os(macOS)
import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    @State private var stickyMode = false
    @State private var isPasting = false
    let appDelegate: AppDelegate?
    
    init(appDelegate: AppDelegate? = nil) {
        self.appDelegate = appDelegate
        print("ClipboardHistoryView init with appDelegate: \(appDelegate != nil ? "Present" : "Nil")")
    }
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardHistory
        } else {
            return clipboardManager.clipboardHistory.filter { item in
                item.preview.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, stickyMode: stickyMode)
                .padding()
            
            Divider()
            
            if filteredItems.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardItemRow(
                                item: item,
                                index: index + 1,
                                isSelected: selectedItemId == item.id
                            )
                            .onTapGesture {
                                print("Tap gesture recognized for item: \(item.preview)")
                                selectAndPaste(item, keepOpen: stickyMode)
                            }
                            .onHover { isHovered in
                                if isHovered {
                                    selectedItemId = item.id
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Divider()
            
            HStack {
                Text("\(clipboardManager.clipboardHistory.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if stickyMode {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Sticky Mode")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if isPasting {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Pasting...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Button("Clear All") {
                    clipboardManager.clearHistory()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 500)
        .onAppear {
            setupKeyboardShortcuts()
            // Auto-select first item when popup appears
            if selectedItemId == nil {
                selectedItemId = filteredItems.first?.id
            }
        }
        .onChange(of: searchText) { _ in
            // Ensure selection stays valid when search changes
            if let selectedId = selectedItemId, !filteredItems.contains(where: { $0.id == selectedId }) {
                selectedItemId = filteredItems.first?.id
            }
        }
    }
    
    private func selectAndPaste(_ item: ClipboardItem, keepOpen: Bool = false) {
        // Prevent rapid-fire pasting to avoid overwrites
        guard !isPasting else {
            print("Already pasting, ignoring request")
            return
        }
        
        isPasting = true
        print("selectAndPaste called for item: \(item.preview), keepOpen: \(keepOpen)")
        
        // Try to get appDelegate from passed reference or from NSApp
        let appDel = appDelegate ?? (NSApp.delegate as? AppDelegate)
        
        // Check if appDelegate is nil
        guard let appDelegate = appDel else {
            print("ERROR: Could not get appDelegate!")
            // Still try to paste even without appDelegate
            clipboardManager.pasteItem(item, directPaste: keepOpen)
            isPasting = false
            return
        }
        
        // Get the target app before potentially closing popover
        let targetApp = appDelegate.targetApplication
        print("Target app: \(targetApp?.localizedName ?? "None")")
        
        // Only close the popover if not in sticky mode
        if !keepOpen {
            appDelegate.closePopover()
        }
        
        // Paste to the target application with proper timing for sticky mode
        let pasteDelay: Double = keepOpen ? 0.5 : 0.2 // Longer delay in sticky mode
        DispatchQueue.main.asyncAfter(deadline: .now() + pasteDelay) {
            if let app = targetApp, app.bundleIdentifier != Bundle.main.bundleIdentifier {
                // Activate the target app
                print("Activating target app: \(app.localizedName ?? "Unknown")")
                app.activate(options: [.activateIgnoringOtherApps])
                
                // Wait for app to become active
                let activationDelay: Double = keepOpen ? 0.5 : 0.3
                DispatchQueue.main.asyncAfter(deadline: .now() + activationDelay) {
                    self.clipboardManager.pasteItem(item, targetApp: app, directPaste: keepOpen)
                    
                    // Reset pasting flag and bring focus back if needed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isPasting = false
                        if keepOpen {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                appDelegate.bringPopoverToFront()
                            }
                        }
                    }
                }
            } else {
                // Direct paste if no target app
                print("No target app, performing direct paste")
                self.clipboardManager.pasteItem(item, directPaste: keepOpen)
                
                // Reset pasting flag and bring focus back if needed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isPasting = false
                    if keepOpen {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            appDelegate.bringPopoverToFront()
                        }
                    }
                }
            }
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Handle Space key for sticky mode toggle
            if event.keyCode == Settings.shared.stickyModeKey {
                self.stickyMode.toggle()
                self.appDelegate?.setStickyMode(self.stickyMode)
                return nil
            }
            
            // Handle Enter key
            if event.keyCode == 36 { // Return key
                if let selectedId = self.selectedItemId,
                   let selectedItem = self.filteredItems.first(where: { $0.id == selectedId }) {
                    self.selectAndPaste(selectedItem, keepOpen: self.stickyMode)
                } else if let firstItem = self.filteredItems.first {
                    self.selectAndPaste(firstItem, keepOpen: self.stickyMode)
                }
                return nil
            }
            
            // Handle arrow keys for navigation
            if event.keyCode == 125 { // Down arrow
                self.navigateDown()
                return nil
            }
            
            if event.keyCode == 126 { // Up arrow
                self.navigateUp()
                return nil
            }
            
            // Handle number keys 1-9 for quick selection
            if event.keyCode >= 18 && event.keyCode <= 26 {
                let number = Int(event.keyCode - 17)
                if number > 0 && number <= self.filteredItems.count {
                    self.selectAndPaste(self.filteredItems[number - 1], keepOpen: self.stickyMode)
                    return nil
                }
            }
            
            // Handle Escape key to close
            if event.keyCode == 53 { // Escape key
                self.appDelegate?.closePopover()
                return nil
            }
            
            return event
        }
    }
    
    private func navigateDown() {
        if filteredItems.isEmpty { return }
        
        if let currentSelectedId = selectedItemId,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentSelectedId }) {
            let nextIndex = min(currentIndex + 1, filteredItems.count - 1)
            selectedItemId = filteredItems[nextIndex].id
        } else {
            selectedItemId = filteredItems.first?.id
        }
    }
    
    private func navigateUp() {
        if filteredItems.isEmpty { return }
        
        if let currentSelectedId = selectedItemId,
           let currentIndex = filteredItems.firstIndex(where: { $0.id == currentSelectedId }) {
            let previousIndex = max(currentIndex - 1, 0)
            selectedItemId = filteredItems[previousIndex].id
        } else {
            selectedItemId = filteredItems.first?.id
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let stickyMode: Bool
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search clipboard history...", text: $text)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .disabled(stickyMode) // Disable search in sticky mode to prevent focus stealing
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onTapGesture {
            if !stickyMode {
                isSearchFocused = true
            }
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                switch item.content {
                case .text:
                    HStack(spacing: 8) {
                        if item.isPassword {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        Text(item.preview)
                            .lineLimit(2)
                            .font(.system(.body, design: .default))
                    }
                case .image(let image):
                    HStack {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 40)
                        
                        Text("Image")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    if let sourceApp = item.sourceApp {
                        Label(sourceApp, systemImage: "app")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(RelativeDateTimeFormatter().localizedString(for: item.timestamp, relativeTo: Date()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        .overlay(
            isSelected ? RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor, lineWidth: 2) : nil
        )
        .cornerRadius(6)
        .contentShape(Rectangle())
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No clipboard history")
                .font(.headline)
            
            Text("Copy something to start building your history")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
