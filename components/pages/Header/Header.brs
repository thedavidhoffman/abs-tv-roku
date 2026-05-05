'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initHandlers()

    m.homeSelectedCounter = 0
    m.librarySelectedCounter = 0
    m.searchSelectedCounter = 0
    m.logoutSelectedCounter = 0
    m.downSelectedCounter = 0
    m.backSelectedCounter = 0
    m.overlayRequestedCounter = 0
    m.usernameUpPressCount = 0

    initStyle()
    updateUserMenuButton()
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
    m.searchButton = m.top.findNode("searchButton")
    m.settingsButton = m.top.findNode("settingsButton")
    m.userMenuButton = m.top.findNode("userMenuButton")
    m.menuPanel = m.top.findNode("menuPanel")
    m.logoutButton = m.top.findNode("logoutButton")
    m.usernameUpSequenceTimer = m.top.findNode("usernameUpSequenceTimer")
    m.headerButtons = [
        m.homeButton
        m.libraryButton
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
    m.searchButton.observeField("buttonSelected", "onSearchPressed")
    m.settingsButton.observeField("buttonSelected", "onSettingsPressed")
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
    if m.searchButton <> invalid then m.searchButton.headerBgColor = headerBgColor
    if m.settingsButton <> invalid then m.settingsButton.headerBgColor = headerBgColor
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
    if m.homeButton <> invalid and m.homeButton.isInFocusChain() then return 0
    if m.libraryButton <> invalid and m.libraryButton.isInFocusChain() then return 1
    if m.searchButton <> invalid and m.searchButton.isInFocusChain() then return 2
    if m.settingsButton <> invalid and m.settingsButton.isInFocusChain() then return 3
    if m.userMenuButton <> invalid and m.userMenuButton.isInFocusChain() then return 4
    if m.logoutButton <> invalid and m.logoutButton.isInFocusChain() then return 4

    return -1
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
' onSearchPressed
'-------------------------------------------------------------------------------
sub onSearchPressed()
    closeMenu()
    setActiveHeaderButton("search")
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
' setActiveHeaderButton
'-------------------------------------------------------------------------------
sub setActiveHeaderButton(activeButtonName as string)
    if m.homeButton <> invalid then m.homeButton.isActive = (activeButtonName = "home")
    if m.libraryButton <> invalid then m.libraryButton.isActive = (activeButtonName = "library")
    if m.searchButton <> invalid then m.searchButton.isActive = (activeButtonName = "search")
    if m.settingsButton <> invalid then m.settingsButton.isActive = false
end sub

'-------------------------------------------------------------------------------
' onUserMenuPressed
'-------------------------------------------------------------------------------
sub onUserMenuPressed()
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
    wasOpen = m.top.menuOpen
    setMenuOpen(false)
    if wasOpen then
        m.userMenuButton.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' setMenuOpen
'-------------------------------------------------------------------------------
sub setMenuOpen(isOpen as boolean)
    m.top.menuOpen = isOpen
    if m.menuPanel <> invalid then m.menuPanel.visible = isOpen
end sub

'-------------------------------------------------------------------------------
' updateUserMenuButton
'-------------------------------------------------------------------------------
sub updateUserMenuButton()
    if m.userMenuButton = invalid then return

    buttonText = FirstNonEmpty([m.top.username], "Account")
    m.userMenuButton.text = buttonText
end sub
