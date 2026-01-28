//
//  TaskQueueTests.swift
//  SwiftCoreTests
//
//  Created by vsmbd on 24/01/26.
//

import Dispatch
import Foundation
import Testing
import SwiftCore

@Suite("TaskQueue")
struct TaskQueueTests {
	@Test
	func serialQueuePreservesOrder() {
		let queue = TaskQueue.default
		nonisolated(unsafe) var events: [Int] = []
		let group = DispatchGroup()

		for value in 0..<5 {
			group.enter()
			queue.async { _ in
				events.append(value)
				group.leave()
			}
		}

		#expect(group.wait(timeout: .now() + 2) == .success)
		#expect(events == [0, 1, 2, 3, 4])
	}

	@Test
	func backgroundBarrierSeparatesWork() {
		let queue = TaskQueue.background
		let group = DispatchGroup()
		let lock = NSLock()
		nonisolated(unsafe) var events: [String] = []

		@Sendable
		func record(_ value: String) {
			lock.lock()
			events.append(value)
			lock.unlock()
		}

		for index in 0..<5 {
			group.enter()
			queue.async { _ in
				record("pre\(index)")
				group.leave()
			}
		}

		group.enter()
		queue.asyncBarrier { _ in
			record("barrier")
			group.leave()
		}

		for index in 0..<5 {
			group.enter()
			queue.async { _ in
				record("post\(index)")
				group.leave()
			}
		}

		#expect(group.wait(timeout: .now() + 2) == .success)

		guard let barrierIndex = events.firstIndex(of: "barrier") else {
			#expect(Bool(false))
			return
		}

		let preIndices = events.enumerated()
			.filter { $0.element.hasPrefix("pre") }
			.map(\.offset)
		let postIndices = events.enumerated()
			.filter { $0.element.hasPrefix("post") }
			.map(\.offset)

		#expect(preIndices.allSatisfy { $0 < barrierIndex })
		#expect(postIndices.allSatisfy { $0 > barrierIndex })
	}
}
