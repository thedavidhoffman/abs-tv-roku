# Roku AppTask

SceneGraph `Task` nodes run BrightScript work away from the main render thread.
They are the right place for network calls and heavier response mapping.

This app uses one reusable `AppTask` component, but creates separate task
instances in the feature components that own each lane of API work.

## Shared Component

`components/tasks/AppTask.xml` includes the API modules and exposes a small
request/response interface:

```xml
<field id="request" type="assocarray" />
<field id="response" type="assocarray" />
```

`components/tasks/AppTask.brs` sets:

```brightscript
m.top.functionName = "executeRequest"
```

`executeRequest()` dispatches by `request.action`, for example:

- `login`
- `authorize`
- `logout`
- `loadLibrary`
- `loadSeries`
- `loadPersonalized`
- `startPlayback`
- `syncPlaybackSession`
- `closePlaybackSession`

The task writes the result to `m.top.response`.

## Current Task Instances

Task instances are owned by the component responsible for the feature state:

```xml
<AppTask id="authApiTask" />
<AppTask id="libraryApiTask" />
<AppTask id="seriesApiTask" />
<AppTask id="personalizedApiTask" />
<AppTask id="playbackApiTask" />
```

Current ownership:

- `AuthController` owns `authApiTask` for login, token authorization, and logout.
- `Library` owns `libraryApiTask` for root library loads and grid-view series drilldown.
- `ListView` owns `seriesApiTask` for inline MarkupList series expansion.
- `HomePage` owns `personalizedApiTask` for personalized shelves.
- `Player` owns `playbackApiTask` for playback start, sync, and close-session requests.

This keeps `MainScene` focused on app-shell routing and lets each feature own
its local loading state, response handling, and error publication.

## Running A Request

The owning component sets `request`, then starts the task:

```brightscript
m.libraryApiTask.request = {
    action: "loadLibrary"
    server: m.loadRequest.server
    token: m.loadRequest.token
    bookLibraryId: m.loadRequest.bookLibraryId
}
m.libraryApiTask.control = "run"
```

The same component observes `response`:

```brightscript
m.libraryApiTask.observeField("response", "onLibraryApiResponse")
```

The response handler should stay in the owner component unless the result is a
high-level event that must be reported upward, such as `playSelected`,
`errorResponse`, or an authenticated session.

## Multiple Task Instances

Use more than one instance of the same `Task` component when the app needs
independent API work to run at the same time, or when different components own
different loading state.

Each task node has its own `request`, `response`, and `control` state. This lets
home shelves load through `HomePage`, library items load through `Library`,
inline series load through `ListView`, and playback calls run through `Player`
without one request overwriting another component's in-flight work.

## Single Task Instance

A single `Task` node can be used for multiple API actions only if those requests
are strictly sequential within the same owner, or if the owner implements a
queue/dispatcher.

Avoid setting a new `request` and running the same task again while it may still
be processing a previous request. That can make responses ambiguous and can
clobber in-flight work.

## Naming

Name task instances by their lane of responsibility, not by the shared component
type:

- `authApiTask`
- `libraryApiTask`
- `seriesApiTask`
- `personalizedApiTask`
- `playbackApiTask`

This keeps the concurrency and ownership model visible while still sharing the
same reusable `AppTask` implementation.
