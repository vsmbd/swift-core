//
//  MonotonicNanostamp.swift
//  SwiftCore
//
//  Created by vsmbd on 24/01/26.
//

import NativeTime

/// A monotonic timestamp in nanoseconds. Increases over time and is not affected by system clock changes (e.g. NTP, sleep). Use for measuring elapsed time and ordering events within a process.
/// Origin is platform-defined (e.g. boot); do not use as wall time. Encodes/decodes as a nested structure with key `"timestamp"` and inner key `"monotonic_nanos"`.
@frozen
public struct MonotonicNanostamp: Equatable,
								  Comparable,
								  Hashable,
								  Sendable {
	/// Nanoseconds since the monotonic clock origin (e.g. boot).
	public let nanoseconds: UInt64

	@inlinable
	public init(nanoseconds: UInt64) {
		self.nanoseconds = nanoseconds
	}

	/// The current monotonic time (nanoseconds). Safe to call from any thread.
	@inlinable
	public static var now: Self {
		.init(nanoseconds: monotonicNanos())
	}

	@inlinable
	public static func < (
		leftValue: Self,
		rightValue: Self
	) -> Bool {
		leftValue.nanoseconds < rightValue.nanoseconds
	}
}

extension MonotonicNanostamp: Codable {
	private enum TopLevelKeys: String,
							   CodingKey {
		case timestamp
	}

	private enum TimestampKeys: String,
								CodingKey {
		case monotonicNanos = "monotonic_nanos"
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
				forKey: .monotonicNanos
			)
		self.nanoseconds = decodedNanoseconds
	}

	public func encode(to encoder: Encoder) throws {
		var topLevelContainer = encoder.container(keyedBy: TopLevelKeys.self)
		var timestampContainer = topLevelContainer
			.nestedContainer(
				keyedBy: TimestampKeys.self,
				forKey: .timestamp
			)

		try timestampContainer.encode(
			nanoseconds,
			forKey: .monotonicNanos
		)
	}
}
