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
			dependencies: ["Measure", "NativeTaskID"],
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
			name: "NativeTaskID",
			path: "Sources/NativeTaskID",
			publicHeadersPath: "include"
		),
		.testTarget(
			name: "SwiftCoreTests",
			dependencies: ["SwiftCore"],
			path: "Tests/SwiftCoreTests"
		),
	]
)
