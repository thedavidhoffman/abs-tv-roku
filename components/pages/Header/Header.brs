'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    rebuildFocusableHeaderButtons()
    initHandlers()

    m.usernameUpPressCount = 0

    initStyle()
    updateUserMenuButton()
    updateCurrentLibraryButton()
    setActiveHeaderButton("home")
    setMenuOpen(false)
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.headerBg = m.top.findNode("headerBg")
    m.navGroup = m.top.findNode("navGroup")
    m.homeButton = m.top.findNode("homeButton")
    m.libraryButton = m.top.findNode("libraryButton")
    m.seriesButton = m.top.findNode("seriesButton")
    m.searchButton = m.top.findNode("searchButton")
    m.settingsButton = m.top.findNode("settingsButton")
    m.currentLibraryButton = m.top.findNode("currentLibraryButton")
    m.userMenuButton = m.top.findNode("userMenuButton")
    m.menuPanel = m.top.findNode("menuPanel")
    m.libraryMenuPanel = m.top.findNode("libraryMenuPanel")
    m.libraryMenuBg = m.top.findNode("libraryMenuBg")
    m.libraryMenuItems = m.top.findNode("libraryMenuItems")
    m.logoutButton = m.top.findNode("logoutButton")
    m.usernameUpSequenceTimer = m.top.findNode("usernameUpSequenceTimer")
    m.focusableHeaderButtons = []
    m.libraryMenuButtons = []
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.homeButton.observeField("buttonSelected", "onHomePressed")
    m.libraryButton.observeField("buttonSelected", "onLibraryPressed")
    m.seriesButton.observeField("buttonSelected", "onSeriesPressed")
    m.searchButton.observeField("buttonSelected", "onSearchPressed")
    m.settingsButton.observeField("buttonSelected", "onSettingsPressed")
    m.currentLibraryButton.observeField("buttonSelected", "onCurrentLibraryPressed")
    m.userMenuButton.observeField("buttonSelected", "onUserMenuPressed")
    m.logoutButton.observeField("buttonSelected", "onLogoutPressed")
    m.usernameUpSequenceTimer.observeField("fire", "onUsernameUpSequenceTimerFired")
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    headerBgColor = palette.background.header
    m.headerBg.color = headerBgColor
    m.homeButton.headerBgColor = headerBgColor
    m.libraryButton.headerBgColor = headerBgColor
    m.seriesButton.headerBgColor = headerBgColor
    m.searchButton.headerBgColor = headerBgColor
    m.settingsButton.headerBgColor = headerBgColor
    m.currentLibraryButton.headerBgColor = headerBgColor
    m.userMenuButton.headerBgColor = headerBgColor
    m.logoutButton.headerBgColor = headerBgColor
end sub

'-------------------------------------------------------------------------------
' focusHeader
'-------------------------------------------------------------------------------
function focusHeader() as boolean
    closeMenu()

    for each button in m.focusableHeaderButtons
        if button <> invalid then
            button.setFocus(true)
            return true
        end if
    end for

    return false
end function

'-------------------------------------------------------------------------------
' focusSettingsButton
'-------------------------------------------------------------------------------
function focusSettingsButton() as boolean
    closeMenu()
    if m.settingsButton = invalid then return false

    m.settingsButton.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' focusUserMenuButton
'-------------------------------------------------------------------------------
function focusUserMenuButton() as boolean
    closeMenu()
    if m.userMenuButton = invalid then return false

    m.userMenuButton.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' activateLibraryButton
'-------------------------------------------------------------------------------
function activateLibraryButton() as boolean
    setActiveHeaderButton("library")
    return true
end function

'-------------------------------------------------------------------------------
' activateSeriesButton
'-------------------------------------------------------------------------------
function activateSeriesButton() as boolean
    setActiveHeaderButton("series")
    return true
end function

'-------------------------------------------------------------------------------
' activateSearchButton
'-------------------------------------------------------------------------------
function activateSearchButton() as boolean
    setActiveHeaderButton("search")
    return true
end function

