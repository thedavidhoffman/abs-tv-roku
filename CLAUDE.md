# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

ABSTV is a Roku SceneGraph app (BrightScript + XML) that connects to an [Audiobookshelf](https://www.audiobookshelf.org/) server to browse and play audiobooks on Roku TVs. The app has no unit test framework; validation is done via BrightScript compiler and manual testing on a Roku device.

## Commands

```bash
npm run validate                 # BrightScript type/syntax check, output to build/staging
npm run increment-build-version  # increment build_version in manifest by 1
npm run build                    # increment build_version + clean + validate
npm run package                  # build + create out/abstv.<major>.<minor>.<build>.zip
npm run deploy                   # increment build_version + validate + deploy to Roku device
npm run clean                    # remove build/ and out/
npm run logviewer                # start browser-based Roku log viewer
```

Deployment requires copying `rokudeploy.example.json` to `rokudeploy.json` and filling in the Roku device IP and developer password.

Use `npm run validate` for a non-mutating check. `build`, `package`, and `deploy` modify `manifest` by incrementing `build_version`.

VS Code tasks (Ctrl+Shift+B): validate, package, deploy, clean-staging.

**Run validation after each architectural change** so boundary mistakes are caught while the change is still small.

## Architecture

### Thread Model

Roku SceneGraph has two threads: the **render thread** (all component `.brs` files) and the **task thread** (`components/tasks/*Task`). Network calls must run in a task thread. UI components communicate with a domain-specific task by writing a `request` associative array and setting `control = "run"`, then observing the `response` field for results. Endpoint-specific Audiobookshelf API logic lives inside the task that owns the async request.

### Key Components

- **`source/main.brs`** - Creates `roSGScreen`, enables Roku memory warning monitoring, instantiates `MainScene`, and enters the event loop.
- **`components/pages/MainScene/`** - App shell: top-level routing between Login/HomePage/Library/Player, global focus recovery, auth lifecycle (resume, expiration, logout), and app exit.
- **`components/controllers/AuthController/`** - Auth state machine; reads/writes the Roku registry via `source/store/AuthStore.brs`.
- **`components/pages/Player/`** - Audiobook playback UI. Uses a hidden Roku `Video` node (not `Audio`) so it can set `disableScreenSaver`; the node must keep `enableUI="false"` and configure content as `contentType = "audio"`. **Do not swap it for an `Audio` node** without handling screensaver suppression another way.
- **`components/tasks/*Task`** - Background task components split by API domain. Endpoint-specific Audiobookshelf API calls live in the task that owns the async request.
- **`source/HttpClient.brs`** - Shared HTTP request infrastructure for task-owned API calls.
- **`source/mappers/`** - Map raw Audiobookshelf API responses to app-level structs and reduced cache shapes.
- **`source/store/`** - Roku registry persistence (`AuthStore`, `SettingsStore`).

### Component Ownership

Each feature component owns its own API calls, loading state, and local navigation state; don't route those through `MainScene`. Communication up to `MainScene` should be narrow and event-like (item selected, auth error, close requested). Pass session context down explicitly as `server`, `token`, and `bookLibraryId` request fields; don't let child components read global scene state.

Extract shared pure logic into `/source` helpers only when it is genuinely reused across components, or when keeping it in a component would make that component responsible for unrelated calculations.

## Style & Naming

### BrightScript

- `/source` public helpers: module-style prefix, such as `AuthStore_Load` or `SettingsStore_Load`.
- `/source` file-internal helpers: `__` prefix, such as `__GetCollapseSeriesQueryValue`.
- Component-local functions in `components/`: plain behavioral names, such as `initStyle` or `onKeyEvent`.
- Color fields: integer hex literals, such as `m.title.color = &h0F1A2AFF` (not string `"0x0F1A2AFF"`).
- Do not use `FormatJson()` for outbound API request bodies when key casing matters; Roku lowercases JSON object keys during serialization.

### XML

- Literal color attribute values: `0x` prefix, such as `color="0xF3F7FBFF"`.

### Comment Headers

BrightScript functions generally use a three-line comment header:

```brightscript
'-------------------------------------------------------------------------------
' functionName
'-------------------------------------------------------------------------------
```

For `src/config.js`, this header format is required for every function definition. Elsewhere, follow the surrounding file style and keep headers aligned with the exact function name when adding or moving functions.

## Packaging And Release Notes

- `scripts/increment-build-version.mjs` increments `manifest` `build_version`.
- `scripts/package.mjs` names packages from manifest version fields: `out/abstv.<major_version>.<minor_version>.<build_version>.zip`.
- Keep `RELEASE-NOTES.md`, `PRIVACY-POLICY.md`, and `TERMS-OF-USE.md` aligned with certification-facing changes.
- The manifest currently declares `rsg_version=1.3`; Roku Developer Dashboard minimum firmware should be 15.1 or greater for certification.

## External References

- Audiobookshelf API docs: https://github.com/audiobookshelf/audiobookshelf-api-docs
- Audiobookshelf server source: https://github.com/advplyr/audiobookshelf
- Roku SceneGraph samples: https://github.com/rokudev/samples
- Roku reference docs: https://developer.roku.com/en-au/docs/references/references-overview.md

Before changing Audiobookshelf API calls, playback-session handling, media metadata mapping, playlist behavior, or chapter behavior, review the linked API docs for the relevant endpoint/response shape.
