//
//  AsyncBlock.swift
//  SwiftCore
//
//  Created by vsmbd on 04/02/26.
//

import SwiftCoreNativeCounters

// MARK: - AsyncBlockEvent

/// Event emitted to the async block event sink when an async block is started or completed.
/// Set a sink with `AsyncBlock.setEventSink(_:)`; the sink is responsible for thread-safe ingestion.
public enum AsyncBlockEvent: Sendable,
							 Encodable {
	/// An async block was started. block: the block; checkpoint: at start; timestamp: monotonic (default `.now`).
	case started(
		block: AsyncBlock,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now
	)
	/// An async block was completed. block: the block; checkpoint: at completion; timestamp: monotonic (default `.now`).
	case completed(
		block: AsyncBlock,
		checkpoint: Checkpoint,
		timestamp: MonotonicNanostamp = .now
	)
}

// MARK: - AsyncBlock

/// An asynchronous block: started at init; call `execute(_:)` to run the stored closure and emit completed.
public struct AsyncBlock: Sendable {
	// MARK: + Private scope

	private let block: @Sendable () -> Void

	nonisolated(unsafe)
	private static var eventSink: (@Sendable (AsyncBlockEvent) -> Void)?

	// MARK: + Public scope

	/// Monotonically increasing block id (process-wide, from native counter).
	public let blockId: UInt64
	/// Checkpoint at block start (captured in init).
	public let startCheckpoint: Checkpoint

	/// Creates an async block: emits `.started` and stores `block` (escaping) for later execution.
	/// - Parameters:
	///   - checkpoint: Checkpoint at block start (unlabeled).
	///   - block: Trailing closure to run when `execute(_:)` is called (escaping, stored privately).
	public init(
		_ checkpoint: Checkpoint,
		block: @escaping @Sendable () -> Void
	) {
		self.blockId = nextBlockID()
		self.startCheckpoint = checkpoint
		self.block = block
		Self.eventSink?(
			.started(
				block: self,
				checkpoint: checkpoint
			)
		)
	}

	/// Closure type for the async block event sink. Receives `AsyncBlockEvent`; must be thread-safe.
	public typealias EventSink = @Sendable (AsyncBlockEvent) -> Void

	/// Registers the async block event sink. Call once at startup; subsequent calls are ignored.
	public static func setEventSink(_ sink: @escaping EventSink) {
		guard eventSink == nil else {
			return
		}

		eventSink = sink
	}

	/// Executes the stored block, then emits `.completed(block: self, checkpoint:)` to the sink if set.
	/// - Parameter checkpoint: Checkpoint at completion (unlabeled).
	public func execute(_ checkpoint: Checkpoint) {
		block()
		Self.eventSink?(
			.completed(
				block: self,
				checkpoint: checkpoint
			)
		)
	}
}

// MARK: - AsyncBlock + Encodable

extension AsyncBlock: Encodable {
	// MARK: + Private scope

	private enum CodingKeys: String,
							 CodingKey {
		case blockId
		case startCheckpoint
	}

	// MARK: + Public scope

	public func encode(to encoder: Encoder) throws {
		var container = encoder
			.container(keyedBy: CodingKeys.self)

		try container.encode(
			blockId,
			forKey: .blockId
		)
		try container.encode(
			startCheckpoint,
			forKey: .startCheckpoint
		)
	}
}
