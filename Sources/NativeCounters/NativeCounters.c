//
//  NativeCounters.c
//  SwiftCore
//
//  Created by vsmbd on 25/01/26.
//

#include "NativeCounters.h"

#if defined(__APPLE__)

// Apple platforms (macOS, iOS, tvOS, watchOS, visionOS)

#include <stdatomic.h>

static _Atomic uint64_t taskID = 0;

uint64_t nextTaskID(void) {
	// relaxed is sufficient for uniqueness/monotonicity of the returned value
	return atomic_fetch_add_explicit(&taskID, 1, memory_order_relaxed) + 1;
}

#elif defined(__linux__)

// Linux

#include <stdatomic.h>

static _Atomic uint64_t taskID = 0;

uint64_t nextTaskID(void) {
	return atomic_fetch_add_explicit(&taskID, 1, memory_order_relaxed) + 1;
}

#elif defined(_WIN32)
// Windows (MSVC)

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

static LONG64 taskID = 0;

uint64_t nextTaskID(void) {
	// Returns incremented value.
	return (uint64_t)InterlockedIncrement64(&taskID);
}

#else

#error "NativeCounters is not supported on this platform."

#endif
