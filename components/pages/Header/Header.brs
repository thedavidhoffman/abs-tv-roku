'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initHandlers()

    m.logoutSelectedCounter = 0
    m.changeServerSelectedCounter = 0
    m.settingsSelectedCounter = 0
    m.downSelectedCounter = 0

    initStyle()
    updateUserMenuButton()
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
    m.changeServerButton = m.top.findNode("changeServerButton")
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
    m.settingsButton.observeField("buttonSelected", "onSettingsPressed")
    m.userMenuButton.observeField("buttonSelected", "onUserMenuPressed")
    m.logoutButton.observeField("buttonSelected", "onLogoutPressed")
    m.changeServerButton.observeField("buttonSelected", "onChangeServerPressed")
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
    if m.changeServerButton <> invalid then m.changeServerButton.headerBgColor = headerBgColor
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
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "left" then
        return focusHeaderButtonByOffset(-1)
    else if key = "right" then
        return focusHeaderButtonByOffset(1)
    else if key = "down" then
        closeMenu()
        m.downSelectedCounter = m.downSelectedCounter + 1
        m.top.downSelected = m.downSelectedCounter
        return true
    end if

    return false
end function

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
    if m.changeServerButton <> invalid and m.changeServerButton.isInFocusChain() then return 4

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
' onSettingsPressed
'-------------------------------------------------------------------------------
sub onSettingsPressed()
    closeMenu()
    m.settingsSelectedCounter = m.settingsSelectedCounter + 1
    m.top.settingsSelected = m.settingsSelectedCounter
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

'-------------------------------------------------------------------------------
' onChangeServerPressed
'-------------------------------------------------------------------------------
sub onChangeServerPressed()
    closeMenu()
    m.changeServerSelectedCounter = m.changeServerSelectedCounter + 1
    m.top.changeServerSelected = m.changeServerSelectedCounter
end sub

'-------------------------------------------------------------------------------
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
