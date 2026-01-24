# SwiftCore Goals

This document defines what SwiftCore must achieve.

## 1. Foundational primitives only
Provide primitives required by multiple higher-level infrastructure modules.

## 2. Explicit time measurement
Expose monotonic and wall clock timestamps with clear, stable semantics.

## 3. Explicit execution semantics
Standardize execution contexts through TaskQueue.

## 4. Deterministic behavior
Prefer serial execution and testability over flexibility.

## 5. Explicit contracts
Favor clarity and constraints over broad abstractions.

## 6. Platform agnostic
No UIKit, AppKit, or platform UI assumptions.

## 7. Small and stable API
Minimize public surface area and avoid frequent breaking changes.
