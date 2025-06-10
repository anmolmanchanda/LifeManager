// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LifeManager",
            targets: ["LifeManager"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "LifeManager",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources/LifeManager"
        ),
        .testTarget(
            name: "LifeManagerTests",
            dependencies: ["LifeManager"],
            path: "Tests/LifeManagerTests"
        ),
    ]
) 