//
//  Checkpoint.swift
//  SwiftCore
//
//  Created by vsmbd on 30/01/26.
//

// MARK: - CheckpointEvent

/// Event emitted to the checkpoint sink when checkpoints are created or correlated.
/// Set a sink with `Checkpoint.setEventSink(_:)`; the sink is responsible for thread-safe ingestion (e.g. graph storage, export).
public enum CheckpointEvent: Sendable {
	/// A checkpoint was created via `Checkpoint.at(_:file:line:function:)`. The associated value is the new checkpoint.
	case created(Checkpoint)
	/// A checkpoint-to-checkpoint correlation was recorded via `Checkpoint.next(_:file:line:function:)`. The edge is from the calling checkpoint to the returned one.
	case correlated(
		from: Checkpoint,
		to: Checkpoint
	)
}

// MARK: - Checkpoint

/// A point in code flow: an entity identity plus file, line, and function at capture.
/// Use `Checkpoint.at(_:file:line:function:)` to create a checkpoint for an entity at the current call site; use `next(_:file:line:function:)` to record a successor checkpoint and emit a correlation event.
public struct Checkpoint: Sendable {
	// MARK: + Private scope

	nonisolated(unsafe)
	private static var eventSink: (@Sendable (CheckpointEvent) -> Void)?

	private init(
		typeName: String,
		entityId: UInt64,
		file: StaticString,
		line: UInt,
		function: StaticString
	) {
		self.typeName = typeName
		self.entityId = entityId
		self.file = file
		self.line = line
		self.function = function

		Self.eventSink?(.created(self))
	}

	// MARK: + Public scope

	/// The type name of the entity at this checkpoint.
	public let typeName: String
	/// The entity identifier at this checkpoint.
	public let entityId: UInt64
	/// The file (e.g. module/file path) where the checkpoint was captured. Defaults to `#fileID`.
	public let file: StaticString
	/// The line number where the checkpoint was captured. Defaults to `#line`.
	public let line: UInt
	/// The function name where the checkpoint was captured. Defaults to `#function`.
	public let function: StaticString

	/// Closure type for the checkpoint event sink. Receives `CheckpointEvent` values; must be thread-safe.
	public typealias EventSink = @Sendable (CheckpointEvent) -> Void

	/// Registers the global checkpoint event sink. Call once at startup; subsequent calls are ignored. The sink receives `.created` and `.correlated` events and is responsible for thread-safe ingestion.
	public static func setEventSink(_ sink: @escaping EventSink) {
		guard eventSink == nil else {
			return
		}
		eventSink = sink
	}

	/// Creates a checkpoint for the given entity at the current call site. Emits `.created(checkpoint)` to the sink if set.
	/// - Parameters:
	///   - entity: The entity (e.g. `self` when conforming to `Entity`) to associate with this checkpoint.
	///   - file: Call site file; defaults to `#fileID`.
	///   - line: Call site line; defaults to `#line`.
	///   - function: Call site function; defaults to `#function`.
	/// - Returns: The new checkpoint.
	public static func at(
		_ entity: Entity,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) -> Checkpoint {
		.init(
			typeName: entity.typeName,
			entityId: entity.identifier,
			file: file,
			line: line,
			function: function
		)
	}

	/// Creates a successor checkpoint for the given entity at the current call site and emits `.correlated(from: self, to: next)` to the sink if set.
	/// Use this to record a flow edge from this checkpoint to the next (e.g. state transitions, call chains).
	/// - Parameters:
	///   - entity: The entity to associate with the successor checkpoint.
	///   - file: Call site file; defaults to `#fileID`.
	///   - line: Call site line; defaults to `#line`.
	///   - function: Call site function; defaults to `#function`.
	/// - Returns: The new checkpoint (successor).
	public func next(
		_ entity: Entity,
		file: StaticString = #fileID,
		line: UInt = #line,
		function: StaticString = #function
	) -> Checkpoint {
		let next = Self(
			typeName: entity.typeName,
			entityId: entity.identifier,
			file: file,
			line: line,
			function: function
		)

		Self.eventSink?(.correlated(
			from: self,
			to: next
		))

		return next
	}
}

// MARK: - Checkpoint + Equatable

extension Checkpoint: Equatable {
	public static func == (
		lhs: Checkpoint,
		rhs: Checkpoint
	) -> Bool {
		lhs.typeName == rhs.typeName
		&& lhs.entityId == rhs.entityId
		&& String(describing: lhs.file) == String(describing: rhs.file)
		&& lhs.line == rhs.line
		&& String(describing: lhs.function) == String(describing: rhs.function)
	}
}

// MARK: - Checkpoint + Hashable

extension Checkpoint: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(typeName)
		hasher.combine(entityId)
		hasher.combine(String(describing: file))
		hasher.combine(line)
		hasher.combine(String(describing: function))
	}
}

// MARK: - Checkpoint + Encodable

extension Checkpoint: Encodable {
	// MARK: + Private scope

	private enum CodingKeys: String,
							 CodingKey {
		case typeName
		case entityId
		case file
		case line
		case function
	}

	// MARK: + Public scope

	public func encode(to encoder: Encoder) throws {
		var container = encoder
			.container(keyedBy: CodingKeys.self)

		try container.encode(
			typeName,
			forKey: .typeName
		)
		try container.encode(
			entityId,
			forKey: .entityId
		)
		try container.encode(
			String(describing: file),
			forKey: .file
		)
		try container.encode(
			line,
			forKey: .line
		)
		try container.encode(
			String(describing: function),
			forKey: .function
		)
	}
}
