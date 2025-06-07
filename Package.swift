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
        // Pin to exact version to prevent supply chain attacks
        .package(url: "https://github.com/soffes/HotKey", exact: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "ClipboardHistory",
            dependencies: ["HotKey"],
            path: ".",
            exclude: [
                "LICENSE",
                "Makefile",
                "Info.plist",
                "SECURITY.md",
                "scripts",
                "CONTRIBUTING.md",
                "README.md",
                "create_icon.py",
                "create_icon_simple.py",
                "create_menubar_icon.py",
                "build.sh",
                "release.sh",
                "notarize.sh",
                "CHANGELOG.md",
                "CLAUDE.md",
                "ClipboardHistory.app",
                ".github",
                ".gitleaks.toml",
                "Package.resolved",
                "AppIcon.svg",
                "MenuBarIcon.svg",
                "AppIcon.iconset"
            ],
            sources: [
                "ClipboardHistoryApp.swift",
                "ClipboardManager.swift",
                "ClipboardHistoryView.swift",
                "Settings.swift",
                "SettingsView.swift",
                "HotKeyRecorderView.swift"
            ],
            resources: [
                .process("Assets.xcassets"),
                .copy("AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "ClipboardHistoryTests",
            dependencies: ["ClipboardHistory"],
            path: "Tests"
        )
    ]
)