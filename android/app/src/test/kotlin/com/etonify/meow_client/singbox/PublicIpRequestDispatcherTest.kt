package com.etonify.meow_client.singbox

import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class PublicIpRequestDispatcherTest {
    private class ManualExecutor : Executor {
        private val pending = java.util.ArrayDeque<Runnable>()
        override fun execute(task: Runnable) { pending.add(task) }
        fun drain() { while (pending.isNotEmpty()) pending.removeFirst().run() }
    }
    private val direct = Executor { it.run() }

    @Test fun cancelBeforeWorkerAndBeforeSubmitNeverStartsNetwork() {
        val worker = ManualExecutor()
        var calls = 0
        val cancelled = mutableListOf<String>()
        val dispatcher = PublicIpRequestDispatcher<Any, String>(worker, direct, direct) { _, id -> cancelled.add(id) }
        var result: Result<String>? = null
        dispatcher.submit("queued", Any(), { calls++; "wrong" }) { result = it }
        dispatcher.cancel("queued") { assertTrue(it.isSuccess) }
        worker.drain()
        assertEquals(0, calls)
        assertTrue(result!!.isFailure)
        assertEquals(listOf("queued"), cancelled)
        dispatcher.cancel("early") {}
        dispatcher.submit("early", Any(), { calls++; "wrong" }) { assertTrue(it.isFailure) }
        worker.drain()
        assertEquals(0, calls)
    }

    @Test fun duplicateAndLateCancelCannotAffectDifferentRequestOrClient() {
        val worker = ManualExecutor()
        val first = Any()
        val second = Any()
        val cancelled = mutableListOf<Pair<Any, String>>()
        val dispatcher = PublicIpRequestDispatcher<Any, String>(worker, direct, direct) { client, id -> cancelled.add(client to id) }
        dispatcher.submit("one", first, { "one" }) { assertTrue(it.isSuccess) }
        dispatcher.submit("one", second, { "bad" }) { assertTrue(it.isFailure) }
        worker.drain()
        dispatcher.submit("two", second, { "two" }) { assertEquals("two", it.getOrThrow()) }
        dispatcher.cancel("one") {}
        worker.drain()
        assertTrue(cancelled.isEmpty())
    }

    @Test fun cancelBetweenLookupAndCallbackDropsCompletedOldResult() {
        val callbacks = ManualExecutor()
        val dispatcher = PublicIpRequestDispatcher<Any, String>(direct, direct, callbacks) { _, _ -> }
        var result: Result<String>? = null
        dispatcher.submit("old", Any(), { "late" }) { result = it }
        dispatcher.cancel("old") {}
        callbacks.drain()
        assertTrue(result!!.isFailure)
    }

    @Test fun cancellationDoesNotWaitBehindBlockedLookupAndSharedClientStaysAlive() {
        val lookupWorker = Executors.newSingleThreadExecutor()
        val cancelWorker = Executors.newSingleThreadExecutor()
        try {
            val entered = CountDownLatch(1)
            val stopped = CountDownLatch(1)
            val completed = CountDownLatch(1)
            val sharedClient = AtomicInteger(7)
            val dispatcher = PublicIpRequestDispatcher<AtomicInteger, String>(lookupWorker, cancelWorker, direct) { client, id ->
                assertSame(sharedClient, client)
                assertEquals("blocked", id)
                stopped.countDown()
            }
            dispatcher.submit("blocked", sharedClient, {
                entered.countDown()
                assertTrue(stopped.await(2, TimeUnit.SECONDS))
                "must-not-return"
            }) { assertTrue(it.isFailure); completed.countDown() }
            assertTrue(entered.await(2, TimeUnit.SECONDS))
            dispatcher.cancel("blocked") { assertTrue(it.isSuccess) }
            assertTrue(completed.await(2, TimeUnit.SECONDS))
            assertEquals(7, sharedClient.get())
            val second = CountDownLatch(1)
            dispatcher.submit("next", sharedClient, { "alive" }) { assertEquals("alive", it.getOrThrow()); second.countDown() }
            assertTrue(second.await(2, TimeUnit.SECONDS))
        } finally { lookupWorker.shutdownNow(); cancelWorker.shutdownNow() }
    }
}
