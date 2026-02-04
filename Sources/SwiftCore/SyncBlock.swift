//
//  SyncBlock.swift
//  SwiftCore
//
//  Created by vsmbd on 04/02/26.
//

import SwiftCoreNativeCounters

// MARK: - SyncBlockEvent

/// Event emitted to the sync block event sink when a sync block is started or completed.
/// Set a sink with `SyncBlock.setEventSink(_:)`; the sink is responsible for thread-safe ingestion.
public enum SyncBlockEvent: Sendable,
							Encodable {
	/// A sync block was started. block: the block; checkpoint: at start; timestamp: monotonic (default `.now`).
	case started(
		block: SyncBlock,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now
	)
	/// A sync block was completed. block: the block; checkpoint: at completion (for sync, typically the same as start); timestamp: monotonic (default `.now`).
	case completed(
		block: SyncBlock,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now
	)
}

// MARK: - SyncBlock

/// A synchronous block: at init, emits start, runs the trailing closure, then emits completed.
public struct SyncBlock: Sendable,
						 Encodable {
	// MARK: + Private scope

	nonisolated(unsafe)
	private static var eventSink: (@Sendable (SyncBlockEvent) -> Void)?

	// MARK: + Public scope

	/// Monotonically increasing block id (process-wide, from native counter).
	public let blockId: UInt64
	/// Checkpoint at block start (captured in init).
	public let startCheckpoint: Checkpoint

	/// Creates a sync block: emits `.started`, executes `block()`, emits `.completed` (with the same checkpoint), then returns.
	/// - Parameters:
	///   - checkpoint: Checkpoint at block start (unlabeled).
	///   - block: Trailing closure to run (non-escaping).
	@discardableResult
	public init(
		_ checkpoint: Checkpoint,
		block: () -> Void
	) {
		self.blockId = nextBlockID()
		self.startCheckpoint = checkpoint
		Self.eventSink?(
			.started(
				block: self,
				checkpoint: checkpoint
			)
		)
		block()
		Self.eventSink?(
			.completed(
				block: self,
				checkpoint: checkpoint
			)
		)
	}

	/// Closure type for the sync block event sink. Receives `SyncBlockEvent`; must be thread-safe.
	public typealias EventSink = @Sendable (SyncBlockEvent) -> Void

	/// Registers the sync block event sink. Call once at startup; subsequent calls are ignored.
	public static func setEventSink(_ sink: @escaping EventSink) {
		guard eventSink == nil else {
			return
		}

		eventSink = sink
	}
}
