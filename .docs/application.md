# Application Code Notes

## Purpose

This file documents the application code structure, important components, and
the contracts between major parts of the Roku app. It is intended as a living
reference for how the code is organized and how key files should be used.

## AppTask

`components/tasks/AppTask.brs` is the app's background API task. It is declared
in `components/tasks/AppTask.xml` as a Roku SceneGraph `Task` component:

```xml
<component name="AppTask" extends="Task">
```

Roku `Task` components run work away from the main SceneGraph render thread.
This makes `AppTask` the right place for network requests and response mapping
that should not block the UI. UI components send work to the task by setting the
`request` field, starting the task with `control = "run"`, and observing the
`response` field.

### Interface

`AppTask.xml` exposes two fields:

- `request`: an associative array describing the action to perform.
- `response`: an associative array containing the result.

The task sets:

```brightscript
m.top.functionName = "executeRequest"
```

That causes Roku to run `executeRequest()` when the task is started.

### Supported Actions

`executeRequest()` reads `request.action` and dispatches to the appropriate
handler:

- `login`: calls `Authentication_Login(request)`.
- `authorize`: calls `Authentication_AuthorizeToken(request)`.
- `logout`: calls `Authentication_Logout(request)`.
- `loadLibrary`: calls `loadLibrary(request)`.
- `startPlayback`: calls `Playback_Start(request)`.

Unknown or missing actions return an error response.

### Included Helpers

`AppTask.xml` includes shared helper scripts before `AppTask.brs`:

- `source/Formatting.brs`
- `source/api/HttpClient.brs`
- `source/api/Authentication.brs`
- `source/api/Playback.brs`

Those files provide formatting helpers, HTTP request handling, authentication
API actions, and playback-session mapping.

### `loadLibrary`

`loadLibrary(request)` loads audiobook library items from Audiobookshelf.

Expected request fields:

- `server`
- `token`
- `bookLibraryId`

If `bookLibraryId` is missing, the task verifies the token with
`/api/authorize` and resolves the first available book library. It then pages
through `/api/libraries/{libraryId}/items` until all results are loaded.

The successful response includes:

- `ok: true`
- `action: "loadLibrary"`
- `bookLibraryId`
- `libraryItems`
