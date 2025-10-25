#if !os(macOS)
import Foundation

@main
struct ClipboardHistoryUnsupportedPlatformApp {
    static func main() {
        fatalError("ClipboardHistory is only supported on macOS.")
    }
}
#endif
