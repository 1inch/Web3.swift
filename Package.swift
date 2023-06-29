// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "Web3",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(name: "Web3", targets: ["Web3"]),
        .library(name: "Web3ContractABI", targets: ["Web3ContractABI"]),
    ],
    dependencies: [
        // Core dependencies
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.4.1"),
        .package(url: "https://github.com/1inch/secp256k1.swift", from: "0.2.2"),

        // Test dependencies
        .package(url: "https://github.com/Quick/Quick.git", from: "3.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.1.2"),
    ],
    targets: [
        .target(
            name: "Web3",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "secp256k1", package: "secp256k1.swift"),
            ],
            path: "Sources/Core"
        ),
        .target(
            name: "Web3ContractABI",
            dependencies: [
                .target(name: "Web3"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ],
            path: "Sources/ContractABI"
        ),
        .testTarget(
            name: "Web3Tests",
            dependencies: [
                .target(name: "Web3"),
                .target(name: "Web3ContractABI"),
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
            ]
        ),
    ]
)
