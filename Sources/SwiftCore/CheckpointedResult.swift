//
//  CheckpointedResult.swift
//  SwiftCore
//
//  Created by vsmbd on 01/02/26.
//

/// A result type that carries a checkpoint on both success and failure for structured reporting.
/// Success carries the value and the checkpoint where success was determined; failure carries `ErrorInfo` (error entity, checkpoint, timestamp, etc.).
/// Conforms to `Encodable` when `Success` is `Encodable`.
public enum CheckpointedResult<
	Success: Sendable,
	Failure: ErrorEntity
>: Sendable {
	case success(Success, Checkpoint)
	case failure(ErrorInfo<Failure>)
}

// MARK: - Encodable

extension CheckpointedResult: Encodable where Success: Encodable {
	// MARK: + Private scope

	private enum CodingKeys: String,
							 CodingKey {
		case success
		case failure
	}

	private enum SuccessCodingKeys: String,
									CodingKey {
		case value
		case checkpoint
	}

	private enum FailureCodingKeys: String,
									CodingKey {
		case errorInfo
	}

	// MARK: + Public scope

	public func encode(to encoder: Encoder) throws {
		var container = encoder
			.container(keyedBy: CodingKeys.self)

		switch self {
		case let .success(value, checkpoint):
			var successContainer = container.nestedContainer(
				keyedBy: SuccessCodingKeys.self,
				forKey: .success
			)
			try successContainer.encode(
				value,
				forKey: .value
			)
			try successContainer.encode(
				checkpoint,
				forKey: .checkpoint
			)

		case let .failure(errorInfo):
			var failureContainer = container.nestedContainer(
				keyedBy: FailureCodingKeys.self,
				forKey: .failure
			)
			try failureContainer.encode(
				errorInfo,
				forKey: .errorInfo
			)
		}
	}
}
