//
//  TaskQueue.swift
//  SwiftCore
//
//  Created by vsmbd on 23/01/26.
//

import Dispatch
import SwiftCoreNativeCounters

// MARK: - TaskQueue

/// Namespace and configuration for execution queues. Provides serial (main, default) and concurrent (background) queues; each task is tied to a `Checkpoint` and optionally reported via `setEventSink(_:)`.
public final class TaskQueue {
	// MARK: + Private scope

	nonisolated(unsafe)
	fileprivate static var eventSink: TaskQueueEventSink?

	private static let mainQueue: DispatchQueue = .main

	private static let defaultQueue: DispatchQueue = .init(
		label: "swift-core.TaskQueue.default",
		qos: .default
	)

	private static let backgroundQueue: DispatchQueue = .init(
		label: "swift-core.TaskQueue.background",
		qos: .background,
		attributes: .concurrent
	)

	private init() {
		//
	}

	// MARK: + Default scope

	// MARK: + Public scope

	/// Lifecycle state of a task as reported to the event sink.
	public enum TaskExecutionState: String,
									Sendable,
									Codable {
		/// Task was enqueued (created).
		case created
		/// Task began executing.
		case started
		/// Task finished executing.
		case completed
	}

	/// How the task was dispatched (sync/async, with or without barrier).
	public enum TaskDispatchType: String,
								  Sendable,
								  Codable {
		case sync
		case async
		case syncBarrier
		case asyncBarrier
	}

	/// Identity and context for a single task: a unique task id and the checkpoint at which it was enqueued.
	public struct TaskInfo: Sendable,
							Hashable,
							Encodable {
		/// Keys for use in `extra` or attribute bags (e.g. `TaskInfo.Key.taskId`).
		public enum Key {
			/// Key for the task id when embedding in dictionaries.
			public static let taskId = "task_id"
		}

		/// Monotonically increasing task id (process-wide, from native counter).
		public let taskId: UInt64
		/// The checkpoint at which this task was enqueued (entity + file/line/function).
		public let checkpoint: Checkpoint

		@inlinable
		init(_ checkpoint: Checkpoint) {
			self.taskId = nextTaskID()
			self.checkpoint = checkpoint
		}
	}

	/// A single task lifecycle event: queue name, task info, state, dispatch type, and monotonic timestamp. Emitted to the event sink at created/started/completed.
	public struct TaskQueueEvent: Sendable,
								  Encodable,
								  Hashable {
		/// Name of the queue (e.g. `"main"`, `"default"`, `"background"`).
		public let queueName: String
		/// The task’s id and checkpoint.
		public let taskInfo: TaskInfo
		/// Whether the task was created, started, or completed.
		public let executionState: TaskExecutionState
		/// How the task was dispatched (sync, async, syncBarrier, asyncBarrier).
		public let dispatchType: TaskDispatchType
		/// Monotonic timestamp when the event was emitted.
		public let timestamp: MonotonicNanostamp

		init(
			queueName: String,
			taskInfo: TaskInfo,
			executionState: TaskExecutionState,
			dispatchType: TaskDispatchType,
			timestamp: MonotonicNanostamp = .now
		) {
			self.queueName = queueName
			self.taskInfo = taskInfo
			self.executionState = executionState
			self.dispatchType = dispatchType
			self.timestamp = timestamp
		}
	}

	/// Closure type for the task queue event sink. Receives `TaskQueueEvent` for every created/started/completed transition; must be thread-safe.
	public typealias TaskQueueEventSink = @Sendable (TaskQueueEvent) -> Void

	/// The main (serial) queue. Use for UI or main-thread work.
	public static let main: SerialTaskQueue = .init(
		mainQueue,
		name: "main"
	)

	/// The default (serial) queue. Use for general off-main work.
	public static let `default`: SerialTaskQueue = .init(
		defaultQueue,
		name: "default"
	)

	/// The background (concurrent) queue. Use for parallel work; supports barrier for exclusive phases.
	public static let background: ConcurrentTaskQueue = .init(
		backgroundQueue,
		name: "background"
	)

	/// Registers the global task queue event sink. Call once at startup; subsequent calls are ignored. The sink receives events for every task created/started/completed.
	public static func setEventSink(_ sink: @escaping TaskQueueEventSink) {
		guard eventSink == nil else {
			return
		}

		eventSink = sink
	}
}

// MARK: - SerialTaskQueue

/// A serial (FIFO) task queue. Tasks run one at a time; each task is tied to a checkpoint and optionally reported via the global event sink.
@frozen
public struct SerialTaskQueue: Sendable {
	// MARK: + Private scope

	private let queue: DispatchQueue
	private let name: String

	fileprivate init(
		_ queue: DispatchQueue,
		name: String
	) {
		self.queue = queue
		self.name = name
	}

	// MARK: + Public scope

	/// Result of a synchronous task: the returned value and the task’s `TaskInfo`.
	public typealias SyncResult<T> = (
		value: T,
		taskInfo: TaskQueue.TaskInfo
	)

