# SwiftCore

SwiftCore is a small, platform-agnostic foundation library for Swift packages.
It provides a minimal set of primitives required to build predictable, testable,
and well-layered infrastructure libraries such as EventDispatch, Telme, KVStore,
FileStore, and UIKitCore.

SwiftCore is intentionally constrained.
It exists to stabilize the bottom of the dependency graph, not to provide convenience APIs.

## Why SwiftCore exists

Infrastructure libraries often need a small set of low-level concepts:

- Time: Monotonic time for latency and duration; wall clock time for correlation.
- Identity and call-site: Entity identity and checkpoints (entity + file/line/function).
- Execution: A constrained execution model with observable task lifecycle.
- Errors: Structured, explicitly reportable errors tied to checkpoints.

SwiftCore provides these primitives once, with explicit contracts,
so higher layers can stay focused and coherent.

## Design principles

- Small surface area
- Explicit over clever
- Deterministic by default
- Strict layering

## What SwiftCore contains

### Time (Measure)

- MonotonicNanostamp — Monotonic nanoseconds for ordering and elapsed time.
- WallNanostamp — Wall clock nanoseconds since Unix epoch.

Backed by a minimal C layer (NativeTime) for platform-specific implementations.

### Entity

- Entity — Runtime identity consisting of typeName and identifier.
- Reference types derive identifiers from ObjectIdentifier.
- Value types must assign and store an identifier explicitly.

### Checkpoint

- Checkpoint — Entity identity plus call-site information (file, line, function).
- Used to model control-flow and causal relationships.
- Create with `Checkpoint.checkpoint(_:file:line:function:)`; use `next(_:file:line:function:)` to record a successor and emit a correlation event.
- Emits created and correlated events to a global sink when set via `Checkpoint.setEventSink(_:)`.

### ErrorEntity and ErrorInfo (planned)

Structured error representation for observability and correlation is planned:

- ErrorEntity — A constrained protocol for errors that are safe to export (Error, Sendable, Encodable); only explicitly adopting errors participate in structured reporting.
- ErrorInfo — An envelope tying an ErrorEntity to a Checkpoint, with optional scalar metadata.

SwiftCore does not capture or serialize arbitrary Error values. Higher layers may wrap system errors into domain-specific types that opt into reporting.

### TaskQueue

- main — Serial queue (main thread).
- default — Serial queue for deterministic background work.
- background — Concurrent queue for long-running or parallel work.

Each task is associated with a Checkpoint.
Lifecycle events may be emitted to a global sink when set via `TaskQueue.setEventSink(_:)`.

### ScalarValue

- A constrained scalar value type for structured metadata.
- Supports string, bool, int64, uint64, double, and float.
- Codable, Sendable, and Hashable.

## What SwiftCore does not contain

- Logging or telemetry exporters
- Networking or persistence
- UI utilities
- General-purpose helpers

## Stability

SwiftCore is a foundational dependency.
Public APIs are expected to remain stable with rare breaking changes.
