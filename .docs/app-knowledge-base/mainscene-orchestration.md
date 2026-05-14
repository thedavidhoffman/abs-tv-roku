# MainScene Orchestration

`MainScene` is the app shell. It owns top-level visibility, route changes,
global focus recovery, and app exit handling. It should not be the central API
task router for feature work.

Feature components and controllers own their own `AppTask` instances when they
can safely own the full request/response loop:

- `AuthController` owns login, authorize, logout, registry persistence, and
  authenticated session creation.
- `HomePage` owns personalized shelf loading.
- `LibraryController` owns library loading and cache-backed search/series data.
- `Library` owns library view state, search/drilldown navigation, and list/grid
  presentation.
- `Series` owns series-page rendering and focus behavior.
- `Player` owns playback start, playback sync, and playback-session close.

`MainScene` passes session context down, observes high-level component events,
and coordinates what should be shown or focused next.

## MainScene Children

`components/pages/MainScene/MainScene.xml` contains the app surfaces and the
auth controller:

```xml
<Login id="login" />
<HomePage id="homePage" />
<Library id="library" />
<Series id="seriesPage" />
<Header id="header" />
<Search id="search" />
<Player id="player" />
<OverlayHost id="overlayHost" />
<AuthController id="authController" />
<LibraryController id="libraryController" />
<AppTask id="inProgressApiTask" />
```

There is intentionally no generic `AppTask` lane in `MainScene` for Library,
HomePage, Player, or Auth. Those tasks live with the components/controllers that
own their behavior. The one current `MainScene` task is `inProgressApiTask`,
which refreshes media progress after playback closes so multiple surfaces can
receive the updated progress snapshot.

## Session Context

After auth succeeds, `AuthController` emits `authenticatedSession`.
`MainScene` stores that session in `m.session`, stores mapped media progress in
`m.mediaProgress`, shows the app shell, and passes request context down to
feature components.

The shared request context shape is:

```brightscript
{
    server: m.session.server
    token: m.session.token
    bookLibraryId: m.session.bookLibraryId
}
```

`MainScene.buildSessionLoadRequest()` builds this object. `HomePage`, `Library`,
`Series`, and `LibraryController` receive it through their `loadRequest` fields
as needed. Components should treat this as explicit input, not read session
state from `MainScene`.

## Auth Flow

`Login` owns the login UI and emits `loginRequested`.

`MainScene` forwards that request to `AuthController.loginRequest`. It also
signals session restore through `AuthController.resumeRequested` and logout
through `AuthController.logoutRequest`.

`AuthController` owns:

- loading saved auth state from `AuthStore`
- running auth API requests through its internal `authApiTask`
- saving and clearing registry auth data
- building the authenticated session object
- emitting auth state events

`MainScene` observes:

- `authenticatedSession` -> store session, pass media progress down, show app
- `loginRequired` -> show Login with a message
- `loginFailed` -> show Login status message
- `sessionExpired` -> clear visible app state and show Login

Auth expiry reported by feature components is routed through
`MainScene.handleComponentError()`, which clears the saved token through
`AuthController` and returns the app to Login.

## HomePage Flow

`MainScene` sets:

```brightscript
m.homePage.loadRequest = buildSessionLoadRequest()
m.homePage.mediaProgress = m.mediaProgress
```

`HomePage` owns its internal `personalizedApiTask`. When its `loadRequest`
changes, or when `reloadPersonalizedShelves()` is called, it runs
`loadPersonalized`, stores the returned shelves in its own
`personalizedShelves` field, and renders the home rows.

`HomePage` emits:

- `playSelected` when the user chooses an audiobook
- `backSelected` or `upFromFirstRowSelected` for focus recovery
- `errorResponse` for auth/global errors

`MainScene` reacts by starting playback, focusing Header, or handling auth
errors.

## Library Flow

`MainScene` sets:

```brightscript
m.library.loadRequest = buildSessionLoadRequest()
m.library.mediaProgress = m.mediaProgress
m.libraryController.loadRequest = buildSessionLoadRequest()
```

`LibraryController` owns the API/cache lane for library data. It runs parallel
`loadLibrary` requests through `allItemsTask` and `collapsedItemsTask`, caches
the all-title and collapsed-series results, and publishes:

