```
Why would the player display for the current playback position be skipping numbers, it doesn't display every second
```

Most likely because Roku’s Audio.position is not guaranteed to update at exact one-second intervals, even if your timer fires every second.

In your player, the progress timer fires every 1 second and reads:

```
m.audioPlayer.position
```

But that value is owned by Roku’s media engine. It can advance in chunks depending on buffering, stream format, HLS segment boundaries, decoder timing, device load, and how often the underlying playback component publishes position updates. So the UI timer may fire every second, but the position value might go from 12 to 14, or 21 to 23, because Roku did not expose an intermediate value at that moment.

A few other reasons it can happen:

- HLS/audio streams often update position less smoothly than a local clock.
- `int(val(position.ToStr()))` floors whatever Roku reports, so small timing drift can make some numbers appear skipped.
- The timer callback itself is not real-time; SceneGraph can delay timer events while layout, network, or media work is happening.
- During buffering, seeking, or track transitions, position reporting can be especially uneven.

So it is normal. The displayed position is “current reported playback position,” not a guaranteed wall-clock counter.

```
is there an approach we can take that would make it a guaranteed wall-clock counter
```

Yes, with a caveat: you can make the UI counter wall-clock based, but you cannot make it a guaranteed truth source for actual decoder playback position.

A good approach is:

When playback starts or resumes, capture:
- Roku’s reported audioPlayer.position
- current wall-clock time

While playing, display:
```
basePlaybackPosition + elapsedWallClockSeconds
```

instead of directly displaying audioPlayer.position every tick.

Whenever playback pauses, buffers, seeks, resumes, or changes tracks, re-sync the base position from audioPlayer.position.
That gives you a smooth 0:01, 0:02, 0:03... UI counter while playback is active.

The tradeoff is that it is predictive. If Roku buffers silently, stalls briefly, or playback drifts, your displayed counter can become slightly wrong until the next resync. So I’d treat Roku’s position as the authoritative value and the wall-clock counter as the presentation layer.

Best version for your app:

Use audioPlayer.position on state changes, seek completion, track start, pause, resume, buffering, and finished.
Use wall-clock elapsed time only while state is "playing".
Clamp the display to the current track duration.
Periodically resync, maybe every 10-15 seconds, to avoid drift.
That would make the display feel like a normal second-by-second counter without fighting Roku’s uneven position updates.