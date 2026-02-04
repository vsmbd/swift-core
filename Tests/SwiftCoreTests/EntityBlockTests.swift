//
//  EntityBlockTests.swift
//  SwiftCoreTests
//
//  Created by vsmbd on 04/02/26.
//

import SwiftCore
import Testing

private struct TestEntity: Entity {
	let identifier: UInt64

	init() {
		self.identifier = Self.nextID
	}
}

@Suite("Entity sync and async block")
struct EntityBlockTests {
	@Test
	func syncRunsClosure() {
		let entity = TestEntity()
		nonisolated(unsafe) var ran = false

		entity.sync {
			ran = true
		}

		#expect(ran)
	}

	@Test
	func asyncRunsClosureWhenExecuted() {
		let entity = TestEntity()
		nonisolated(unsafe) var ran = false

		let block = entity.async {
			ran = true
		}

		#expect(!ran)

		let completionCheckpoint = Checkpoint.checkpoint(entity)
		block.execute(completionCheckpoint)

		#expect(ran)
	}
}