	/// Runs the task synchronously on this queue. Emits created/started/completed events to the sink. Blocks until the task completes.
	/// - Parameters:
	///   - checkpoint: Checkpoint (entity + call site) for this task.
	///   - task: The work to run; receives the task’s `TaskInfo`.
	/// - Returns: A tuple of the task’s return value and its `TaskInfo`.
	public func sync<T>(
		_ checkpoint: Checkpoint,
		_ task: (TaskQueue.TaskInfo) throws -> T
	) rethrows -> SyncResult<T> {
		let taskInfo = TaskQueue.TaskInfo(checkpoint)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .sync
			)
		)

		let result = try queue.sync(execute: {
			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .started,
					dispatchType: .sync
				)
			)

			defer {
				TaskQueue.eventSink?(
					.init(
						queueName: name,
						taskInfo: taskInfo,
						executionState: .completed,
						dispatchType: .sync
					)
				)
			}

			return try task(taskInfo)
		})

		return (result, taskInfo)
	}

	/// Enqueues the task asynchronously on this queue. Emits created/started/completed events to the sink. Returns immediately with the task’s `TaskInfo`.
	/// - Parameters:
	///   - checkpoint: Checkpoint (entity + call site) for this task.
	///   - task: The work to run; receives the task’s `TaskInfo`.
	/// - Returns: The task’s `TaskInfo` (task id and checkpoint).
	@discardableResult
	public func async(
		_ checkpoint: Checkpoint,
		_ task: @Sendable @escaping (TaskQueue.TaskInfo) -> Void
	) -> TaskQueue.TaskInfo {
		let taskInfo = TaskQueue.TaskInfo(checkpoint)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .async
			)
		)

		queue.async(execute: {
			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .started,
					dispatchType: .async
				)
			)

			task(taskInfo)

			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .completed,
					dispatchType: .async
				)
			)
		})

		return taskInfo
	}
}

// MARK: - ConcurrentTaskQueue

/// A concurrent task queue. Multiple tasks can run in parallel; barrier sync/async provide exclusive phases. Each task is tied to a checkpoint and optionally reported via the global event sink.
@frozen
public struct ConcurrentTaskQueue: Sendable {
	// MARK: + Private scope

	private let queue: DispatchQueue
	private let name: String

	fileprivate init(
		_ queue: DispatchQueue,
		name: String
	) {
		self.queue = queue
		self.name = name
	}

	// MARK: + Public scope

	/// Result of a synchronous task: the returned value and the task’s `TaskInfo`.
	public typealias SyncResult<T> = (
		value: T,
		taskInfo: TaskQueue.TaskInfo
	)

	/// Runs the task synchronously on this queue. Emits created/started/completed events. Blocks until the task completes.
	public func sync<T>(
		_ checkpoint: Checkpoint,
		_ task: (TaskQueue.TaskInfo) throws -> T
	) rethrows -> SyncResult<T> {
		let taskInfo = TaskQueue.TaskInfo(checkpoint)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .sync
			)
		)

		let result = try queue.sync(execute: {
			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .started,
					dispatchType: .sync
				)
			)

			defer {
				TaskQueue.eventSink?(
					.init(
						queueName: name,
						taskInfo: taskInfo,
						executionState: .completed,
						dispatchType: .sync
					)
				)
			}

			return try task(taskInfo)
		})

		return (result, taskInfo)
	}

	/// Enqueues the task asynchronously. Emits created/started/completed events. Returns immediately with the task’s `TaskInfo`.
	@discardableResult
	public func async(
		_ checkpoint: Checkpoint,
		_ task: @Sendable @escaping (TaskQueue.TaskInfo) -> Void
	) -> TaskQueue.TaskInfo {
		let taskInfo = TaskQueue.TaskInfo(checkpoint)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .async
			)
		)

		queue.async(execute: {
			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .started,
					dispatchType: .async
				)
			)

			task(taskInfo)

			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .completed,
					dispatchType: .async
				)
			)
		})

		return taskInfo
	}

	/// Runs the task synchronously with a barrier: no other work runs until this task completes. Use for exclusive updates. Emits created/started/completed with `syncBarrier` dispatch type.
	public func syncBarrier<T>(
		_ checkpoint: Checkpoint,
		_ task: (TaskQueue.TaskInfo) throws -> T
	) rethrows -> SyncResult<T> {
		let taskInfo = TaskQueue.TaskInfo(checkpoint)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .syncBarrier
			)
		)

		let result = try queue.sync(
			flags: .barrier,
			execute: {
				TaskQueue.eventSink?(
					.init(
						queueName: name,
						taskInfo: taskInfo,
						executionState: .started,
						dispatchType: .syncBarrier
					)
				)

				defer {
					TaskQueue.eventSink?(
						.init(
							queueName: name,
							taskInfo: taskInfo,
							executionState: .completed,
							dispatchType: .syncBarrier
						)
					)
				}

				return try task(taskInfo)
			}
		)

		return (result, taskInfo)
	}

	/// Enqueues the task asynchronously with a barrier: no other work runs until this task completes. Use for exclusive updates. Emits created/started/completed with `asyncBarrier` dispatch type.
	@discardableResult
	public func asyncBarrier(
		_ checkpoint: Checkpoint,
		_ task: @escaping @Sendable (TaskQueue.TaskInfo) -> Void
	) -> TaskQueue.TaskInfo {
		let taskInfo = TaskQueue.TaskInfo(checkpoint)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .asyncBarrier
			)
		)

		queue.async(
			flags: .barrier,
			execute: {
				TaskQueue.eventSink?(
					.init(
						queueName: name,
						taskInfo: taskInfo,
						executionState: .started,
						dispatchType: .asyncBarrier
					)
				)

				task(taskInfo)

				TaskQueue.eventSink?(
					.init(
						queueName: name,
						taskInfo: taskInfo,
						executionState: .completed,
						dispatchType: .asyncBarrier
					)
				)
			}
		)

		return taskInfo
	}
}
