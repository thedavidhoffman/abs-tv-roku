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
- `loadInProgress`
- `loadPersonalized`
- `startPlayback`
- `syncPlaybackSession`
- `closePlaybackSession`

The task writes the result to `m.top.response`.

## Current Task Instances

Task instances are owned by the component responsible for the feature state:

```xml
<AppTask id="authApiTask" />
<AppTask id="allItemsTask" />
<AppTask id="collapsedItemsTask" />
<AppTask id="inProgressApiTask" />
<AppTask id="personalizedApiTask" />
<AppTask id="playbackApiTask" />
```

Current ownership:

- `AuthController` owns `authApiTask` for login, token authorization, and logout.
- `LibraryController` owns `allItemsTask` and `collapsedItemsTask` for parallel
  `loadLibrary` requests. It caches both the all-title library result and the
  collapsed-series library result.
- `MainScene` owns `inProgressApiTask` for post-playback progress refreshes.
- `HomePage` owns `personalizedApiTask` for personalized shelves.
- `Player` owns `playbackApiTask` for playback start, sync, and close-session requests.

`Library`, `ListView`, and `Series` do not currently own `AppTask` instances.
They request search results, series rows, and series-item drilldowns through
`LibraryController`, which serves those responses from its library caches.

This keeps `MainScene` focused on app-shell routing and lets each feature own
its local loading state, response handling, and error publication.

## Running A Request

The owning component sets `request`, then starts the task:

```brightscript
m.allItemsTask.request = {
    action: "loadLibrary"
    server: m.loadRequest.server
    token: m.loadRequest.token
    bookLibraryId: m.loadRequest.bookLibraryId
    cacheKey: "allTitles"
    collapseSeries: false
    requestGeneration: m.requestGeneration
}
m.allItemsTask.control = "run"
```

The same component observes `response`:

```brightscript
m.allItemsTask.observeField("response", "onAllItemsResponse")
```

The response handler should stay in the owner component unless the result is a
high-level event that must be reported upward, such as `playSelected`,
`errorResponse`, or an authenticated session.

## Multiple Task Instances

Use more than one instance of the same `Task` component when the app needs
independent API work to run at the same time, or when different components own
different loading state.

Each task node has its own `request`, `response`, and `control` state. This lets
home shelves load through `HomePage`, progress refreshes load through
`MainScene`, playback calls run through `Player`, and library cache loads run
in parallel through `LibraryController` without one request overwriting another
component's in-flight work.

`LibraryController` is the main case where multiple task instances of the same
component are intentionally owned by one component. It runs `allItemsTask` and
`collapsedItemsTask` at the same time, tags each request with `cacheKey` and
`requestGeneration`, then ignores stale responses from older generations.

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
- `allItemsTask`
- `collapsedItemsTask`
- `inProgressApiTask`
- `personalizedApiTask`
- `playbackApiTask`

This keeps the concurrency and ownership model visible while still sharing the
same reusable `AppTask` implementation.

## Supported Actions And Current Use

`AppTask` still dispatches `loadSeries` to `Series_Load(request)`, but the
current UI path for series rows and drilldowns is cache-backed in
`LibraryController`. The controller publishes `loadSeriesRows` and `loadSeries`
responses from cached library data rather than starting a separate `AppTask`.

`loadInProgress` is used by `MainScene` after playback closes so Home, Library,
and Series can receive refreshed media-progress data.
