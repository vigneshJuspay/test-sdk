// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "PeekKit",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "PeekKit", targets: ["PeekKit"])
    ],
    targets: [
        .target(
            name: "PeekKit",
            path: "PeekKit",
            exclude: ["Assets", "Classes/.gitkeep"],
            sources: ["Classes"],
            resources: [.copy("Resources/PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "PeekKitTests",
            dependencies: ["PeekKit"],
            path: "Example/Tests",
            exclude: ["Info.plist"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
