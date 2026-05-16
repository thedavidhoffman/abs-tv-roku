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
