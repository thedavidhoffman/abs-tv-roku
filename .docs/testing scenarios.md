# Test scenarios:

## Header Libraries Button

### 1. One library

The header should not display the libraries button, the other buttons { Home, Library, Series, Search, Settings } should display centered as a group.

### 2. One library and a podcast library

The header should not display the libraries button, the other buttons { Home, Library, Series, Search, Settings } should display centered as a group. The podcast library should be ignored and the one library should be active.

### 3. Multiple libraries

The header should display the libraries button with a dropdown list of all libraries that the user can switch between.

### 4. Multiple libraries and a podcast library

The header should display the libraries button with a dropdown list of all libraries that the user can switch between.
Any podcast directories should not be listed.

## Header back button

1. When the libraries button is displayed, has focus, and the `BACK` button is pressed the exit confirmation dialog should display.
2. When the libraries button is not displayed, the Home button has focus, and the `BACK` button is pressed the exit confirmation dialog should display.

## Header button navigation

1. All header buttons should navigate in order.
2. When the first button in the header has focus and the `LEFT` button is pressed focus should move to the last button in the header.
3. When the last button in the header has focus and the `RIGHT` button is pressed focus should move to the first button in the header.

## Library with no content

Test a library with no content to make sure that screens and navigation all work correctly.

## Player

1. Play/pause.
2. Restart.
3. Tint.
4. Scrub left/right on the progress bar using the playhead.
5. Chapter navigation.
6. Description highlight (only when the description is truncated).
7. Description dialog.
8. When the player is closed the item that had focus on the GridView, ListView or Series should still have focus.

## Screensaver

1. Configured screensaver displays at the configured time interval.
2. Remote key events restart the screensaver delay timer (if the screensaver is not yet displayed).
3. When the screensaver is displayed it should get focus. Any remote key events should dimiss the screensaver and not trigger any functionality on playback.
4. If the description dialog is displayed and the screensaver kicks in, the description dialog should be dismissed.
5. If the chapter dialog is displayed and the screensaver kicks in, the description dialog should be dismissed.
