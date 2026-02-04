//
//  TimeBaseline.swift
//  SwiftCore
//
//  Created by vsmbd on 03/02/26.
//

import NativeTime

// MARK: - TimeBaseline

/// Wall and monotonic timestamps captured together so both refer to the same instant.
///
/// Use for session baselines when converting event monotonic time to wall time:
/// `event_wall_nanos = baseline.wall.unixEpochNanoseconds + (event_mono_nanos - baseline.monotonic.nanoseconds)`.
/// The native layer captures wall first, then monotonic, to minimize the delay between samples.
///
/// Obtain the process-wide baseline from `timeBaseline` (captured at first access).
@frozen
public struct TimeBaseline: Sendable,
							Codable {
	// MARK: + Private scope

	fileprivate init(
		wall: WallNanostamp,
		monotonic: MonotonicNanostamp
	) {
		self.wall = wall
		self.monotonic = monotonic
	}

	// MARK: + Public scope

	/// Wall-clock time (Unix epoch nanoseconds UTC) at capture.
	public let wall: WallNanostamp

	/// Monotonic time (nanoseconds since boot) at capture.
	public let monotonic: MonotonicNanostamp

	/// Converts a monotonic timestamp to wall-clock time (Unix epoch UTC).
	/// Use when the stamp is from the same process as this baseline; its nanoseconds must be ≥ `self.monotonic.nanoseconds` to avoid underflow.
	@inlinable
	public func wallNanostamp(for monotonicNanostamp: MonotonicNanostamp) -> WallNanostamp {
		let elapsedNanos = monotonicNanostamp.nanoseconds &- monotonic.nanoseconds
		let wallNanos = wall.unixEpochNanoseconds &+ elapsedNanos
		return .init(unixEpochNanoseconds: wallNanos)
	}
}

/// Process-wide baseline (wall + monotonic) captured at first access.
/// Safe to read from any thread. Use for converting event monotonic timestamps to wall time.
public let timeBaseline: TimeBaseline = {
	var raw = NativeTimeBaseline(
		wallNanos: 0,
		monotonicNanos: 0
	)
	nativeTimeBaseline(&raw)
	return .init(
		wall: .init(unixEpochNanoseconds: raw.wallNanos),
		monotonic: .init(nanoseconds: raw.monotonicNanos)
	)
}()
