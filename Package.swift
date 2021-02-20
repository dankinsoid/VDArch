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
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
        .package(url: "https://github.com/dankinsoid/VDKit.git", from: "1.7.0"),
        .package(url: "https://github.com/dankinsoid/RxOperators.git", from: "2.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "VDArch",
            dependencies: ["VDKit", "RxSwift", "RxOperators"]
				),
				.testTarget(
					name: "VDArchTests",
					dependencies: ["VDArch"],
					path: "Tests"
				)
    ]
)
