//
//  Entity.swift
//  SwiftCore
//
//  Created by vsmbd on 30/01/26.
//

import SwiftCoreNativeCounters

// MARK: - Entity

/// A unique identifier for a runtime entity (e.g. a type instance or type itself).
/// Used for correlation and traceability across checkpoints and events.
/// For reference types this is derived from the object pointer; for value types it is typically assigned once at creation via `Entity.nextID`.
public typealias EntityID = UInt64

/// A runtime entity that has a type name and a stable identifier for correlation.
/// Conform to this protocol to represent types that can be checkpointed and traced through code flow.
/// - **Reference types (classes):** Get a default `identifier` from the object pointer (stable per instance, process-local).
/// - **Value types (structs):** Must implement `identifier` yourself; typically store a value from `Self.nextID` at creation.
public protocol Entity: Sendable {
	/// The name of the type (e.g. for logging and correlation). Default implementation returns `String(describing: type(of: self))`.
	var typeName: String { get }
	/// A stable identifier for this entity within the process. Used to correlate checkpoints and events.
	var identifier: EntityID { get }
}

public extension Entity {
	/// The type name of the conforming type, suitable for diagnostics and correlation keys.
	var typeName: String {
		String(describing: type(of: self))
	}

	/// Returns a fresh entity id from the process-wide counter. Use once when creating a value-type entity (e.g. in `init`) and store the result in `identifier`; do not use as a stable “my id” without storing.
	static var nextID: EntityID {
		nextEntityID()
	}
}

public extension Entity where Self: AnyObject {
	/// The object’s identity as an `EntityID` (pointer-derived). Stable for the lifetime of the instance; not stable across process restarts (ASLR).
	var identifier: EntityID {
		UInt64(UInt(bitPattern: ObjectIdentifier(self)))
	}
}
