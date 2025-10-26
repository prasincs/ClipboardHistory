#if !os(macOS)
import Foundation

@main
struct ClipboardHistoryUnsupportedPlatformApp {
    static func main() {
        fatalError("ClipboardHistory's SwiftUI interface is only available on macOS. On Linux, run the clipboard-history-linux daemon from the linux/ directory.")
    }
}
#endif
