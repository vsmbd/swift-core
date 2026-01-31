# SwiftCore Non-Goals

This document defines what SwiftCore explicitly does not attempt to do.

## 1. Not a utilities grab-bag

No random helpers, formatting utilities, or Foundation extensions.

## 2. Not a concurrency framework

No schedulers, futures, reactive streams, or task graphs. TaskQueue is a constrained queue abstraction, not a general concurrency runtime.

## 3. Not logging or telemetry

No log levels, sinks, metrics, or exporters. SwiftCore provides Entity and Checkpoint for correlation; higher layers (e.g. Telme) implement ingestion and export.

## 4. Not application architecture

No domain logic, UI coordination, or app messaging.

## 5. Not configuration or DI

No global configuration registries or dependency injection containers.

## 6. Not a general-purpose ID or synchronization library

No standalone trace/correlation ID types beyond Entity/Checkpoint. No locks, atomics, or other synchronization primitives. Entity and Checkpoint provide observability-oriented identity and call-site context; they are not generic correlation IDs or sync primitives.

## 7. Not a performance playground

Avoid unsafe tricks and undocumented behavior.
