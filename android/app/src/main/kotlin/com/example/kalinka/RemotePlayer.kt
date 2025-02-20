package com.example.kalinka

import android.os.Looper
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.SimpleBasePlayer
import androidx.media3.common.util.UnstableApi
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

@UnstableApi
class RemotePlayer(
    private val playerController: RpiPlayerProxy,
    looper: Looper
) :
    EventCallback,
    SimpleBasePlayer(looper) {
    private var playerState = PlayerState()

    override fun getState(): State {
        val availableCommands = Player.Commands.Builder()
            .add(COMMAND_PLAY_PAUSE)
            .add(COMMAND_STOP)
            .add(COMMAND_SEEK_TO_NEXT)
            .add(COMMAND_SEEK_TO_PREVIOUS)
            .add(COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM)
            .build()

        val state = when (playerState.state ?: "IDLE") {
            "IDLE" -> STATE_IDLE
            "PLAYING" -> STATE_READY
            "PAUSED" -> STATE_READY
            "BUFFERING" -> STATE_BUFFERING
            "READY" -> STATE_READY
            "ERROR" -> STATE_IDLE
            "STOPPED" -> STATE_ENDED
            "SKIP_TO_NEXT" -> STATE_BUFFERING
            "SKIP_TO_PREV" -> STATE_BUFFERING
            "SEEK_IN_PROGRESS" -> STATE_BUFFERING
            else -> STATE_IDLE
        }

        return State.Builder().setAvailableCommands(availableCommands).setPlaybackState(state)
            .setPlayerError(
                if (playerState.state == "ERROR") PlaybackException(
                    "Error", null, PlaybackException.ERROR_CODE_REMOTE_ERROR
                ) else null
            ).build()
    }

    override fun handleSetPlayWhenReady(playWhenReady: Boolean): ListenableFuture<*> {
        if (playWhenReady) {
            when (playerState.state) {
                "PLAYING" -> {}
                "PAUSED" -> playerController.pause(false) {}
                 else -> playerController.play {}
            }
        } else {
            when(playerState.state) {
                "PLAYING" -> playerController.pause(true) {}
                else -> {}
            }
        }
        return Futures.immediateVoidFuture()
    }

    override fun handleStop(): ListenableFuture<*> {
        playerController.stop {}
        return Futures.immediateVoidFuture()
    }

    override fun handleSeek(
        mediaItemIndex: Int, positionMs: Long, seekCommand: Int
    ): ListenableFuture<*> {
        when (seekCommand) {
            COMMAND_SEEK_TO_NEXT -> playerController.skipToNext {}
            COMMAND_SEEK_TO_PREVIOUS -> playerController.skipToPrev {}
            COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM -> playerController.seekTo(positionMs) {}
            else -> playerController.seekTo(positionMs) {}
        }
        return Futures.immediateVoidFuture()
    }

    override fun onStateChanged(newState: PlayerState) {
        playerState = newState
    }

    override fun onDisconnected() {
        TODO("Not yet implemented")
    }

    override fun onFavoriteTrackAdded(trackId: String) {
        TODO("Not yet implemented")
    }

    override fun onFavoriteTrackRemoved(trackId: String) {
        TODO("Not yet implemented")
    }
}