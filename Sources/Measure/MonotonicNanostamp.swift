//
//  MonotonicNanostamp.swift
//  SwiftCore
//
//  Created by vsmbd on 24/01/26.
//

import NativeTime

@frozen
public struct MonotonicNanostamp: Equatable,
								  Comparable,
								  Hashable,
								  Sendable {
    public let nanoseconds: UInt64

    @inlinable
	public init(nanoseconds: UInt64) {
		self.nanoseconds = nanoseconds
	}

	@inlinable
	public static var now: Self {
		.init(nanoseconds: NativeTime.monotonicNanos())
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
