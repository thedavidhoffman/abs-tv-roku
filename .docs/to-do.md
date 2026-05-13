
## Hit List
----------------------------------------------------

- compare playback on ABS client vs this client
- 05-12 19:10:52.416 [Playback::CloseSession] sessionId=3da16aed-3e69-4af5-9905-daa6fc783c05 currentTime=invalid timeListened=invalid duration=invalid
- courtship of princess leia - static on playback
- library... list... expanded... doctor who titles prefixed with a number
- media progress on library titles not displaying

- roku channel screens

- default page setting
    - home
    - library
    - series

- diagnostic screen
    - add cache info
    - add library names

- login form
    - use StandardKeyboardDialog
    - branding
    - review UI


The promising bit to remember for tomorrow: the working direction appears to be HLS PlayStart at the ABS global resume time, plus the larger resume retry window. No more “unable to resume” path, no post-start HLS seek, no final-output.m3u8 detour.

Titles with playback problems
----------------------------------------------------
- courtship of princess leia
- the hutt gambit
- meditations playback
- play James Bond, plays correctly, play it again, it rifles through tracks and starts playback at a much later track

- in-progress bar for series
- loading spinner/indicator

Continue Listening (home page)
    - * key triggers menu
    - mark as finished
    - removed from continue listening "HideFromContinueListening"

- error modal

- on playback (https://api.audiobookshelf.org/#play-a-library-item-or-podcast-episode) send the device info



