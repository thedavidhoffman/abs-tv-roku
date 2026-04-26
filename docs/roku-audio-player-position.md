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