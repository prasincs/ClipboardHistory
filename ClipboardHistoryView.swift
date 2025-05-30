import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    
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
            SearchBar(text: $searchText)
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
                                selectAndPaste(item)
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
        }
    }
    
    private func selectAndPaste(_ item: ClipboardItem) {
        clipboardManager.pasteItem(item)
        NSApplication.shared.keyWindow?.close()
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.keyCode == 36 {
                if let firstItem = filteredItems.first {
                    selectAndPaste(firstItem)
                }
                return nil
            }
            
            if event.keyCode >= 18 && event.keyCode <= 26 {
                let number = Int(event.keyCode - 17)
                if number > 0 && number <= filteredItems.count {
                    selectAndPaste(filteredItems[number - 1])
                    return nil
                }
            }
            
            return event
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search clipboard history...", text: $text)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
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
                    Text(item.preview)
                        .lineLimit(2)
                        .font(.system(.body, design: .default))
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
                
                Text(RelativeDateTimeFormatter().localizedString(for: item.timestamp, relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
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