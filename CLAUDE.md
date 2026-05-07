# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

ABSTV is a Roku SceneGraph app (BrightScript + XML) that connects to an [Audiobookshelf](https://www.audiobookshelf.org/) server to browse and play audiobooks on Roku TVs. It is side-loaded (not in the Roku channel store). The app has no unit test framework — validation is done via BrightScript compiler and manual testing on a Roku device.

## Commands

```bash
npm run validate    # BrightScript type/syntax check (bsc compiler), output to build/staging
npm run build       # clean + validate
npm run package     # create deployable ZIP → out/ABSTV.zip
npm run deploy      # deploy ZIP to Roku device (requires rokudeploy.json)
npm run clean       # remove build/staging directories
```

Deployment requires copying `rokudeploy.example.json` to `rokudeploy.json` and filling in the Roku device IP and dev password.

VS Code tasks (Ctrl+Shift+B): validate, package, deploy, clean-staging.

**Run validation after each architectural change** so boundary mistakes are caught while the change is still small.

## Architecture

### Thread model

Roku SceneGraph has two threads: the **render thread** (all component `.brs` files) and the **task thread** (`components/tasks/AppTask`). Network calls must run in the task thread. UI components communicate with `AppTask` by writing a `request` associative array and setting `control = "run"`, then observing the `response` field for results. `AppTask` dispatches on `request.action` to the appropriate API helper in `source/api/`.

### Key components

- **`source/main.brs`** — Creates `roSGScreen`, instantiates `MainScene`, enters the event loop.
- **`components/pages/MainScene/`** — App shell: top-level routing between Login/HomePage/Library/Player, global focus recovery, auth lifecycle (resume, expiration, logout), and app exit.
- **`components/controllers/AuthController/`** — Auth state machine; reads/writes the Roku registry via `source/store/AuthStore.brs`.
- **`components/pages/Player/`** — Audiobook playback UI (~1,300 lines). Uses a hidden Roku `Video` node (not `Audio`) so it can set `disableScreenSaver`; the node must keep `enableUI="false"` and configure content as `contentType = "audio"`. **Do not swap it for an `Audio` node** without handling screensaver suppression another way.
- **`components/tasks/AppTask`** — Background task; supported actions: `login`, `authorize`, `logout`, `loadLibrary`, `startPlayback`. See [.docs/application.md](.docs/application.md) for the full interface contract.
- **`source/api/`** — Pure API call helpers (HttpClient, Authentication, Libraries, LibraryItems, Item, Series, Playback, etc.).
- **`source/mappers/`** — Map raw Audiobookshelf API responses to app-level structs.
- **`source/store/`** — Roku registry persistence (`AuthStore`, `SettingsStore`).

### Component ownership

Each feature component owns its own API calls, loading state, and local navigation state — don't route those through `MainScene`. Communication up to `MainScene` should be narrow and event-like (item selected, auth error, close requested). Pass session context down explicitly as `server`, `token`, and `bookLibraryId` request fields; don't let child components read global scene state.

Extract shared pure logic into `/source` helpers only when it is genuinely reused across components, or when keeping it in a component would make that component responsible for unrelated calculations.

## Style & Naming

### BrightScript

- `/source` public helpers: module-style prefix — `AuthStore_Load`, `Playback_Start`.
- `/source` file-internal helpers: `__` prefix — `__GetCollapseSeriesQueryValue`.
- Component-local functions in `components/`: plain behavioral names — `initStyle`, `onKeyEvent`.
- Color fields: integer hex literals — `m.title.color = &h0F1A2AFF` (not string `"0x0F1A2AFF"`).

### XML

- Literal color attribute values: `0x` prefix — `color="0xF3F7FBFF"`.

### Comment headers

Every function definition in a source file gets a three-line comment header:
```brightscript
'-------------------------------------------------------------------------------
' functionName
'-------------------------------------------------------------------------------
```
Lines 1 and 3 are `'` followed by dashes to column 80. Line 2 is `' ` followed by the exact function name.

## External References

- Audiobookshelf API docs: https://github.com/audiobookshelf/audiobookshelf-api-docs
- Audiobookshelf server source: https://github.com/advplyr/audiobookshelf
- Roku SceneGraph samples: https://github.com/rokudev/samples
- Roku reference docs: https://developer.roku.com/en-au/docs/references/references-overview.md

Before changing Audiobookshelf API calls, playback-session handling, media metadata mapping, or chapter behavior, review the linked API docs for the relevant endpoint/response shape.
