// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = [
    .library(
        name: "ClipboardCore",
        targets: ["ClipboardCore"]
    ),
    .executable(
        name: "ClipboardHistory",
        targets: ["ClipboardHistory"]
    )
]

var targets: [Target] = [
    .target(
        name: "ClipboardCore",
        path: "Sources/ClipboardCore"
    ),
    .target(
        name: "HotKey",
        path: "Sources/HotKey",
        linkerSettings: [
            .linkedFramework("Carbon", .when(platforms: [.macOS]))
        ]
    ),
    .executableTarget(
        name: "ClipboardHistory",
        dependencies: [
            .target(name: "HotKey", condition: .when(platforms: [.macOS])),
            "ClipboardCore",
        ],
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
            "CHANGELOG.md",
            ".github",
            ".gitleaks.toml",
            "Package.resolved",
            "AppIcon.svg",
            "MenuBarIcon.svg",
            "Sources",
            "Tests"
        ],
        sources: [
            "ClipboardHistoryApp.swift",
            "ClipboardManager.swift",
            "ClipboardHistoryView.swift",
            "Settings.swift",
            "SettingsView.swift",
            "HotKeyRecorderView.swift",
            "ClipboardHistoryUnsupportedMain.swift"
        ],
        resources: [
            .process("Assets.xcassets"),
            .copy("AppIcon.icns")
        ]
    )
]

var testTargets: [Target] = [
    .testTarget(
        name: "ClipboardCoreTests",
        dependencies: ["ClipboardCore"],
        path: "Tests/ClipboardCoreTests"
    )
]

#if os(macOS)
testTargets.append(
    .testTarget(
        name: "ClipboardHistoryTests",
        dependencies: ["ClipboardHistory"],
        path: "Tests/ClipboardHistoryTests"
    )
)
#endif

let package = Package(
    name: "ClipboardHistory",
    platforms: [
        .macOS(.v13)
    ],
    products: products,
    dependencies: [],
    targets: targets + testTargets
)
