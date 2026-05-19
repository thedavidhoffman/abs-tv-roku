# FormatJson Key Casing

## Do not use FormatJson for API request bodies

Roku's `FormatJson()` will lowercase object keys when serializing BrightScript associative arrays. That can produce syntactically valid JSON that is semantically wrong for APIs with case-sensitive field names.

Audiobookshelf playback start is a known failure case. The app intended to send `supportedMimeTypes`, but FormatJson() converted the key to `supportedmimetypes` and the ABS server logged:

```text
[Book] checkCanDirectPlay: supportedMimeTypes is not an array undefined
```

Because Audiobookshelf did not see the correctly cased `supportedMimeTypes` field, it selected an HLS/transcode session and generated MP3-in-HLS output that Roku played as static.

## Preferred pattern

For outbound API request bodies, build JSON explicitly so field names keep their exact API casing:

```brightscript
body = "{" + Chr(34) + "supportedMimeTypes" + Chr(34) + ":[" + Chr(34) + "audio/mpeg" + Chr(34) + "]}"
```

There are helper functions for building JSON in `/source/Json.brs`.

Keep helper builders close to the API module that owns the request shape. Log the raw body during playback/API debugging when server behavior does not match the local request object.

`FormatJson()` is still acceptable for non-wire uses such as approximate debug/cache byte-size estimates, where exact key casing is not consumed by an external API.
