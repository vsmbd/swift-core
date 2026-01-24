#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Monotonic nanoseconds suitable for measuring durations.
// Origin is unspecified (typically boot). Must not be used as wall time.
// Returns 0 on failure.
uint64_t monotonicNanos(void);

// Wall-clock time in Unix epoch nanoseconds.
// Subject to NTP/manual clock changes and may jump.
// Returns 0 on failure.
uint64_t wallNanos(void);

#ifdef __cplusplus
} // extern "C"
#endif
