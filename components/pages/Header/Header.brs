'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initHandlers()

    m.homeSelectedCounter = 0
    m.librarySelectedCounter = 0
    m.seriesSelectedCounter = 0
    m.searchSelectedCounter = 0
    m.currentLibrarySelectedCounter = 0
    m.logoutSelectedCounter = 0
    m.downSelectedCounter = 0
    m.backSelectedCounter = 0
    m.overlayRequestedCounter = 0
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
    m.libraryMenuButtons = []
    m.headerButtons = [
        m.currentLibraryButton    
        m.homeButton
        m.libraryButton
        m.seriesButton
        m.searchButton
        m.settingsButton
        m.userMenuButton
    ]
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
    if m.usernameUpSequenceTimer <> invalid then m.usernameUpSequenceTimer.observeField("fire", "onUsernameUpSequenceTimerFired")
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    headerBgColor = palette.background.header
    if m.headerBg <> invalid then m.headerBg.color = headerBgColor

    if m.homeButton <> invalid then m.homeButton.headerBgColor = headerBgColor
    if m.libraryButton <> invalid then m.libraryButton.headerBgColor = headerBgColor
    if m.seriesButton <> invalid then m.seriesButton.headerBgColor = headerBgColor
    if m.searchButton <> invalid then m.searchButton.headerBgColor = headerBgColor
    if m.settingsButton <> invalid then m.settingsButton.headerBgColor = headerBgColor
    if m.currentLibraryButton <> invalid then m.currentLibraryButton.headerBgColor = headerBgColor
    if m.userMenuButton <> invalid then m.userMenuButton.headerBgColor = headerBgColor
    if m.logoutButton <> invalid then m.logoutButton.headerBgColor = headerBgColor
end sub

