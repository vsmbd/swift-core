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
	func measuredRunsClosure() {
		let entity = TestEntity()
		nonisolated(unsafe) var ran = false

		entity.measured {
			ran = true
		}

		#expect(ran)
	}
}