'-------------------------------------------------------------------------------
' isSearchButtonActive
'-------------------------------------------------------------------------------
function isSearchButtonActive() as boolean
    return m.searchButton <> invalid and m.searchButton.isActive = true
end function

'-------------------------------------------------------------------------------
' isHomeButtonFocused
'-------------------------------------------------------------------------------
function isHomeButtonFocused() as boolean
    return m.homeButton <> invalid and m.homeButton.isInFocusChain()
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean

    if press = false then return false

    if isLibraryMenuOpen() then
        if key = "up" then return focusLibraryMenuButtonByOffset(-1)
        if key = "down" then return focusLibraryMenuButtonByOffset(1)
    end if

    if key = "up" then return trackUsernameUpSequence()

    resetUsernameUpSequence()

    if key = "left" then
        return focusHeaderButtonByOffset(-1)
    else if key = "right" then
        return focusHeaderButtonByOffset(1)
    else if key = "down" then
        closeMenu()
        m.top.downSelected = true
        return true
    else if key = "back" then
        if m.top.menuOpen = true then
            closeMenu()
            return true
        end if

        closeMenu()
        m.top.backSelected = true
        return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' trackUsernameUpSequence
'-------------------------------------------------------------------------------
function trackUsernameUpSequence() as boolean
    if m.userMenuButton = invalid or m.userMenuButton.isInFocusChain() = false then
        resetUsernameUpSequence()
        return false
    end if

    m.usernameUpPressCount = m.usernameUpPressCount + 1
    restartUsernameUpSequenceTimer()

    if m.usernameUpPressCount >= 5 then
        resetUsernameUpSequence()
        m.top.overlayRequested = {
            id: "diagnostics"
            componentName: "DiagnosticsDialog"
            closeField: "closeRequested"
            openFunction: "openDiagnostics"
        }
    end if

    return true
end function

'-------------------------------------------------------------------------------
' restartUsernameUpSequenceTimer
'-------------------------------------------------------------------------------
sub restartUsernameUpSequenceTimer()
    if m.usernameUpSequenceTimer = invalid then return

    m.usernameUpSequenceTimer.control = "stop"
    m.usernameUpSequenceTimer.control = "start"
end sub

'-------------------------------------------------------------------------------
' resetUsernameUpSequence
'-------------------------------------------------------------------------------
sub resetUsernameUpSequence()
    m.usernameUpPressCount = 0
    if m.usernameUpSequenceTimer <> invalid then m.usernameUpSequenceTimer.control = "stop"
end sub

'-------------------------------------------------------------------------------
' onUsernameUpSequenceTimerFired
'-------------------------------------------------------------------------------
sub onUsernameUpSequenceTimerFired()
    resetUsernameUpSequence()
end sub

'-------------------------------------------------------------------------------
' focusHeaderButtonByOffset
'-------------------------------------------------------------------------------
function focusHeaderButtonByOffset(offset as integer) as boolean
    headerButtons = m.focusableHeaderButtons
    if headerButtons = invalid or headerButtons.Count() = 0 then return false

    currentIndex = getFocusedHeaderButtonIndex()
    if currentIndex < 0 then
        return focusHeader()
    end if

    nextIndex = currentIndex + offset
    lastIndex = headerButtons.Count() - 1

    if nextIndex < 0 then
        nextIndex = lastIndex
    else if nextIndex > lastIndex then
        nextIndex = 0
    end if

    closeMenu()

    nextButton = headerButtons[nextIndex]
    if nextButton = invalid then return false

    nextButton.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' rebuildFocusableHeaderButtons
'-------------------------------------------------------------------------------
sub rebuildFocusableHeaderButtons()
    m.focusableHeaderButtons = []

    if hasLibraryChoices() then m.focusableHeaderButtons.Push(m.currentLibraryButton)
    m.focusableHeaderButtons.Push(m.homeButton)
    m.focusableHeaderButtons.Push(m.libraryButton)
    m.focusableHeaderButtons.Push(m.seriesButton)
    m.focusableHeaderButtons.Push(m.searchButton)
    m.focusableHeaderButtons.Push(m.settingsButton)
    m.focusableHeaderButtons.Push(m.userMenuButton)
