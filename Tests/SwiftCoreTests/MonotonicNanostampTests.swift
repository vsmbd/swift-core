//
//  MonotonicNanostampTests.swift
//  SwiftCoreTests
//
//  Created by vsmbd on 24/01/26.
//

import Foundation
import Testing

import SwiftCore

@Suite("MonotonicNanostamp")
struct MonotonicNanostampTests {
	@Test
	func comparableAndHashable() {
		let first = MonotonicNanostamp(nanoseconds: 1)
		let second = MonotonicNanostamp(nanoseconds: 2)

		#expect(first < second)
		#expect(second > first)
		#expect(first == MonotonicNanostamp(nanoseconds: 1))

		var set: Set<MonotonicNanostamp> = []
		set.insert(first)
		set.insert(second)
		set.insert(MonotonicNanostamp(nanoseconds: 1))

		#expect(set.count == 2)
	}

	@Test
	func codableRoundTrip() throws {
		let stamp = MonotonicNanostamp(nanoseconds: 42)
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()

		let data = try encoder.encode(stamp)
		let decoded = try decoder.decode(MonotonicNanostamp.self, from: data)

		#expect(decoded == stamp)

		let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		let value = object?["monotonic_nanos"] as? NSNumber

		#expect(value?.uint64Value == 42)
	}
}
