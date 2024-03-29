// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "VDArch",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "VDArch",
            targets: ["VDArch"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/dankinsoid/CombineOperators.git", from: "2.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.43.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "VDArch",
            dependencies: [
                "CombineOperators",
                .product(name: "CombineCocoa", package: "CombineOperators"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
