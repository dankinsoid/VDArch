# VDArch

## Description

## Example

## Usage

## Installation

1. [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create a `Package.swift` file.
```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "SomeProject",
  dependencies: [
    .package(url: "https://github.com/dankinsoid/VDArch.git", from: "1.0.24")
  ],
  targets: [
    .target(name: "SomeProject", dependencies: ["VDArch"])
  ]
)
```
```ruby
$ swift build
```

## Author

dankinsoid, voidilov@gmail.com

## License

VDArch is available under the MIT license. See the LICENSE file for more info.

