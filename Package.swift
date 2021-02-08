// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VDArch",
    platforms: [
//        .macOS(.v10_13),
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "VDArch",
            targets: ["VDArch"]
				),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.1.1"),
        .package(url: "https://github.com/dankinsoid/VDKit.git", from: "1.0.31"),
        .package(url: "https://github.com/dankinsoid/VDFlow.git", from: "1.0.36"),
        .package(url: "https://github.com/dankinsoid/RxOperators.git", from: "1.0.22")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "VDArch",
            dependencies: ["VDKit", "VDFlow", "RxSwift", "RxOperators"]
				),
				.testTarget(
					name: "VDArchTests",
					dependencies: ["VDArch"],
					path: "Tests"
				)
    ]
)
