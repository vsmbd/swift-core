//
//  WallNanostampTests.swift
//  SwiftCoreTests
//
//  Created by vsmbd on 24/01/26.
//

import Foundation
import Testing

import SwiftCore

@Suite("WallNanostamp")
struct WallNanostampTests {
	@Test
	func comparableAndHashable() {
		let first = WallNanostamp(unixEpochNanoseconds: 10)
		let second = WallNanostamp(unixEpochNanoseconds: 20)

		#expect(first < second)
		#expect(second > first)
		#expect(first == WallNanostamp(unixEpochNanoseconds: 10))

		var set: Set<WallNanostamp> = []
		set.insert(first)
		set.insert(second)
		set.insert(WallNanostamp(unixEpochNanoseconds: 10))

		#expect(set.count == 2)
	}

	@Test
	func codableRoundTrip() throws {
		let stamp = WallNanostamp(unixEpochNanoseconds: 84)
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()

		let data = try encoder.encode(stamp)
		let decoded = try decoder.decode(WallNanostamp.self, from: data)

		#expect(decoded == stamp)

		let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		let value = object?["wall_nanos"] as? NSNumber

		#expect(value?.uint64Value == 84)
	}
}
