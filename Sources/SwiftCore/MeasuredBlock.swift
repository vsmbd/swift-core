//
//  MeasuredBlock.swift
//  SwiftCore
//
//  Created by vsmbd on 04/02/26.
//

import SwiftCoreNativeCounters

// MARK: - MeasuredBlockEvent

/// Event emitted to the sync block event sink when a sync block is started or completed.
/// Set a sink with `MeasuredBlock.setEventSink(_:)`; the sink is responsible for thread-safe ingestion.
public enum MeasuredBlockEvent: Sendable {
	case created(
		blockId: UInt64,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now
	)
	case started(
		blockId: UInt64,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now
	)
	case completed(
		blockId: UInt64,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now
	)
}

// MARK: - MeasuredBlock

nonisolated(unsafe)
fileprivate var eventSink: (@Sendable (MeasuredBlockEvent) -> Void)?

/// A synchronous block: at init, emits start, runs the trailing closure, then emits completed.
public struct MeasuredBlock<T>: Sendable {
	// MARK: + Private scope

	private let block: @Sendable () throws -> T

	// MARK: + Public scope

	/// Monotonically increasing block id (process-wide, from native counter).
	public let blockId: UInt64
	/// Checkpoint at
	public let createdCheckpoint: Checkpoint

	/// Creates a sync block: emits `.started`, executes `block()`, emits `.completed` (with the same checkpoint), then returns.
	/// - Parameters:
	///   - checkpoint: Checkpoint at block start .
	///   - block: Trailing closure to run (non-escaping).
	@discardableResult
	public init(
		_ checkpoint: Checkpoint,
		block: @escaping @Sendable () throws -> T
	) {
		self.blockId = nextBlockID()
		self.createdCheckpoint = checkpoint
		self.block = block

		eventSink?(
			.created(
				blockId: blockId,
				checkpoint: checkpoint
			)
		)
	}

	/// Closure type for the sync block event sink. Receives `MeasuredBlockEvent`; must be thread-safe.
	public typealias EventSink = @Sendable (MeasuredBlockEvent) -> Void

	/// Registers the sync block event sink. Call once at startup; subsequent calls are ignored.
	public static func setEventSink(_ sink: @escaping EventSink) {
		guard eventSink == nil else {
			return
		}

		eventSink = sink
	}

	/// Executes the stored block, then emits `.completed(block: self, checkpoint:)` to the sink if set.
	/// Completed is always emitted, even when the block throws (via defer).
	/// - Parameter checkpoint: Checkpoint at completion .
	public func execute(_ checkpoint: Checkpoint) throws -> T {
		eventSink?(
			.started(
				blockId: blockId,
				checkpoint: checkpoint
			)
		)

		defer {
			eventSink?(
				.completed(
					blockId: blockId,
					checkpoint: checkpoint
				)
			)
		}

		return try block()
	}
}
