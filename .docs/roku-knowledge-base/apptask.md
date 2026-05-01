# Roku AppTask

SceneGraph `Task` nodes run BrightScript work away from the main render thread.
They are the right place for network calls and heavier response mapping.

## Multiple Task Instances

Use more than one instance of the same `Task` component when the app needs
independent API work to run at the same time.

```xml
<AppTask id="authApiTask" />
<AppTask id="libraryApiTask" />
<AppTask id="homeApiTask" />
```

Each node has its own `request`, `response`, and `control` state. This lets the
home page load personalized shelves while the library loads items, without one
request overwriting or blocking the other.

## Single Task Instance

A single `Task` node can be used for all API work only if requests are strictly
sequential, or if the app implements a queue/dispatcher.

Avoid setting a new `request` and running the same task again while it may still
be processing a previous request. That can make responses ambiguous and can
clobber in-flight work.

## Naming

Prefer naming task instances by their lane of responsibility, not by the shared
component type:

- `authApiTask`
- `libraryApiTask`
- `homeApiTask`

This keeps the concurrency model visible in `MainScene` while still sharing the
same reusable `AppTask` implementation.

