//
//  NativeCounters.h
//  SwiftCore
//
//  Created by vsmbd on 25/01/26.
//

#ifndef SWIFTCORE_NATIVE_COUNTERS_H
#define SWIFTCORE_NATIVE_COUNTERS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Returns a monotonically increasing task id (starting from 1).
/// Thread-safe on supported platforms/toolchains.
uint64_t nextTaskID(void);

/// Returns a monotonically increasing entity id (starting from 1).
/// Thread-safe on supported platforms/toolchains.
uint64_t nextEntityID(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SWIFTCORE_NATIVE_COUNTERS_H
