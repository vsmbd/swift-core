# SwiftCore Goals

This document defines what SwiftCore must achieve.

## 1. Foundational primitives only

Provide primitives required by multiple higher-level infrastructure modules (time, identity/call-site, execution, structured scalar values).

## 2. Explicit time measurement

Expose monotonic and wall-clock timestamps with clear, stable semantics (MonotonicNanostamp, WallNanostamp).

## 3. Identity and call-site for correlation

Provide Entity and Checkpoint so higher layers can correlate events and flow without SwiftCore implementing logging or telemetry.

## 4. Explicit execution semantics

Standardize execution contexts through TaskQueue (main, default, background) with observable task lifecycle tied to Checkpoint.

## 5. Deterministic behavior

Prefer serial execution and testability over flexibility.

## 6. Explicit contracts

Favor clarity and constraints over broad abstractions.

## 7. Platform agnostic

No UIKit, AppKit, or platform UI assumptions.

## 8. Small and stable API

Minimize public surface area and avoid frequent breaking changes.