'-------------------------------------------------------------------------------
' focusHeader
'-------------------------------------------------------------------------------
function focusHeader() as boolean
    closeMenu()

    for each button in m.headerButtons
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
        m.downSelectedCounter = m.downSelectedCounter + 1
        m.top.downSelected = m.downSelectedCounter
        return true
    else if key = "back" then
        if m.top.menuOpen = true then
            closeMenu()
            return true
        end if

        closeMenu()
        m.backSelectedCounter = m.backSelectedCounter + 1
        m.top.backSelected = m.backSelectedCounter
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
        m.overlayRequestedCounter = m.overlayRequestedCounter + 1
        m.top.overlayRequested = {
            id: "diagnostics"
            componentName: "DiagnosticsDialog"
            closeField: "closeRequested"
            openFunction: "openDiagnostics"
            counter: m.overlayRequestedCounter
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
    if m.headerButtons = invalid or m.headerButtons.Count() = 0 then return false

    currentIndex = getFocusedHeaderButtonIndex()
    if currentIndex < 0 then
        return focusHeader()
    end if

    nextIndex = currentIndex + offset
    lastIndex = m.headerButtons.Count() - 1

    if nextIndex < 0 then
        nextIndex = lastIndex
    else if nextIndex > lastIndex then
        nextIndex = 0
    end if

    closeMenu()

    nextButton = m.headerButtons[nextIndex]
    if nextButton = invalid then return false

    nextButton.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' getFocusedHeaderButtonIndex
'-------------------------------------------------------------------------------
function getFocusedHeaderButtonIndex() as integer
    if m.currentLibraryButton <> invalid and m.currentLibraryButton.isInFocusChain() then return 0
    if isLibraryMenuInFocusChain() then return 0
    if m.homeButton <> invalid and m.homeButton.isInFocusChain() then return 1
    if m.libraryButton <> invalid and m.libraryButton.isInFocusChain() then return 2
    if m.seriesButton <> invalid and m.seriesButton.isInFocusChain() then return 3
    if m.searchButton <> invalid and m.searchButton.isInFocusChain() then return 4
    if m.settingsButton <> invalid and m.settingsButton.isInFocusChain() then return 5
    if m.userMenuButton <> invalid and m.userMenuButton.isInFocusChain() then return 6
    if m.logoutButton <> invalid and m.logoutButton.isInFocusChain() then return 6

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
' onCloseMenuTokenChanged
'-------------------------------------------------------------------------------
sub onCloseMenuTokenChanged()
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
    rebuildLibraryMenu()
end sub

'-------------------------------------------------------------------------------
' onCurrentLibraryIdChanged
'-------------------------------------------------------------------------------
sub onCurrentLibraryIdChanged()
    updateCurrentLibraryButton()
end sub

'-------------------------------------------------------------------------------
' onHomePressed
'-------------------------------------------------------------------------------
sub onHomePressed()
    closeMenu()
    setActiveHeaderButton("home")
    m.homeSelectedCounter = m.homeSelectedCounter + 1
    m.top.homeSelected = m.homeSelectedCounter
end sub

'-------------------------------------------------------------------------------
' onLibraryPressed
'-------------------------------------------------------------------------------
sub onLibraryPressed()
    closeMenu()
    setActiveHeaderButton("library")
    m.librarySelectedCounter = m.librarySelectedCounter + 1
    m.top.librarySelected = m.librarySelectedCounter
end sub

'-------------------------------------------------------------------------------
' onSeriesPressed
'-------------------------------------------------------------------------------
sub onSeriesPressed()
    closeMenu()
    setActiveHeaderButton("series")
    m.seriesSelectedCounter = m.seriesSelectedCounter + 1
    m.top.seriesSelected = m.seriesSelectedCounter
end sub

'-------------------------------------------------------------------------------
' onSearchPressed
'-------------------------------------------------------------------------------
sub onSearchPressed()
    closeMenu()
    m.searchSelectedCounter = m.searchSelectedCounter + 1
    m.top.searchSelected = m.searchSelectedCounter
end sub

'-------------------------------------------------------------------------------
' onSettingsPressed
'-------------------------------------------------------------------------------
sub onSettingsPressed()
    closeMenu()
    m.overlayRequestedCounter = m.overlayRequestedCounter + 1
    m.top.overlayRequested = {
        id: "settings"
        componentName: "SettingsDialog"
        closeField: "closeRequested"
        openFunction: "openSettings"
        counter: m.overlayRequestedCounter
    }
end sub

'-------------------------------------------------------------------------------
' onCurrentLibraryPressed
'-------------------------------------------------------------------------------
sub onCurrentLibraryPressed()
    setLibraryMenuOpen(not isLibraryMenuOpen())
end sub

'-------------------------------------------------------------------------------
' setActiveHeaderButton
'-------------------------------------------------------------------------------
sub setActiveHeaderButton(activeButtonName as string)
    if m.homeButton <> invalid then m.homeButton.isActive = (activeButtonName = "home")
    if m.libraryButton <> invalid then m.libraryButton.isActive = (activeButtonName = "library")
    if m.seriesButton <> invalid then m.seriesButton.isActive = (activeButtonName = "series")
    if m.searchButton <> invalid then m.searchButton.isActive = (activeButtonName = "search")
    if m.settingsButton <> invalid then m.settingsButton.isActive = false
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
    m.logoutSelectedCounter = m.logoutSelectedCounter + 1
    m.top.logoutSelected = m.logoutSelectedCounter
end sub

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
' updateUserMenuButton
'-------------------------------------------------------------------------------
sub updateUserMenuButton()
    if m.userMenuButton = invalid then return

    buttonText = FirstNonEmpty([m.top.username], "Account")
    m.userMenuButton.text = buttonText
end sub

'-------------------------------------------------------------------------------
' updateCurrentLibraryButton
'-------------------------------------------------------------------------------
sub updateCurrentLibraryButton()
    if m.currentLibraryButton = invalid then return

    m.currentLibraryButton.text = getCurrentLibraryName()
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

    m.currentLibrarySelectedCounter = m.currentLibrarySelectedCounter + 1
    m.top.currentLibrarySelected = {
        id: selectedLibrary.id
        name: selectedLibrary.name
        counter: m.currentLibrarySelectedCounter
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
