// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LifeManagerLib",
            targets: ["LifeManagerLib"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "LifeManagerLib",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LifeManagerTests",
            dependencies: ["LifeManagerLib"],
            path: "Tests"
        ),
    ]
) 