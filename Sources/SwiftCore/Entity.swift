//
//  Entity.swift
//  SwiftCore
//
//  Created by vsmbd on 30/01/26.
//

import SwiftCoreNativeCounters

// MARK: - Entity

public typealias EntityID = UInt64

public protocol Entity: Sendable {
	var typeName: String { get }
	var identifier: EntityID { get }
}

public extension Entity {
	var typeName: String {
		String(describing: type(of: Self.self))
	}

	static var nextID: EntityID {
		nextEntityID()
	}
}

public extension Entity where Self: AnyObject {
	var identifier: EntityID {
		UInt64(UInt(bitPattern: ObjectIdentifier(self)))
	}
}

// MARK: - Checkpoint

public struct Checkpoint: Sendable {
	// MARK: + Private scope

	private init(
		typeName: String,
		entityId: EntityID,
		file: StaticString,
		line: UInt,
		function: StaticString
	) {
		self.typeName = typeName
		self.entityId = entityId
		self.file = file
		self.line = line
		self.function = function
	}

	// MARK: + Public scope

	public let typeName: String
	public let entityId: EntityID
	public let file: StaticString
	public let line: UInt
	public let function: StaticString

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