end sub

'-------------------------------------------------------------------------------
' getFocusedHeaderButtonIndex
'-------------------------------------------------------------------------------
function getFocusedHeaderButtonIndex() as integer
    headerButtons = m.focusableHeaderButtons
    if headerButtons = invalid then return -1

    for i = 0 to headerButtons.Count() - 1
        button = headerButtons[i]
        if button <> invalid and button.isInFocusChain() then return i
    end for

    if isLibraryMenuInFocusChain() and hasLibraryChoices() then return 0
    if m.logoutButton <> invalid and m.logoutButton.isInFocusChain() then return headerButtons.Count() - 1

    return -1
end function

'-------------------------------------------------------------------------------
' focusLibraryMenuButtonByOffset
'-------------------------------------------------------------------------------
function focusLibraryMenuButtonByOffset(offset as integer) as boolean
    if m.libraryMenuButtons = invalid or m.libraryMenuButtons.Count() = 0 then return false

    currentIndex = getFocusedLibraryMenuButtonIndex()
    if currentIndex < 0 then
        focusCurrentLibraryMenuButton()
        return true
    end if

    nextIndex = currentIndex + offset
    lastIndex = m.libraryMenuButtons.Count() - 1

    if nextIndex < 0 then
        nextIndex = lastIndex
    else if nextIndex > lastIndex then
        nextIndex = 0
    end if

    nextItem = m.libraryMenuButtons[nextIndex]
    if nextItem = invalid or nextItem.button = invalid then return false

    nextItem.button.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' onCloseMenuRequested
'-------------------------------------------------------------------------------
sub onCloseMenuRequested()
    closeMenu()
end sub

'-------------------------------------------------------------------------------
' onUsernameChanged
'-------------------------------------------------------------------------------
sub onUsernameChanged()
    updateUserMenuButton()
end sub

'-------------------------------------------------------------------------------
' onLibrariesChanged
'-------------------------------------------------------------------------------
sub onLibrariesChanged()
    updateCurrentLibraryButton()
    rebuildFocusableHeaderButtons()
    updateNavGroupPosition()
    rebuildLibraryMenu()
end sub

'-------------------------------------------------------------------------------
' onCurrentLibraryIdChanged
'-------------------------------------------------------------------------------
sub onCurrentLibraryIdChanged()
    updateCurrentLibraryButton()
    updateNavGroupPosition()
end sub

'-------------------------------------------------------------------------------
' onHomePressed
'-------------------------------------------------------------------------------
sub onHomePressed()
    closeMenu()
    setActiveHeaderButton("home")
    m.top.homeSelected = true
end sub

'-------------------------------------------------------------------------------
' onLibraryPressed
'-------------------------------------------------------------------------------
sub onLibraryPressed()
    closeMenu()
    setActiveHeaderButton("library")
    m.top.librarySelected = true
end sub

'-------------------------------------------------------------------------------
' onSeriesPressed
'-------------------------------------------------------------------------------
sub onSeriesPressed()
    closeMenu()
    setActiveHeaderButton("series")
    m.top.seriesSelected = true
end sub

'-------------------------------------------------------------------------------
' onSearchPressed
'-------------------------------------------------------------------------------
sub onSearchPressed()
    closeMenu()
    m.top.searchSelected = true
end sub

'-------------------------------------------------------------------------------
' onSettingsPressed
'-------------------------------------------------------------------------------
sub onSettingsPressed()
    closeMenu()
    m.top.overlayRequested = {
        id: "settings"
        componentName: "SettingsDialog"
        closeField: "closeRequested"
        openFunction: "openSettings"
    }
end sub

'-------------------------------------------------------------------------------
' onCurrentLibraryPressed
'-------------------------------------------------------------------------------
sub onCurrentLibraryPressed()
    if hasLibraryChoices() = false then return
    setLibraryMenuOpen(not isLibraryMenuOpen())
end sub

