//
//  TaskQueue.swift
//  SwiftCore
//
//  Created by vsmbd on 23/01/26.
//

import Dispatch

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

	public static let main: SerialTaskQueue = .init(mainQueue)

	public static let `default`: SerialTaskQueue = .init(defaultQueue)

	public static let background: ConcurrentTaskQueue = .init(backgroundQueue)
}

// MARK: - SerialTaskQueue

@frozen
public struct SerialTaskQueue: Sendable {
	// MARK: + Private scope

	private let queue: DispatchQueue

	fileprivate init(_ queue: DispatchQueue) {
		self.queue = queue
	}

	// MARK: + Public scope

	public func sync<T>(_ task: () throws -> T) rethrows -> T {
		try queue.sync(execute: task)
	}

	public func async(_ task: @Sendable @escaping () -> Void) {
		queue.async(execute: task)
	}
}

// MARK: - ConcurrentTaskQueue

@frozen
public struct ConcurrentTaskQueue: Sendable {
	// MARK: + Private scope

	private let queue: DispatchQueue

	fileprivate init(_ queue: DispatchQueue) {
		self.queue = queue
	}

	// MARK: + Public scope

	public func sync<T>(_ task: () throws -> T) rethrows -> T {
		try queue.sync(execute: task)
	}

	public func async(_ task: @Sendable @escaping () -> Void) {
		queue.async(execute: task)
	}

	public func syncBarrier<T>(_ task: () throws -> T) rethrows -> T {
		try queue.sync(
			flags: .barrier,
			execute: task
		)
	}

	public func asyncBarrier(_ task: @escaping @Sendable () -> Void) {
		queue.async(
			flags: .barrier,
			execute: task
		)
	}
}