- `libraryItemsChanged` / `libraryItems` for the current root library list
- `searchResponse` for cache-backed search results
- `seriesItemsResponse` for cache-backed series drill-in items
- `seriesRowsResponse` for the standalone Series page
- `errorResponse` for auth/global errors

`Library` owns view/navigation state. It receives root items and controller
responses from `MainScene`, stores its own drilldown back stack, and updates its
List/Grid child views. It emits `controllerSearchRequest` and
`seriesItemsRequest` when it needs cache-backed data from `LibraryController`.

`Library` emits:

- `playSelected` when the user chooses an audiobook
- `upFromFirstItemSelected` or `backFromFirstItemSelected` for focus recovery
- `itemsReloaded` after a root reload completes
- `mainListRestored` when returning from drilldown/search to the main list
- `controllerSearchRequest` when search needs cache-backed results
- `seriesItemsRequest` when ListView needs cache-backed series drill-in items
- `errorResponse` for auth/global errors

`MainScene` forwards Library requests to `LibraryController`, forwards
controller responses back into `Library`, and uses `itemsReloaded` only for the
current settings-save focus recovery case. When settings change, MainScene
updates both `m.library.displaySettings` and
`m.libraryController.displaySettings`, then focuses the Settings button after
the library update completes.

## Series Flow

Playback can also start from `Series`, which emits `playSelected`.

`MainScene` sets:

```brightscript
m.seriesPage.loadRequest = buildSessionLoadRequest()
m.seriesPage.mediaProgress = m.mediaProgress
```

When the user opens Series, `MainScene` sends a `seriesRowsRequest` to
`LibraryController`. The controller builds rows from its cached library data and
publishes `seriesRowsResponse`; `MainScene` forwards that response to
`Series.seriesRowsResponse`.

`Series` owns its RowList/empty-state rendering and focus behavior. If there are
no series, it shows `No series found` and keeps focus on the Series component so
Up and Back can still return to the header.

`Series` emits:

- `playSelected` when the user chooses an audiobook
- `upFromFirstRowSelected` or `backSelected` for focus recovery
- `errorResponse` for auth/global errors

## Player Flow

Playback can start from `HomePage`, `Library`, or `Series`; each emits
`playSelected`.

`MainScene.playbackPlayItem()` shows `Player`, gives it focus, and sets
`m.player.playRequest` with session context, cover URL, metadata, and a start
position.

Start position lookup is delegated to `source/MediaProgressLookup.brs`:

```brightscript
MediaProgressLookup_GetStartPosition(selectedItem, m.mediaProgress)
```

`Player` owns its internal `playbackApiTask`. It handles:

- `startPlayback`
- periodic `syncPlaybackSession`
- seek/pause sync requests
- `closePlaybackSession`

`Player` emits:

- `closeRequested` when the player should be hidden
- `errorResponse` for auth/global errors

`MainScene` restores the previous app surface and focus when Player closes.
For auth-expired player errors, MainScene closes Player before returning to
Login so authenticated content is not left visible.

After Player closes, `MainScene` also reloads Home personalized shelves and runs
`inProgressApiTask` with `loadInProgress`. Successful progress refreshes are
merged into `m.mediaProgress` and pushed back down to HomePage, Library, and
Series.

## Overlay Flow

`Header` emits `overlayRequested`. `MainScene` forwards the request to
`OverlayHost.openOverlay`.

When an overlay closes:

- Settings close: MainScene applies saved settings to Library, asks Library to
  update, applies the same display settings to LibraryController, and returns
  focus to the Settings button after the library update completes.
- Exit close: MainScene sets `closeRequested = true` when confirmed, otherwise
  returns focus to Header.
- Other closes: MainScene returns focus to the user menu button.

## MainScene Ownership

`MainScene` should own:

- app shell visibility
- major route changes between Home, Library, Search, Player, Login, and overlays
- forwarding cache-backed LibraryController responses to Library and Series
- global focus recovery
- the current authenticated session object
- passing session context and media progress to feature components
- post-playback media progress refresh and fan-out
- app exit requests

`MainScene` should not own:

- feature-specific API task instances, except the cross-surface
  post-playback `inProgressApiTask`
- feature-specific response routing
- Library drilldown state
- personalized shelf state
- playback session sync/close
- auth registry persistence

When adding new behavior, prefer placing the `AppTask` and response handling in
the component/controller that owns the workflow, then expose a narrow event-like
field back to `MainScene` only when the app shell must react.
