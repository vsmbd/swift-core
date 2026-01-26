// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftCore",
	products: [
		.library(
			name: "SwiftCore",
			targets: ["SwiftCore"]
		)
	],
	targets: [
		.target(
			name: "SwiftCore",
			dependencies: ["Measure", "SwiftCoreNativeCounters"],
			path: "Sources/SwiftCore"
		),
		.target(
			name: "Measure",
			dependencies: ["NativeTime"],
			path: "Sources/Measure"
		),
		.target(
			name: "NativeTime",
			path: "Sources/NativeTime",
			publicHeadersPath: "include"
		),
		.target(
			name: "SwiftCoreNativeCounters",
			path: "Sources/SwiftCoreNativeCounters",
			publicHeadersPath: "include"
		),
		.testTarget(
			name: "SwiftCoreTests",
			dependencies: ["SwiftCore"],
			path: "Tests/SwiftCoreTests"
		),
	]
)
