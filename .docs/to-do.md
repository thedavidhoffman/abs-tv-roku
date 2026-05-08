
RELEASE NOTES
I'm excited to release version 1.0 of ABSTV, an AudioBookshelf (ABS) client for Roku. This is my first time developing a Roku app, and to be honest, it would not have been successful without the help of AI. To be clear, I didn't just "vibe code" this app. I'm an experienced senior software developer and I used AI as a tool to help craft this app. I took the AI output and constantly refined, reorganized, encapsulated, and abstracted it. That being said. This is version 1.0 of this app, and there's still plenty of room for improvement, and I'm still learning about the interesting world that is Roku app development. I'm also positive there is room for improvement with performance.



If you're a user of Audiobookshelf and looking to use it on your TV, I hope you find this application useful.

I'm open to any and all suggestions for enhancements and improvements.


# PREVIEW NOTES
I wanted to share some progess that I'm making on a Roku app for Audiobookshelf. I started this as a side project to do for fun, and while there is no shortage of iPhone apps for ABS, I couldn't find any for Roku.

Let's take a look at what it does, and then we'll discuss what it doesn't do.

So here's what the app doesn't do...
- There is no support for podcasts, collections, playlists, browsing by authors or narrators. Maybe in the future, but for now I've limited the scope of work to exclude those features.
- I'm not trying to hit every bell and blow every whistle, instead I'm looking to release a reasonable functioning Roku app for playing audiobooks from audiobookshelf.
- This app will not be availabe in the official Roku channel store. It must be side-loaded onto a Roku device. I'm assuming that most people that run the ABS docker image have some technical ability, so they should be able to side-load this app. In the future I may look to get it on the official Roku channel store.

Also, big disclaimer...
This is my first time developing a Roku app, and to be honest, it would not have been successful without the help of AI. To be clear, I didn't just "vibe code" this app. I'm an experienced senior software engineer and I used AI as a tool to help craft this app. I took the AI output and constantly refined, reorganized, encapsulated, and abstracted it. That being said. This app is still in beta, there will be bugs and there's plenty of room for improvement.

Ok, all that being said, if you're interested in being a beta tester hit me up in the comments. And if anyone out there is asking themselves if you can trust some random Roku app from some random guy on the internet, that is most definitely a question you should be asking yourself. I'll say two things in reponse to that. First, I am in no way attempting to exploit or track any of your data. And second, if you're using an ABS client on your iPhone or Android, then you've already extended your trust to those apps.

## Hit List
----------------------------------------------------
- roku channel screens

- search
    - listview support search results

- StandardKeyboardDialog on login form

- investigate passing episode id into play, this might fix our play/advance issue
- /api/items/${this.libraryItem.id}/play/${this.episodeId}` : `/api/items/${this.libraryItem.id}/play`

Playback.brs
----------------------------------------------------
- the content type being set in map tracks is off, being set from two different payloads
- why oh why does this need two payloads: tracks = ___MapTracks(server, token, playbackResult.data, itemPayload, log)
- continue to dig in on this file

Titles with playback problems
----------------------------------------------------
- courtship of princess leia playback
- dune playback
- meditations playback
- play James Bond, plays correctly, play it again, it rifles through tracks and starts playback at a much later track

- end session when playback stops - verify, i think this is done
- sync progress - verify, i think this is done
- test description modal with really long title

- in-progress bar for series
- loading spinner/indicator

Continue Listening (home page)
    - * key triggers menu
    - mark as finished
    - removed from continue listening "HideFromContinueListening"

- error modal

- on playback (https://api.audiobookshelf.org/#play-a-library-item-or-podcast-episode) send the device info



