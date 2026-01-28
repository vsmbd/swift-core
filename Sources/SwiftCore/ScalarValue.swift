//
//  ScalarValue.swift
//  SwiftCore
//
//  Created by vsmbd on 27/01/26.
//

import Foundation

// MARK: - ScalarValue

/// Scalar-only value type for structured data.
/// Limited to scalar types to preserve Codable and Sendable compliance.
@frozen
public enum ScalarValue: Equatable,
						 Codable,
						 Sendable,
						 Hashable {
	case string(String)
	case bool(Bool)
	case int64(Int64)
	case uint64(UInt64)
	case double(Double)
	case float(Float)

	private enum CodingKeys: String,
							 CodingKey,
							 CaseIterable {
		case string
		case bool
		case int64
		case uint64
		case double
		case float
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Validate that exactly one key is present
		var foundKey: CodingKeys?
		for key in CodingKeys.allCases {
			if container.contains(key) {
				if foundKey != nil {
					throw DecodingError.dataCorrupted(
						DecodingError.Context(
							codingPath: decoder.codingPath,
							debugDescription: "ScalarValue must contain exactly one scalar type key"
						)
					)
				}
				foundKey = key
			}
		}

		guard let key = foundKey else {
			throw DecodingError.keyNotFound(
				CodingKeys.string,
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "ScalarValue must contain exactly one scalar type key"
				)
			)
		}

		// Decode based on the found key
		switch key {
		case .string:
			self = .string(try container.decode(
				String.self,
				forKey: .string
			))

		case .bool:
			self = .bool(try container.decode(
				Bool.self,
				forKey: .bool
			))

		case .int64:
			self = .int64(try container.decode(
				Int64.self,
				forKey: .int64
			))

		case .uint64:
			self = .uint64(try container.decode(
				UInt64.self,
				forKey: .uint64
			))

		case .double:
			self = .double(try container.decode(
				Double.self,
				forKey: .double
			))

		case .float:
			self = .float(try container.decode(
				Float.self,
				forKey: .float
			))
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .string(value):
			try container.encode(
				value,
				forKey: .string
			)

		case let .bool(value):
			try container.encode(
				value,
				forKey: .bool
			)

		case let .int64(value):
			try container.encode(
				value,
				forKey: .int64
			)

		case let .uint64(value):
			try container.encode(
				value,
				forKey: .uint64
			)

		case let .double(value):
			try container.encode(
				value,
				forKey: .double
			)

		case let .float(value):
			try container.encode(
				value,
				forKey: .float
			)
		}
	}
}
