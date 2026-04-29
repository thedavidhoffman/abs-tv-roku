# login page
- branding
- if already haz auth token, refresh
- if error, display modal with error info

# player
- description modal
    - see if ScrollableText would be a better choice than our custom scroll
    - extend scroll by one line (see ark in space)
- Resume
- Restart
- Meditations won't play - WHY?

# localization
- https://developer.roku.com/en-au/docs/developer-program/core-concepts/localization.md

# device info (for debugging modal?)
- https://developer.roku.com/en-au/docs/references/brightscript/interfaces/ifdeviceinfo.md


duration display helper

- build out DTOs? https://deepwiki.com/audiobookshelf/audiobookshelf-api-docs/3.1-data-model-and-schemas


json formatter for response output to log...
https://www.npmjs.com/package/brighterscript-formatter
https://github.com/nikolay-mamaev/BrightScript-Json-Beautifier


RELEASE NOTES
I'm excited to release version 1.0 of ABSTV, an AudioBookshelf (ABS) client for Roku. This is my first time developing a Roku app, and to be honest, it would not have been successful without the help of AI. To be clear, I didn't just "vibe code" this app. I'm an experienced senior software developer and I used AI as a tool to help craft this app. I took the AI output and constantly refined, reorganized, encapsulated, and abstracted it. That being said. This is version 1.0 of this app, and there's still plenty of room for improvement, and I'm still learning about the interesting world that is Roku app development. I'm also positive there is room for improvement with performance.

This app is not availabe in the official Roku channel store. It must be side-loaded onto a Roku device. I'm assuming that most people that run the ABS docker image have some technical ability, so they should be able to side-load this app. Once this app gets to a point that it has several releases under it's belt and it has reached some point of maturity, I may look to get it in the official Roku channel store.

If you're a user of Audiobookshelf and looking to use it on your TV, I hope you find this application useful.

I'm open to any and all suggestions for enhancements and improvements.


## Hit List

- home page, continue listening, stats, recently added
- settings, put focus back on main page
- listview support collapsed/expanded
- loading spinner (add only after fixing the collapsed/expanded display quirk)
- error modal
- description modal -> convert to dialog use on both ListView and Player
- html string function move to helper class
- fix chapter nav not working
- placeholder image for no cover
- search
- diagnostics, [clear settings registry] [clear auth registry]
- player, continue listening from last point
- back button at certain level closes the app, see if we can trap this and prompt about exit
- expand gridview series, navigate away, come back, can't get back to collapsed gridview


## Quirks

when switching expand to collapse, it starts to render the component with old data, then updates it when the new data returns from the api
--> roku performance tricks on hide/show things
--> should you tear things down and dynamically reload them

- click on an item to play, quickly hit return, the list is displayed, but the player is still playing