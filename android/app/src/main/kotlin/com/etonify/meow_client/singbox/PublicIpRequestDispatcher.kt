package com.etonify.meow_client.singbox

import java.util.concurrent.Executor
import java.util.concurrent.CancellationException

/** Owns IDs and cancellation only; never disconnects or closes a shared client. */
internal class PublicIpRequestDispatcher<C : Any, R : Any>(
    private val worker: Executor,
    private val cancellationWorker: Executor,
    private val callbacks: Executor,
    private val cancelCore: (C, String) -> Unit,
) {
    private class Entry<C>(val client: C, @Volatile var cancelled: Boolean = false)
    private val lock = Any()
    private val active = mutableMapOf<String, Entry<C>>()
    private val tombstones = mutableMapOf<String, Long>()

    private fun prune() {
        val now = System.nanoTime()
        tombstones.entries.removeAll { it.value < now }
    }

    fun submit(id: String, client: C, operation: (C) -> R, callback: (Result<R>) -> Unit) {
        val entry: Entry<C>
        synchronized(lock) {
            prune()
            if (id.isBlank() || id.length > 128 || active.containsKey(id) || tombstones.containsKey(id) || active.size + tombstones.size >= 2048) {
                callbacks.execute { callback(Result.failure(IllegalArgumentException("invalid, reused or cancelled public IP request ID"))) }
                return
            }
            entry = Entry(client)
            active[id] = entry
        }
        try {
            worker.execute {
                val result = runCatching {
                    check(!entry.cancelled) { "public IP request cancelled before start" }
                    val value = operation(entry.client)
                    if (entry.cancelled) throw CancellationException("public IP request cancelled")
                    value
                }
                callbacks.execute {
                    synchronized(lock) {
                        active.remove(id)
                        tombstones[id] = System.nanoTime() + 60_000_000_000L
                    }
                    callback(if (entry.cancelled) Result.failure(CancellationException("public IP request cancelled")) else result)
                }
            }
        } catch (error: Throwable) {
            synchronized(lock) { active.remove(id); tombstones[id] = System.nanoTime() + 60_000_000_000L }
            callbacks.execute { callback(Result.failure(error)) }
        }
    }

    fun cancel(id: String, callback: (Result<Unit>) -> Unit) {
        val entry = synchronized(lock) {
            prune()
            val value = active[id]
            if (value != null) value.cancelled = true
            else if (id.isNotBlank() && id.length <= 128 && tombstones.size < 2048) tombstones[id] = System.nanoTime() + 60_000_000_000L
            value
        }
        if (entry == null) { callbacks.execute { callback(Result.success(Unit)) }; return }
        try {
            // This executor is deliberately distinct from the blocking lookup lane.
            cancellationWorker.execute {
                val result = runCatching { cancelCore(entry.client, id) }
                callbacks.execute { callback(result) }
            }
        } catch (error: Throwable) { callbacks.execute { callback(Result.failure(error)) } }
    }
}
