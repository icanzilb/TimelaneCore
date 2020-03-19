// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TimelaneCore",
    platforms: [
      .macOS(.v10_10),
      .iOS(.v8),
      .tvOS(.v9),
      .watchOS(.v2)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "TimelaneCore",
            targets: ["TimelaneCore"]),
        .library(
            name: "TimelaneCoreTestUtils",
            targets: ["TimelaneCoreTestUtils"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TimelaneCore",
            dependencies: []),
        .target(
            name: "TimelaneCoreTestUtils",
            dependencies: [],
            path: "Tests/TimelaneCoreTestUtils"),
        .testTarget(
            name: "TimelaneCoreTests",
            dependencies: ["TimelaneCore", "TimelaneCoreTestUtils"]),
    ],
    swiftLanguageVersions: [.v5]
)
