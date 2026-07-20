// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImouTap2Click",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "ImouTap2Click", targets: ["ImouTap2Click"])],
    targets: [
        .systemLibrary(name: "MultitouchSupport"),
        .executableTarget(
            name: "ImouTap2Click",
            dependencies: ["MultitouchSupport"],
            resources: [.process("Resources")],
            linkerSettings: [.unsafeFlags(["-F/System/Library/PrivateFrameworks", "-framework", "MultitouchSupport"])]
        )
    ]
)
