


v1.1.0 Release Notes

- Screensaver support has been added. ABSTV now includes two in-app screensaver options: Bouncing Cover and Starfield. While browsing titles in ABSTV, your configured Roku screensaver will still run as usual. During audiobook playback, ABSTV disables the Roku system screensaver. If an ABSTV screensaver is enabled, it will appear during playback only.

- Audiobook descriptions now use `SmallSystemFont` instead of `SmallestSystemFont` for better TV readability. The description dialog uses the same larger text size and now renders with `ScrollableText`, allowing longer descriptions to scroll instead of being clipped.

- Clock added to player.

- New setting for grid column size with options for { 4, 5, 6 }. When items are displayed in a grid this will control the number of columns displayed in the grid and the posters will resize accordingly. Use this setting to increase/decrease the poster size. This allows for controlling the size/visibility of posters tailored to personal use (tv size and sitting distance from television).

- Substantial refactoring of code. Lots of attention to cleaning up the player code. Grouped/organized the million local variables into logical/functional groupings. Also broken the player UI out into different components. Static/stateless helper functions broken out into helper module.

- Replaced setting key string literals with string constants.