package com.etonify.meow_client.singbox

import java.util.concurrent.atomic.AtomicLong

/**
 * Coalesces Android wake signals that commonly arrive as a short burst
 * (for example SCREEN_ON followed by USER_PRESENT).
 */
internal class RuntimeRecoveryGate(
    private val minimumIntervalMillis: Long,
) {
    private var lastAcceptedAtMillis = NO_TIMESTAMP
    private var lastNetworkGeneration = 0L

    init {
        require(minimumIntervalMillis >= 0L)
    }

    @Synchronized
    fun tryAcquire(nowMillis: Long, networkGeneration: Long = 0L): Boolean {
        if (lastAcceptedAtMillis != NO_TIMESTAMP) {
            if (networkGeneration < lastNetworkGeneration) return false
            if (networkGeneration == lastNetworkGeneration &&
                nowMillis >= lastAcceptedAtMillis &&
                nowMillis - lastAcceptedAtMillis < minimumIntervalMillis
            ) return false
        }
        lastAcceptedAtMillis = nowMillis
        lastNetworkGeneration = networkGeneration
        return true
    }

    @Synchronized
    fun reset() {
        lastAcceptedAtMillis = NO_TIMESTAMP
        lastNetworkGeneration = 0L
    }

    private companion object {
        const val NO_TIMESTAMP = Long.MIN_VALUE
    }
}

/** Keeps only the newest delayed probe after a physical network handover. */
internal class NetworkHandoverProbeGate {
    private val generation = AtomicLong(0L)

    fun replace(): Long = generation.incrementAndGet()

    fun isCurrent(token: Long): Boolean = generation.get() == token

    fun tryConsume(token: Long): Boolean = generation.compareAndSet(token, token + 1L)

    fun invalidate() {
        generation.incrementAndGet()
    }
}

internal fun isNetworkHandoverRecoverySource(source: String): Boolean =
    source.startsWith("network_change:")
