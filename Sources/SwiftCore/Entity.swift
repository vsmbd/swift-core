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
	/// Creates a checkpoint for `self` at the call site, runs the given closure inside a `MeasuredBlock`, then returns. Does not throw when `block` is non-throwing.
	/// - Parameters:
	///   - file: Call site file; defaults to `#fileID`.
	///   - line: Call site line; defaults to `#line`.
	///   - function: Call site function; defaults to `#function`.
	///   - block: Closure to run (non-escaping).
	@discardableResult
	func measured<T>(
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function,
		block: @escaping @Sendable () -> T
	) -> T {
		let checkpoint = Checkpoint.checkpoint(
			self,
			file: file,
			line: line,
			function: function
		)
		let syncBlock = MeasuredBlock(
			checkpoint,
			block: block
		)
		return try! syncBlock.execute(checkpoint)
	}

	/// Creates a checkpoint for `self` at the call site, runs the given closure inside a `MeasuredBlock`, then returns. Throws when `block` throws.
	/// - Parameters:
	///   - file: Call site file; defaults to `#fileID`.
	///   - line: Call site line; defaults to `#line`.
	///   - function: Call site function; defaults to `#function`.
	///   - block: Closure to run (non-escaping); may throw.
	@discardableResult
	func measured<T>(
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function,
		block: @escaping @Sendable () throws -> T
	) throws -> T {
		let checkpoint = Checkpoint.checkpoint(
			self,
			file: file,
			line: line,
			function: function
		)
		let syncBlock = MeasuredBlock(
			checkpoint,
			block: block
		)
		return try syncBlock.execute(checkpoint)
	}
}
