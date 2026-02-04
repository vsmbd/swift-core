//
//  Entity.swift
//  SwiftCore
//
//  Created by vsmbd on 30/01/26.
//

import SwiftCoreNativeCounters

// MARK: - Entity

/// A runtime entity that has a type name and a stable identifier for correlation.
/// Conform to this protocol to represent types that can be checkpointed and traced through code flow.
/// - **Reference types (classes):** Get a default `identifier` from the object pointer (stable per instance, process-local).
/// - **Value types (structs):** Must implement `identifier` yourself; typically store a value from `Self.nextID` at creation.
public protocol Entity: Sendable {
	/// The name of the type (e.g. for logging and correlation). Default implementation returns `String(describing: type(of: self))`.
	var typeName: String { get }
	/// A stable identifier for this entity within the process. Used to correlate checkpoints and events.
	var identifier: UInt64 { get }
}

public extension Entity {
	/// The type name of the conforming type, suitable for diagnostics and correlation keys.
	var typeName: String {
		String(describing: type(of: self))
	}

	/// Returns a fresh entity id from the process-wide counter. Use once when creating a value-type entity (e.g. in `init`) and store the result in `identifier`; do not use as a stable “my id” without storing.
	static var nextID: UInt64 {
		nextEntityID()
	}
}

public extension Entity {
	/// Creates a checkpoint for `self` at the call site, runs the given closure inside a `SyncBlock`, then returns.
	/// - Parameters:
	///   - file: Call site file; defaults to `#fileID`.
	///   - line: Call site line; defaults to `#line`.
	///   - function: Call site function; defaults to `#function`.
	///   - block: Closure to run (non-escaping).
	@discardableResult
	func sync(
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function,
		block: () -> Void
	) -> SyncBlock {
		.init(
			.checkpoint(
				self,
				file: file,
				line: line,
				function: function
			),
			block: block
		)
	}

	/// Creates a checkpoint for `self` at the call site and returns an `AsyncBlock` that runs the given closure when `execute(_:)` is called.
	/// - Parameters:
	///   - file: Call site file; defaults to `#fileID`.
	///   - line: Call site line; defaults to `#line`.
	///   - function: Call site function; defaults to `#function`.
	///   - block: Closure to run when the returned block’s `execute(_:)` is called (escaping).
	/// - Returns: An async block; call `execute(_ checkpoint:)` to run the closure and emit completed.
	func async(
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function,
		block: @escaping @Sendable () -> Void
	) -> AsyncBlock {
		.init(
			.checkpoint(
				self,
				file: file,
				line: line,
				function: function
			),
			block: block
		)
	}
}
