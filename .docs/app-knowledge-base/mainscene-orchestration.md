# MainScene Request Orchestration

`MainScene` is the app-level coordinator between UI components and `AppTask`.
Components do not call API modules directly. Instead, they expose observable
fields such as `loginRequested`, `playSelected`, or `playbackStartRequested`.
`MainScene` observes those fields, builds an API request object, runs the
appropriate `AppTask`, then routes the response back to the component or state
owner that initiated the work.

## Task Components

`components/pages/MainScene/MainScene.xml` owns several `AppTask` instances.
Each is the same `components/tasks/AppTask.xml` component, but each instance is
used for a different lane of work:

```brightscript
m.apiTask
m.playbackApiTask
m.libraryApiTask
m.personalizedApiTask
```

`AppTask` has two public fields:

```xml
<field id="request" type="assocarray" />
<field id="response" type="assocarray" />
```

`MainScene.startApiTask` starts work by assigning the request and running the
task:

```brightscript
sub startApiTask(task as dynamic, request as object)
    if task = invalid then return

    task.request = request
    task.control = "run"
end sub
```

Inside `components/tasks/AppTask.brs`, `executeRequest` reads
`m.top.request.action`, dispatches to the matching API function, and writes the
result to `m.top.response`.

## Request Shape

Requests are associative arrays with an `action` field. Most authenticated
requests also include `server`, `token`, and any endpoint-specific ids.

Examples:

```brightscript
{
    action: "loadLibrary"
    server: m.session.server
    token: m.session.token
    bookLibraryId: m.session.bookLibraryId
}
```

```brightscript
{
    action: "startPlayback"
    server: request.server
    token: request.token
    itemId: request.itemId
    title: request.title
}
```

`AppTask.executeRequest` dispatches by action:

```brightscript
if action = "login" then
    m.top.response = login(request)
else if action = "loadLibrary" then
    m.top.response = LibraryItems_Load(request)
else if action = "startPlayback" then
    m.top.response = Playback_Start(request)
end if
```

## Login And Authorization

`Login` emits `loginRequested`.

`MainScene.onLoginRequested` forwards that request to `m.apiTask`:

```brightscript
request = m.login.loginRequested
startApiTask(m.apiTask, request)
```

When `m.apiTask.response` changes, `onApiResponse` handles `login` and
`authorize` responses by storing the authenticated session and showing the app:

```brightscript
storeAuthenticatedSession(response)
storeMediaProgress(m.session.mediaProgress)
showApp()
```

Session restore is initiated by `MainScene` itself in `tryResumeSession`, which
sends an `authorize` request to `m.apiTask`.

## Library And Series Loading

Full library reloads are initiated by `MainScene.reloadLibraryItems`.

```brightscript
startApiTask(m.libraryApiTask, {
    action: "loadLibrary"
    server: m.session.server
    token: m.session.token
    bookLibraryId: m.session.bookLibraryId
})
```

Series drill-in starts from a `Library` component event. `Library` emits
`seriesSelected`; `MainScene.onLibrarySeriesSelected` builds a `loadSeries`
request and runs `m.libraryApiTask`.

Responses from `m.libraryApiTask` are handled in `onLibraryApiResponse`:

```brightscript
if response.action = "loadLibrary" then
    storeLibraryItems(response)
else if response.action = "loadSeries" then
    storeSeriesItems(response)
end if
```

Those handlers write the returned items back into `m.library.libraryItems`,
which updates the original library UI.

## Personalized Home Shelves

`MainScene.loadPersonalizedShelves` is triggered by app startup and home
navigation. It runs `m.personalizedApiTask` with `action: "loadPersonalized"`.

`onPersonalizedApiResponse` routes successful responses to
`storePersonalizedShelves`, which writes the returned shelves into
`m.homePage.personalizedShelves`.

## Playback

Playback starts from either `HomePage` or `Library`.

The child component emits `playSelected`, and `MainScene` calls
`playLibraryItem(selectedItem)`. This shows the `Player`, gives it focus, and
sets `m.player.playRequest`.

`Player` reacts to `playRequest` internally and emits
`playbackStartRequested`.

`MainScene.onPlaybackStartRequested` forwards the request to `m.apiTask`:

```brightscript
request = m.player.playbackStartRequested
startApiTask(m.apiTask, request)
```

`onApiResponse` handles the `startPlayback` response and writes it back to the
original caller:

```brightscript
if m.player <> invalid then m.player.playbackResponse = response
```

The player observes `playbackResponse` and starts playback from the returned
session and track data.

Playback sync and close requests use a separate task lane:

```brightscript
startApiTask(m.playbackApiTask, request)
```

Those responses are handled by `onPlaybackApiResponse`. At the moment,
successful sync/close responses do not need to be routed back to `Player`; auth
errors are routed through `handleExpiredSession`.

## Response Routing

Responses are routed by the task instance that produced them:

- `m.apiTask.response` -> `onApiResponse`
- `m.libraryApiTask.response` -> `onLibraryApiResponse`
- `m.personalizedApiTask.response` -> `onPersonalizedApiResponse`
- `m.playbackApiTask.response` -> `onPlaybackApiResponse`

`getApiResponseAction` prefers `response.action`, but falls back to the task's
last request action:

```brightscript
if response <> invalid and response.action <> invalid then return response.action
if task <> invalid and task.request <> invalid and task.request.action <> invalid then
    return task.request.action
end if
```

This lets `MainScene` route responses even when an API helper does not echo the
action field.

## Ownership Rule

`MainScene` owns app orchestration and shared runtime state:

- authenticated session
- media progress
- active page visibility
- library back stack
- which task lane handles each request
- where each response should be written

Child components own UI interaction. They request work by changing observable
fields, then receive results through fields that `MainScene` sets after the
task completes.
