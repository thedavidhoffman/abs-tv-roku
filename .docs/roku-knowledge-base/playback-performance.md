# Playback Performance

## Audiobookshelf playback flags

`forceDirectPlay` tells Audiobookshelf to try playing the original media file directly instead of transcoding it.

For Roku, direct play can be risky with large progressive MP3 files. Small MP3 files around 10-20 MB played and stopped cleanly, but large MP3 files around 500 MB could destabilize the app when stopping playback.

`forceTranscode` tells Audiobookshelf to generate a transcoded playback stream. In this app we currently prefer transcoding for Roku playback so large files are delivered as HLS-style segmented media instead of one huge progressive MP3 stream.

Current playback request shape:

```brightscript
body = FormatJson({
    deviceInfo: {
        clientName: "ABSTV"
        clientVersion: "0.1.0"
        manufacturer: "Roku"
        model: "Roku"
    }
    forceDirectPlay: false
    forceTranscode: true
    supportedMimeTypes: [
        "application/vnd.apple.mpegurl"
        "application/x-mpegURL"
        "audio/mpegurl"
        "audio/x-mpegurl"
    ]
    mediaPlayer: "roku"
})
```

## Roku stability notes

Roku handled large Audiobookshelf MP3 streams more reliably after switching from progressive MP3 direct playback to HLS/transcoded playback.

The player already maps URLs containing `.m3u8` or `/hls/` to `streamFormat = "hls"`. Playback URL mapping should preserve HLS playlist URLs and not rewrite them to `/public/session/<sessionId>/track/<index>`.

Use direct play only if there is a strong reason to avoid server transcoding and the media size/format is known to be safe on Roku.
