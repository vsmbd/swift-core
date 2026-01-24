# SwiftCore

SwiftCore is a small, platform-agnostic foundation library for Swift packages.
It provides a minimal set of primitives required to build predictable, testable,
and well-layered infrastructure libraries such as EventDispatch, Logger, Telme,
and UIKitCore.

SwiftCore is intentionally constrained.
It exists to stabilize the bottom of the dependency graph, not to provide convenience APIs.

## Why SwiftCore exists

Infrastructure libraries often need a tiny set of low-level concepts:
- monotonic time measurement for latency and duration
- wall clock time for logging and correlation
- a small, consistent execution model for background and serial work

SwiftCore provides these primitives once, with explicit contracts, so higher layers can stay focused and coherent.

## Design principles

- Small surface area
- Explicit over clever
- Deterministic by default
- Strict layering

## What SwiftCore contains

### Measurement
Value types for timestamp based measurements:
- `MonotonicNanostamp` for monotonic measurements
- `WallNanostamp` for wall clock time in unix epoch nanoseconds

These are backed by a minimal C layer (`NativeTime`) for platform-specific time sources.

### TaskQueue
A constrained execution abstraction exposing exactly three queues:
- Main (serial)
- Default (serial, deterministic FIFO)
- Background (concurrent)

## What SwiftCore does not contain

No logging, telemetry, networking, persistence, UI utilities, or general helpers.

## Stability

SwiftCore is a foundational dependency.
Public APIs are expected to remain stable with rare breaking changes.

## License

MIT or Apache-2.0
