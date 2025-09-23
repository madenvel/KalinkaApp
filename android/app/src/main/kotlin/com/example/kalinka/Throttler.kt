package com.example.kalinka

class Throttler(private val maxFrequencyHz: Double) {
    private var lastActionNotSent: Runnable? = null
    private var lastActionSentTimestamp: Long = 0

    fun executeWithThrottle(action: Runnable) {
        val now = System.currentTimeMillis()
        val minIntervalMs = (1000.0 / maxFrequencyHz).toLong()

        val elapsed = now - lastActionSentTimestamp
        if (elapsed < minIntervalMs) {
            lastActionNotSent = action
            return
        }

        lastActionNotSent = null
        lastActionSentTimestamp = now
        action.run()
    }

    fun flush() {
        lastActionNotSent?.let {
            it.run()
            lastActionSentTimestamp = System.currentTimeMillis()
            lastActionNotSent = null
        }
    }
}