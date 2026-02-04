# SwiftCore Goals

## Provide foundational primitives
- Time, identity, execution, and error modeling
- Shared across all higher-level infrastructure modules

## Enforce explicit contracts
- Strong typing
- Opt-in error reporting
- Clear execution semantics

## Maintain strict layering
- No dependency on higher-level systems
- No policy decisions baked into primitives

## Enable observability
- Correlatable tasks, events, and errors
- Export-ready representations without assuming a backend
- Time baseline (wall + monotonic) for converting event timestamps to wall time

## Stay minimal
- Small API surface
- No convenience abstractions
