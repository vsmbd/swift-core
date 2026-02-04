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

// Captures wall and monotonic time in one call so both refer to the same instant.
// Fills out->wallNanos and out->monotonicNanos with minimal delay between samples
// (wall captured first, then monotonic). Use for session baselines.
typedef struct {
	uint64_t wallNanos;
	uint64_t monotonicNanos;
} NativeTimeBaseline;

void nativeTimeBaseline(NativeTimeBaseline *out);

#ifdef __cplusplus
} // extern "C"
#endif