'-------------------------------------------------------------------------------
' setActiveHeaderButton
'-------------------------------------------------------------------------------
sub setActiveHeaderButton(activeButtonName as string)
    m.homeButton.isActive = (activeButtonName = "home")
    m.libraryButton.isActive = (activeButtonName = "library")
    m.seriesButton.isActive = (activeButtonName = "series")
    m.searchButton.isActive = (activeButtonName = "search")
    m.settingsButton.isActive = false
end sub

'-------------------------------------------------------------------------------
' onUserMenuPressed
'-------------------------------------------------------------------------------
sub onUserMenuPressed()
    setLibraryMenuOpen(false)
    setMenuOpen(not m.top.menuOpen)
    if m.top.menuOpen then m.logoutButton.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' onLogoutPressed
'-------------------------------------------------------------------------------
sub onLogoutPressed()
    closeMenu()
    m.top.logoutSelected = true
end sub

'-------------------------------------------------------------------------------
' closeMenu
'-------------------------------------------------------------------------------
sub closeMenu()

    wasLibraryMenuOpen = isLibraryMenuOpen()
    wasUserMenuOpen = m.top.menuOpen and wasLibraryMenuOpen = false
    
    setMenuOpen(false)
    setLibraryMenuOpen(false)
    
    if wasUserMenuOpen then
        m.userMenuButton.setFocus(true)
    else if wasLibraryMenuOpen then
        m.currentLibraryButton.setFocus(true)
    end if

end sub

'-------------------------------------------------------------------------------
' setMenuOpen
'-------------------------------------------------------------------------------
sub setMenuOpen(isOpen as boolean)
    if isOpen then setLibraryMenuOpen(false)
    m.top.menuOpen = isOpen
    if m.menuPanel <> invalid then m.menuPanel.visible = isOpen
end sub

'-------------------------------------------------------------------------------
' setLibraryMenuOpen
'-------------------------------------------------------------------------------
sub setLibraryMenuOpen(isOpen as boolean)
    if isOpen and hasLibraryChoices() = false then isOpen = false

    wasOpen = isLibraryMenuOpen()
    if isOpen then setMenuOpen(false)
    if m.libraryMenuPanel <> invalid then m.libraryMenuPanel.visible = isOpen
    if isOpen or wasOpen then m.top.menuOpen = isOpen

    if isOpen and m.libraryMenuButtons <> invalid and m.libraryMenuButtons.Count() > 0 then
        focusCurrentLibraryMenuButton()
    end if
end sub

'-------------------------------------------------------------------------------
' isLibraryMenuOpen
'-------------------------------------------------------------------------------
function isLibraryMenuOpen() as boolean
    return m.libraryMenuPanel <> invalid and m.libraryMenuPanel.visible = true
end function

'-------------------------------------------------------------------------------
' hasLibraryChoices
'-------------------------------------------------------------------------------
function hasLibraryChoices() as boolean
    return m.top.libraries <> invalid and m.top.libraries.Count() > 1
end function

'-------------------------------------------------------------------------------
' updateUserMenuButton
'-------------------------------------------------------------------------------
sub updateUserMenuButton()
    if m.userMenuButton = invalid then return

    ' leaving this here in case we ever go back to displaying the username
    'buttonText = FirstNonEmpty([m.top.username], "Account")
    'm.userMenuButton.text = buttonText
end sub

'-------------------------------------------------------------------------------
' updateCurrentLibraryButton
'-------------------------------------------------------------------------------
sub updateCurrentLibraryButton()
    if m.currentLibraryButton = invalid then return

    m.currentLibraryButton.text = getCurrentLibraryName()
    m.currentLibraryButton.visible = hasLibraryChoices()
end sub

'-------------------------------------------------------------------------------
' updateNavGroupPosition
'-------------------------------------------------------------------------------
sub updateNavGroupPosition()

    ' x,y translations for the navGroup based on whether we have multiple
    ' libraries (in which case the library button is displayed) or there
    ' is only one library (in which case the library button is not displayed)
    if hasLibraryChoices() then
        m.navGroup.translation = [632, 22]
    else
        m.navGroup.translation = [526, 22]
    end if

