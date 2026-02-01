//
//  ErrorEntity.swift
//  SwiftCore
//
//  Created by vsmbd on 01/02/26.
//

import SwiftCoreNativeCounters

// MARK: - ErrorEntity

/// A constrained protocol for errors that are safe to export in structured form.
/// Conform explicitly to participate in structured reporting; SwiftCore does not capture or serialize arbitrary `Error` values.
/// Higher layers may wrap system errors into domain-specific types that adopt this protocol.
public protocol ErrorEntity: Error,
							 Sendable,
							 Encodable {
	// No required members beyond Error and Encodable.
}

// MARK: - ErrorInfo

/// An envelope tying an `ErrorEntity` to a `Checkpoint`, with optional scalar extras.
/// Identifies where an error occurred and what the error represents; used for observability and correlation.
@frozen
public struct ErrorInfo<E: ErrorEntity>: Sendable,
										 Encodable {
	// MARK: + Private scope

	private enum CodingKeys: String,
							 CodingKey {
		case errorId
		case timestamp
		case checkpoint
		case errorTypeName
		case error
		case extras
	}

	// MARK: + Public scope

	/// Monotonically increasing error id (process-wide, from native counter). Use for correlation and ordering.
	public let errorId: UInt64
	/// Monotonic timestamp when this error info was created. Defaults to `.now` at init.
	public let timestamp: MonotonicNanostamp
	/// The checkpoint where this error was reported
	public let checkpoint: Checkpoint
	/// The error that opted into structured reporting.
	public let error: E
	/// Optional scalar attributes (e.g. codes, counts) for correlation and dashboards.
	public let extras: [String: ScalarValue]?

	/// Creates an error info envelope for the given checkpoint, error, optional extras, and timestamp.
	/// - Parameters:
	///   - error: The structured error (must conform to `ErrorEntity`).
	///   - checkpoint: Where the error was reported (e.g. from `Checkpoint.checkpoint(_:file:line:function:)`).
	///   - extras: Optional key-value scalar attributes.
	///   - timestamp: Monotonic time when this envelope was created; defaults to `.now`.
	public init(
		error: E,
		_ checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now,
		extras: [String: ScalarValue]? = nil
	) {
		self.errorId = SwiftCoreNativeCounters.nextErrorID()
		self.checkpoint = checkpoint
		self.error = error
		self.timestamp = timestamp
		self.extras = extras
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(
			errorId,
			forKey: .errorId
		)
		try container.encode(
			checkpoint,
			forKey: .checkpoint
		)
		try container.encode(
			String(describing: type(of: error)),
			forKey: .errorTypeName
		)
		try error.encode(
			to: container.superEncoder(forKey: .error)
		)
		try container.encode(
			timestamp,
			forKey: .timestamp
		)
		try container.encodeIfPresent(
			extras,
			forKey: .extras
		)
	}
}
