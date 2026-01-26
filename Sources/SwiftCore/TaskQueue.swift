//
//  TaskQueue.swift
//  SwiftCore
//
//  Created by vsmbd on 23/01/26.
//

import Dispatch
import SwiftCoreNativeCounters

// MARK: - TaskQueue

public final class TaskQueue {
	// MARK: + Private scope

	private static let mainQueue: DispatchQueue = .main

	private static let defaultQueue: DispatchQueue = .init(
		label: "swift-core.TaskQueue.default"
	)

	private static let backgroundQueue: DispatchQueue = .init(
		label: "swift-core.TaskQueue.background",
		attributes: .concurrent
	)

	private init() {
		//
	}

	// MARK: + Default scope

	// MARK: + Public scope

	public enum TaskExecutionState: String,
									Sendable,
									Codable {
		case created
		case started
		case completed
	}

	public enum TaskDispatchType: String,
								  Sendable,
								  Codable {
		case sync
		case async
		case syncBarrier
		case asyncBarrier
	}

	public struct TaskInfo: Sendable,
							Hashable,
							Codable {
		public let taskId: UInt64
		public let file: String
		public let line: UInt
		public let function: String

		@inlinable
		public init(
			taskId: UInt64 = nextTaskID(),
			file: StaticString,
			line: UInt,
			function: StaticString
		) {
			self.taskId = taskId
			self.file = String(describing: file)
			self.line = line
			self.function = String(describing: function)
		}
	}

	public struct TaskQueueEvent: Sendable,
								  Codable,
								  Hashable {
		public let queueName: String
		public let taskInfo: TaskInfo
		public let executionState: TaskExecutionState
		public let dispatchType: TaskDispatchType
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

	public typealias TaskQueueEventSink = @Sendable (TaskQueueEvent) -> Void

	nonisolated(unsafe)
	public static private(set) var eventSink: TaskQueueEventSink?

	public static let main: SerialTaskQueue = .init(
		mainQueue,
		name: "main"
	)

	public static let `default`: SerialTaskQueue = .init(
		defaultQueue,
		name: "default"
	)

	public static let background: ConcurrentTaskQueue = .init(
		backgroundQueue,
		name: "background"
	)

	public static func setEventSink(_ sink: @escaping TaskQueueEventSink) {
		guard eventSink == nil else {
			return
		}

		eventSink = sink
	}
}

// MARK: - SerialTaskQueue

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

	public func sync<T>(
		_ task: () throws -> T,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) rethrows -> T {
		let taskInfo = TaskQueue.TaskInfo(
			file: file,
			line: line,
			function: function
		)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .sync
			)
		)

		return try queue.sync(execute: {
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

			return try task()
		})
	}

	public func async(
		_ task: @Sendable @escaping () -> Void,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) {
		let taskInfo = TaskQueue.TaskInfo(
			file: file,
			line: line,
			function: function
		)

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

			task()

			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .completed,
					dispatchType: .async
				)
			)
		})
	}
}

// MARK: - ConcurrentTaskQueue

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

	// MARK: + Public scope¯

	public func sync<T>(
		_ task: () throws -> T,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) rethrows -> T {
		let taskInfo = TaskQueue.TaskInfo(
			file: file,
			line: line,
			function: function
		)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .sync
			)
		)

		return try queue.sync(execute: {
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

			return try task()
		})
	}

	public func async(
		_ task: @Sendable @escaping () -> Void,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) {
		let taskInfo = TaskQueue.TaskInfo(
			file: file,
			line: line,
			function: function
		)

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

			task()

			TaskQueue.eventSink?(
				.init(
					queueName: name,
					taskInfo: taskInfo,
					executionState: .completed,
					dispatchType: .async
				)
			)
		})
	}

	public func syncBarrier<T>(
		_ task: () throws -> T,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) rethrows -> T {
		let taskInfo = TaskQueue.TaskInfo(
			file: file,
			line: line,
			function: function
		)

		TaskQueue.eventSink?(
			.init(
				queueName: name,
				taskInfo: taskInfo,
				executionState: .created,
				dispatchType: .syncBarrier
			)
		)

		return try queue.sync(
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

				return try task()
			}
		)
	}

	public func asyncBarrier(
		_ task: @escaping @Sendable () -> Void,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) {
		let taskInfo = TaskQueue.TaskInfo(
			file: file,
			line: line,
			function: function
		)

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

				task()

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
	}
}
