#include "NativeTime.h"

#if defined(__APPLE__) && defined(__MACH__)

// Apple platforms (iOS, macOS, tvOS, watchOS)

#include <mach/mach_time.h>
#include <pthread.h>
#include <time.h>

static mach_timebase_info_data_t g_mach_timebase_info;
static pthread_once_t g_mach_timebase_once = PTHREAD_ONCE_INIT;

static void initializeMachTimebase(void) {
    (void)mach_timebase_info(&g_mach_timebase_info);

    // Defensive check: denom should never be zero
    if (g_mach_timebase_info.denom == 0) {
        g_mach_timebase_info.numer = 0;
        g_mach_timebase_info.denom = 1;
    }
}

static inline void ensureMachTimebaseInitialized(void) {
    (void)pthread_once(&g_mach_timebase_once, initializeMachTimebase);
}

uint64_t monotonicNanos(void) {
    ensureMachTimebaseInitialized();

    uint64_t absolute_time_units = mach_absolute_time();

    // Convert Mach absolute time units to nanoseconds:
    // nanoseconds = absolute_time_units * numer / denom
    __uint128_t scaled_nanoseconds =
        (__uint128_t)absolute_time_units *
        (__uint128_t)g_mach_timebase_info.numer;

    scaled_nanoseconds /= (__uint128_t)g_mach_timebase_info.denom;

    return (uint64_t)scaled_nanoseconds;
}

uint64_t wallNanos(void) {
    struct timespec wall_clock_timespec;

    if (clock_gettime(CLOCK_REALTIME, &wall_clock_timespec) == 0) {
        return (uint64_t)wall_clock_timespec.tv_sec * 1000000000ULL
             + (uint64_t)wall_clock_timespec.tv_nsec;
    }

    return 0;
}

#elif defined(__linux__)

// Linux

#include <time.h>

#ifndef CLOCK_MONOTONIC_RAW
#define CLOCK_MONOTONIC_RAW CLOCK_MONOTONIC
#endif

uint64_t monotonicNanos(void) {
    struct timespec monotonic_timespec;

    if (clock_gettime(CLOCK_MONOTONIC_RAW, &monotonic_timespec) == 0) {
        return (uint64_t)monotonic_timespec.tv_sec * 1000000000ULL
             + (uint64_t)monotonic_timespec.tv_nsec;
    }

    return 0;
}

uint64_t wallNanos(void) {
    struct timespec wall_clock_timespec;

    if (clock_gettime(CLOCK_REALTIME, &wall_clock_timespec) == 0) {
        return (uint64_t)wall_clock_timespec.tv_sec * 1000000000ULL
             + (uint64_t)wall_clock_timespec.tv_nsec;
    }

    return 0;
}

#elif defined(_WIN32)

// Windows

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

static INIT_ONCE g_qpc_initialization_once = INIT_ONCE_STATIC_INIT;
static LARGE_INTEGER g_qpc_frequency;

static BOOL CALLBACK initializeQpcFrequency(
    PINIT_ONCE initialization_once,
    PVOID parameter,
    PVOID *context
) {
    (void)initialization_once;
    (void)parameter;
    (void)context;

    QueryPerformanceFrequency(&g_qpc_frequency);
    return TRUE;
}

uint64_t monotonicNanos(void) {
    InitOnceExecuteOnce(
        &g_qpc_initialization_once,
        initializeQpcFrequency,
        NULL,
        NULL
    );

    LARGE_INTEGER performance_counter_value;

    if (!QueryPerformanceCounter(&performance_counter_value) ||
        g_qpc_frequency.QuadPart == 0) {
        return 0;
    }

    // Convert counter ticks to nanoseconds:
    // nanoseconds = ticks * 1e9 / frequency
    unsigned __int128 counter_ticks =
        (unsigned __int128)performance_counter_value.QuadPart;

    unsigned __int128 counter_frequency =
        (unsigned __int128)g_qpc_frequency.QuadPart;

    unsigned __int128 nanoseconds =
        (counter_ticks * (unsigned __int128)1000000000ULL) /
        counter_frequency;

    return (uint64_t)nanoseconds;
}

#define UNIX_EPOCH_IN_FILETIME_100NS 116444736000000000ULL

typedef VOID (WINAPI *GetSystemTimePreciseAsFileTimeFn)(LPFILETIME);

uint64_t wallNanos(void) {
    FILETIME file_time;
    HMODULE kernel32_module = GetModuleHandleW(L"kernel32.dll");

    if (kernel32_module) {
        GetSystemTimePreciseAsFileTimeFn precise_time_function =
            (GetSystemTimePreciseAsFileTimeFn)
            GetProcAddress(kernel32_module, "GetSystemTimePreciseAsFileTime");

        if (precise_time_function) {
            precise_time_function(&file_time);
        } else {
            GetSystemTimeAsFileTime(&file_time);
        }
    } else {
        GetSystemTimeAsFileTime(&file_time);
    }

    ULARGE_INTEGER file_time_value;
    file_time_value.LowPart  = file_time.dwLowDateTime;
    file_time_value.HighPart = file_time.dwHighDateTime;

    uint64_t filetime_100ns_intervals = (uint64_t)file_time_value.QuadPart;

    if (filetime_100ns_intervals < UNIX_EPOCH_IN_FILETIME_100NS) {
        return 0;
    }

    uint64_t unix_epoch_100ns_intervals =
        filetime_100ns_intervals - UNIX_EPOCH_IN_FILETIME_100NS;

    // Convert 100ns intervals to nanoseconds
    return unix_epoch_100ns_intervals * 100ULL;
}

#else

#error "NativeTime is not supported on this platform."

#endif
