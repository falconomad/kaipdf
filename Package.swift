// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiPDF",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KaiPDF", targets: ["KaiPDFApp"])
    ],
    targets: [
        .executableTarget(
            name: "KaiPDFApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
