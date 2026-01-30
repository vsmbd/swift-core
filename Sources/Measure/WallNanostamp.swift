//
//  WallNanostamp.swift
//  SwiftCore
//
//  Created by vsmbd on 24/01/26.
//

import NativeTime

/// A wall-clock timestamp in nanoseconds since the Unix epoch (1970-01-01 00:00:00 UTC). Use for human-readable time and cross-process ordering when clocks are synchronized.
/// Subject to system clock adjustments (NTP, manual changes). Encodes/decodes as a nested structure with key `"timestamp"` and inner key `"wall_nanos"`.
@frozen
public struct WallNanostamp: Equatable,
							 Comparable,
							 Hashable,
							 Sendable {
	/// Nanoseconds since the Unix epoch (1970-01-01 00:00:00 UTC).
	public let unixEpochNanoseconds: UInt64

	@inlinable
	public init(unixEpochNanoseconds: UInt64) {
		self.unixEpochNanoseconds = unixEpochNanoseconds
	}

	/// The current wall time (nanoseconds since Unix epoch). Safe to call from any thread.
	@inlinable
	public static var now: Self {
		.init(unixEpochNanoseconds: wallNanos())
	}

	@inlinable
	public static func < (
		leftValue: Self,
		rightValue: Self
	) -> Bool {
		leftValue.unixEpochNanoseconds < rightValue.unixEpochNanoseconds
	}
}

extension WallNanostamp: Codable {
	private enum TopLevelKeys: String,
							   CodingKey {
		case timestamp
	}

	private enum TimestampKeys: String,
								CodingKey {
		case wallNanos = "wall_nanos"
	}

	public init(from decoder: Decoder) throws {
		let topLevelContainer = try decoder
			.container(keyedBy: TopLevelKeys.self)
		let timestampContainer = try topLevelContainer
			.nestedContainer(
				keyedBy: TimestampKeys.self,
				forKey: .timestamp
			)

		let decodedNanoseconds = try timestampContainer
			.decode(
				UInt64.self,
				forKey: .wallNanos
			)
		self.unixEpochNanoseconds = decodedNanoseconds
	}

	public func encode(to encoder: Encoder) throws {
		var topLevelContainer = encoder
			.container(keyedBy: TopLevelKeys.self)
		var timestampContainer = topLevelContainer
			.nestedContainer(
				keyedBy: TimestampKeys.self,
				forKey: .timestamp
			)

		try timestampContainer.encode(
			unixEpochNanoseconds,
			forKey: .wallNanos
		)
	}
}
