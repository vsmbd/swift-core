//
//  CheckpointedResult.swift
//  SwiftCore
//
//  Created by vsmbd on 01/02/26.
//

/// A `Result` whose success type is `Sendable` and whose failure type conforms to `ErrorEntity`, so it can be wrapped in `ErrorInfo` with a `Checkpoint` for structured reporting.
/// Conforms to `Encodable` when `Success` is `Encodable` (inherited from `Swift.Result`).
public typealias CheckpointedResult<
	Success: Sendable,
	Failure: ErrorEntity
> = Swift.Result<
	Success,
	Failure
>