end sub

'-------------------------------------------------------------------------------
' getCurrentLibraryName
'-------------------------------------------------------------------------------
function getCurrentLibraryName() as string
    libraries = m.top.libraries
    if libraries <> invalid then
        for each library in libraries
            if library <> invalid and library.id = m.top.currentLibraryId then
                return FirstNonEmpty([library.name], "Library")
            end if
        end for

        if libraries.Count() > 0 and libraries[0] <> invalid then
            return FirstNonEmpty([libraries[0].name], "Library")
        end if
    end if

    return "Library"
end function

'-------------------------------------------------------------------------------
' rebuildLibraryMenu
'-------------------------------------------------------------------------------
sub rebuildLibraryMenu()
    if m.libraryMenuItems = invalid then return

    childCount = m.libraryMenuItems.getChildCount()
    if childCount > 0 then m.libraryMenuItems.removeChildrenIndex(childCount, 0)
    m.libraryMenuButtons = []

    libraries = m.top.libraries
    if libraries = invalid then return

    index = 0
    for each library in libraries
        if library <> invalid and library.id <> invalid then
            button = CreateObject("roSGNode", "HeaderButton")
            button.id = "libraryMenuButton" + index.ToStr()
            button.translation = [0, index * 66]
            button.buttonWidth = 300
            button.buttonHeight = 56
            button.textAlign = "left"
            button.textInset = 18
            button.text = FirstNonEmpty([library.name], "Library")
            button.headerBgColor = m.headerBg.color
            button.observeField("buttonSelected", "onLibraryMenuItemPressed")
            m.libraryMenuItems.appendChild(button)
            m.libraryMenuButtons.Push({
                button: button
                library: library
            })
            index = index + 1
        end if
    end for

    if m.libraryMenuBg <> invalid then m.libraryMenuBg.height = 36 + (index * 66)
end sub

'-------------------------------------------------------------------------------
' onLibraryMenuItemPressed
'-------------------------------------------------------------------------------
sub onLibraryMenuItemPressed()
    selectedLibrary = getFocusedLibraryMenuItem()
    if selectedLibrary = invalid then return

    setLibraryMenuOpen(false)
    m.currentLibraryButton.setFocus(true)

    m.top.currentLibrarySelected = {
        id: selectedLibrary.id
        name: selectedLibrary.name
    }
end sub

'-------------------------------------------------------------------------------
' getFocusedLibraryMenuItem
'-------------------------------------------------------------------------------
function getFocusedLibraryMenuItem() as dynamic
    if m.libraryMenuButtons = invalid then return invalid

    for each item in m.libraryMenuButtons
        if item <> invalid and item.button <> invalid and item.button.isInFocusChain() then
            return item.library
        end if
    end for

    return invalid
end function

'-------------------------------------------------------------------------------
' getFocusedLibraryMenuButtonIndex
'-------------------------------------------------------------------------------
function getFocusedLibraryMenuButtonIndex() as integer
    if m.libraryMenuButtons = invalid then return -1

    for i = 0 to m.libraryMenuButtons.Count() - 1
        item = m.libraryMenuButtons[i]
        if item <> invalid and item.button <> invalid and item.button.isInFocusChain() then return i
    end for

    return -1
end function

'-------------------------------------------------------------------------------
' focusCurrentLibraryMenuButton
'-------------------------------------------------------------------------------
sub focusCurrentLibraryMenuButton()
    if m.libraryMenuButtons = invalid then return

    fallbackButton = invalid
    for each item in m.libraryMenuButtons
        if item <> invalid and item.button <> invalid then
            if fallbackButton = invalid then fallbackButton = item.button
            if item.library <> invalid and item.library.id = m.top.currentLibraryId then
                item.button.setFocus(true)
                return
            end if
        end if
    end for

    if fallbackButton <> invalid then fallbackButton.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' isLibraryMenuInFocusChain
'-------------------------------------------------------------------------------
function isLibraryMenuInFocusChain() as boolean
    return getFocusedLibraryMenuItem() <> invalid
end function
