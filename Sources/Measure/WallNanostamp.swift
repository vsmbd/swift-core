//
//  WallNanostamp.swift
//  SwiftCore
//
//  Created by vsmbd on 24/01/26.
//

import NativeTime

@frozen
public struct WallNanostamp: Equatable,
							 Comparable,
							 Hashable,
							 Sendable {
    public let unixEpochNanoseconds: UInt64

    @inlinable
    public init(unixEpochNanoseconds: UInt64) {
        self.unixEpochNanoseconds = unixEpochNanoseconds
    }

    @inlinable
	public static var now: Self {
		.init(unixEpochNanoseconds: NativeTime.wallNanos())
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
