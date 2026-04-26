# AGENTS.md

## audiobookshelf reference

- Before changing Audiobookshelf API calls, playback-session handling, media metadata mapping, or playlist/chapter behavior, review the linked Audiobookshelf docs for the relevant endpoint/response shape.
- audiobookshelf API git repo: https://github.com/audiobookshelf/audiobookshelf-api-docs
- audiobookshelf server git repo: https://github.com/advplyr/audiobookshelf

## Commenting Style

- Add a three-line comment header immediately above each function definition in `src/config.js`.
- Line 1 must be `'` followed immediately by dashes, extending to the 80th column with no space before the first dash.
- Line 2 must be `' ` followed by the exact function name.
- Line 3 must match line 1 exactly.
