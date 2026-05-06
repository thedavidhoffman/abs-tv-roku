# MainScene Orchestration

`MainScene` is the app shell. It owns top-level visibility, route changes,
global focus recovery, and app exit handling. It should not be the central API
task router for feature work.

Feature components and controllers own their own `AppTask` instances when they
can safely own the full request/response loop:

- `AuthController` owns login, authorize, logout, registry persistence, and
  authenticated session creation.
- `HomePage` owns personalized shelf loading.
- `Library` owns library loading, series drill-in, and library drilldown state.
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
<Header id="header" />
<Search id="search" />
<Player id="player" />
<OverlayHost id="overlayHost" />
<AuthController id="authController" />
```

There is intentionally no generic `AppTask` lane in `MainScene` for Library,
HomePage, Player, or Auth. Those tasks live with the components/controllers that
own their behavior.

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

`MainScene.buildSessionLoadRequest()` builds this object. `HomePage` and
`Library` receive it through their `loadRequest` fields. Components should treat
this as explicit input, not read session state from `MainScene`.

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
```

`Library` owns its internal `libraryApiTask`. It loads root library items,
loads series drill-in items, stores its own drilldown back stack, and updates
its List/Grid child views.

`Library` emits:

- `playSelected` when the user chooses an audiobook
- `upFromFirstItemSelected` or `backFromFirstItemSelected` for focus recovery
- `itemsReloaded` after a root reload completes
- `errorResponse` for auth/global errors

`MainScene` uses `itemsReloaded` only for the current settings-save focus
recovery case. When settings change, MainScene updates `m.library.displaySettings`,
asks Library to reload, and focuses the Settings button after reload completes.

## Player Flow

Playback can start from `HomePage` or `Library`; both emit `playSelected`.

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

## Overlay Flow

`Header` emits `overlayRequested`. `MainScene` forwards the request to
`OverlayHost.openOverlay`.

When an overlay closes:

- Settings close: MainScene applies saved settings to Library, asks Library to
  reload, and returns focus to the Settings button after reload.
- Exit close: MainScene sets `closeRequested = true` when confirmed, otherwise
  returns focus to Header.
- Other closes: MainScene returns focus to the user menu button.

## MainScene Ownership

`MainScene` should own:

- app shell visibility
- major route changes between Home, Library, Search, Player, Login, and overlays
- global focus recovery
- the current authenticated session object
- passing session context and media progress to feature components
- app exit requests

`MainScene` should not own:

- feature-specific API task instances
- feature-specific response routing
- Library drilldown state
- personalized shelf state
- playback session sync/close
- auth registry persistence

When adding new behavior, prefer placing the `AppTask` and response handling in
the component/controller that owns the workflow, then expose a narrow event-like
field back to `MainScene` only when the app shell must react.
