package com.example.kalinka

import android.media.VolumeProvider
import android.os.Handler
import android.os.Looper

class RemoteVolumeProvider(
    private val max: Int,
    currentVolume: Int,
    private val onLocalSet: (Int) -> Unit,     // send to server (throttled)
    private val onInteractionStart: () -> Unit,
    private val onInteractionEnd: () -> Unit
) : VolumeProvider(VOLUME_CONTROL_ABSOLUTE, max, currentVolume) {

    private val main = Handler(Looper.getMainLooper())
    private var inMode = false
    private var endRunnable: Runnable? = null
    private val windowMs = 250L

    private fun touch() {
        if (!inMode) {
            inMode = true
            onInteractionStart()
        }
        endRunnable?.let(main::removeCallbacks)
        endRunnable = Runnable {
            inMode = false
            onInteractionEnd() // e.g., reconcile with cached server value
        }.also { main.postDelayed(it, windowMs) }
    }

    override fun onAdjustVolume(direction: Int) {
        // direction: -1, 0, +1
        touch()
        val newVol = (currentVolume + direction).coerceIn(0, max)
        if (newVol != currentVolume) {
            currentVolume = newVol     // updates system UI immediately
            onLocalSet(newVol)           // send to server (throttle during inMode)
        }
    }

    override fun onSetVolumeTo(volume: Int) {
        touch()
        val newVol = volume.coerceIn(0, max)
        if (newVol != currentVolume) {
            currentVolume = newVol     // updates system slider position instantly
            onLocalSet(newVol)           // send to server (throttle)
        }
    }
}