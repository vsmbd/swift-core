//
//  SwiftCore.swift
//  SwiftCore
//
//  Created by vsmbd on 24/01/26.
//

/// SwiftCore re-exports the Measure module (e.g. `MonotonicNanostamp`, `WallNanostamp`) so clients that depend on SwiftCore get time types without adding Measure as a separate dependency.
@_exported import Measure
