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

# library view
- grid view, list view

# library view - list view
- clean up layout
- how to handle collapsed series view
- if back button is clicked move to top of list
- if at top of list and back button is clicked move focus to header

# player
- description modal
    - update header with title
    - extend scroll by one line
- Resume
- Restart
- move description and transport up
- navigation from default play button focus UP to description
- highlighted description cover last line better, extend margins for better highligh
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


Scrollable text?? Instead of custom scroll on description and chapters dialog???
https://developer.roku.com/docs/references/scenegraph/typographic-nodes/scrollabletext.md

Scrolling label
https://developer.roku.com/docs/references/scenegraph/typographic-nodes/scrollinglabel.md

BusySpinner
https://developer.roku.com/docs/references/scenegraph/widget-nodes/busyspinner.md


# names

ShelfTV

AudioShelf TV

CouchShelf

BookBeam

ShelfStream

ShelfPlayer

PurplePlayer?

