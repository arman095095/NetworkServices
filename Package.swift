// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let remoteDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "8.10.0"),
    .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0")
]

private let localDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "8.10.0"),
    .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0")
]

let isDev = true
private let dependencies = isDev ? localDependencies : remoteDependencies

let package = Package(
    name: "NetworkServices",
    platforms: [
            .iOS(.v13),
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NetworkServices",
            targets: ["NetworkServices"]),
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "NetworkServices",
            dependencies: [.product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                           .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                           .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                           .product(name: "Swinject", package: "Swinject")])
    ]
)
