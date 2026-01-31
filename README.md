# SwiftCore

SwiftCore is a small, platform-agnostic foundation library for Swift packages.
It provides a minimal set of primitives required to build predictable, testable,
and well-layered infrastructure libraries such as EventDispatch, Logger, Telme, and UIKitCore.

SwiftCore is intentionally constrained.
It exists to stabilize the bottom of the dependency graph, not to provide convenience APIs.

## Why SwiftCore exists

Infrastructure libraries often need a small set of low-level concepts:

- **Time:** Monotonic time for latency and duration; wall clock for logging and correlation.
- **Identity and call-site:** Entity identity and checkpoints (entity + file/line/function) for correlating events and flow.
- **Execution:** A constrained execution model (serial main/default, concurrent background) with observable task lifecycle.

SwiftCore provides these primitives once, with explicit contracts, so higher layers can stay focused and coherent.

## Design principles

- Small surface area
- Explicit over clever
- Deterministic by default (serial queues, stable ordering)
- Strict layering

## What SwiftCore contains

### Time (Measure, re-exported by SwiftCore)

Value types for timestamp-based measurements:

- **MonotonicNanostamp** — Monotonic nanoseconds (e.g. boot origin). Use for elapsed time and ordering; not affected by clock changes.
- **WallNanostamp** — Wall clock nanoseconds since Unix epoch. Use for human-readable time and cross-process ordering when clocks are synchronized.

Backed by a minimal C layer (`NativeTime`) for platform-specific time sources.

### Entity

Protocol for runtime identity used in checkpoints and correlation:

- **Entity** — `typeName` and `identifier`. Reference types get a default identifier from `ObjectIdentifier`; value types use `Self.nextID` and store it.
- Conform to use types as subjects of checkpoints and task/event correlation.

### Checkpoint

Call-site and entity identity for flow and correlation:

- **Checkpoint** — Entity identity plus `file`, `line`, `function` at capture.
- **Checkpoint.checkpoint(_:file:line:function:)** — Create a checkpoint for an entity at the current call site; emits `.created(checkpoint)` to the sink if set.
- **Checkpoint.next(_:file:line:function:)** — Create a successor checkpoint and emit `.correlated(from:to:)` to the sink if set.
- **Checkpoint.setEventSink(_:)** — Register a global sink for `.created` and `.correlated` events (e.g. graph storage, export). Call once at startup.

### TaskQueue

Constrained execution abstraction with observable task lifecycle:

- **main** — Serial queue (main thread).
- **default** — Serial queue (deterministic FIFO).
- **background** — Concurrent queue.

Each task is tied to a **Checkpoint**. Optional **TaskQueue.setEventSink(_:)** receives created/started/completed events (queue name, task id, checkpoint, dispatch type, monotonic timestamp).

### ScalarValue

Type-erased scalar value for structured data (e.g. event attributes, extra fields):

- Cases: `string`, `bool`, `int64`, `uint64`, `double`, `float`.
- **Codable**, **Sendable**, **Hashable**. Use in key-value bags where values must be one of these types.

## What SwiftCore does not contain

No logging, telemetry export, networking, persistence, UI utilities, or general helpers.
No locks, atomics, or other synchronization primitives (beyond the queue abstraction).

## Stability

SwiftCore is a foundational dependency.
Public APIs are expected to remain stable with rare breaking changes.

## License

MIT or Apache-2.0
