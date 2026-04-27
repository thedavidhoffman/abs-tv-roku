# login page
- branding
- if already haz auth token, refresh
- if error, display modal with error info

# home page
- Continue Listening
- Recently Added

# header
- check for audiobook library, only support that
- home, library, series, search, user
- settings
    - library view display { list, grid }
    - library view series { collapse, expand }

# settings

## Library
- grid/list view
- expand/collapse series


# library view
- grid view, list view

# library view - list view
- clean up layout
- how to handle collapsed series view
- if back button is clicked move to top of list
- if at top of list and back button is clicked move focus to header

# player
- description modal
    - see if ScrollableText would be a better choice than our custom scroll
    - extend scroll by one line (see ark in space)
- Resume
- Restart
- Meditations won't play - WHY?
- chapter nav broken - FIX

# color palette
- establish

# cover art
- curved frame for cover
- placeholder image for no cover

# general
- loading spinner

# NEXT UP...

duration display helper

LibraryView
- move list out of Library into LibraryListView
- create LibraryGridView
- add toggle for different views

- header
    - remove audiobooks (aka library list)
    - add search before books/series, change all to buttons
- build out DTOs? https://deepwiki.com/audiobookshelf/audiobookshelf-api-docs/3.1-data-model-and-schemas


Today...
player, no chapters don't display chapter title
listview
listview librarystatus
login refresh token if we have one
error modal


# names

ShelfTV

AudioShelf TV

CouchShelf

BookBeam

ShelfStream

ShelfPlayer

PurplePlayer?

RELEASE NOTES
I'm excited to release version 1.0 of ABSTV, an AudioBookshelf (ABS) client for Roku. This is my first time developing a Roku app, and to be honest, it would not have been successful without the help of AI. To be clear, I didn't just "vibe code" this app. I'm an experienced senior software developer and I used AI as a tool to help craft this app. I took the AI output and constantly refined, reorganized, encapsulated, and abstracted it. That being said. This is version 1.0 of this app, and there's still plenty of room for improvement, and I'm still learning about the interesting world that is Roku app development.

This app is not availabe in the official Roku channel store. It must be side-loaded onto a Roku device. I'm assuming that most people that run the ABS docker image have a little technical ability, so they should be able to side-load this app. Once this app gets to a point that it has several releases under it's belt and it has reached some point of maturity, I may look to get it in the official Roku channel store.

If you're a user of Audiobookshelf and looking to use it on your TV, I hope you find this application useful.

I'm open to any and all suggestions for enhancements and improvements.