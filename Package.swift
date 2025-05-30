// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardHistory",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClipboardHistory",
            targets: ["ClipboardHistory"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "ClipboardHistory",
            dependencies: ["HotKey"],
            path: ".",
            sources: [
                "ClipboardHistoryApp.swift",
                "ClipboardManager.swift",
                "ClipboardHistoryView.swift",
                "Settings.swift",
                "SettingsView.swift",
                "HotKeyRecorderView.swift"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "ClipboardHistoryTests",
            dependencies: ["ClipboardHistory"],
            path: "Tests"
        )
    ]
)