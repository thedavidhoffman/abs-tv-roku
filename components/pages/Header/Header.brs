'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initHandlers()

    m.logoutSelectedCounter = 0
    m.changeServerSelectedCounter = 0

    initStyle()
    setMenuOpen(false)
    setLibraryMenuOpen(false)
    updateLibraryList()
    updateLibraryButton()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.headerBg = m.top.findNode("headerBg")
    m.libraryButton = m.top.findNode("libraryButton")
    m.libraryList = m.top.findNode("libraryList")
    m.userMenuButton = m.top.findNode("userMenuButton")
    m.menuPanel = m.top.findNode("menuPanel")
    m.logoutButton = m.top.findNode("logoutButton")
    m.changeServerButton = m.top.findNode("changeServerButton")
    m.headerButtons = [
        m.libraryButton
        m.userMenuButton
    ]
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.libraryButton.observeField("buttonSelected", "onLibraryButtonPressed")
    m.libraryList.observeField("itemSelected", "onLibraryItemSelected")
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

    if m.libraryButton <> invalid then m.libraryButton.headerBgColor = headerBgColor
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
    if m.libraryButton <> invalid and m.libraryButton.isInFocusChain() then return 0
    if m.libraryList <> invalid and m.libraryList.isInFocusChain() then return 0
    if m.userMenuButton <> invalid and m.userMenuButton.isInFocusChain() then return 1
    if m.logoutButton <> invalid and m.logoutButton.isInFocusChain() then return 1
    if m.changeServerButton <> invalid and m.changeServerButton.isInFocusChain() then return 1

    return -1
end function

'-------------------------------------------------------------------------------
' onCloseMenuTokenChanged
'-------------------------------------------------------------------------------
sub onCloseMenuTokenChanged()
    closeMenu()
end sub

'-------------------------------------------------------------------------------
' onLibrariesChanged
'-------------------------------------------------------------------------------
sub onLibrariesChanged()
    updateLibraryList()
    updateLibraryButton()
end sub

'-------------------------------------------------------------------------------
' onCurrentLibraryIdChanged
'-------------------------------------------------------------------------------
sub onCurrentLibraryIdChanged()
    updateLibraryButton()
end sub

'-------------------------------------------------------------------------------
' onLibraryButtonPressed
'-------------------------------------------------------------------------------
sub onLibraryButtonPressed()
    libraries = m.top.libraries
    if libraries = invalid or libraries.Count() = 0 then return

    nextOpen = not m.libraryMenuOpen
    setMenuOpen(false)
    setLibraryMenuOpen(nextOpen)
    if nextOpen then m.libraryList.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' onLibraryItemSelected
'-------------------------------------------------------------------------------
sub onLibraryItemSelected()
    libraries = m.top.libraries
    selectedIndex = m.libraryList.itemSelected
    if libraries = invalid or selectedIndex = invalid then return
    if selectedIndex < 0 or selectedIndex >= libraries.Count() then return

    library = libraries[selectedIndex]
    if library = invalid then return

    m.top.currentLibraryId = library.id
    setLibraryMenuOpen(false)
    updateLibraryButton()
    m.libraryButton.setFocus(true)
    m.top.librarySelected = {
        id: library.id
        name: library.name
    }
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
    wasLibraryOpen = m.libraryMenuOpen
    setMenuOpen(false)
    setLibraryMenuOpen(false)
    if wasOpen then
        m.userMenuButton.setFocus(true)
    else if wasLibraryOpen then
        m.libraryButton.setFocus(true)
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
' setLibraryMenuOpen
'-------------------------------------------------------------------------------
sub setLibraryMenuOpen(isOpen as boolean)
    m.libraryMenuOpen = isOpen
    if m.libraryList <> invalid then m.libraryList.visible = isOpen
    m.top.menuOpen = (isOpen or (m.menuPanel <> invalid and m.menuPanel.visible))
end sub

'-------------------------------------------------------------------------------
' updateLibraryList
'-------------------------------------------------------------------------------
sub updateLibraryList()
    if m.libraryList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    libraries = m.top.libraries
    if libraries <> invalid then
        for each library in libraries
            node = CreateObject("roSGNode", "ContentNode")
            node.title = SafeString(library.name, "Library")
            root.appendChild(node)
        end for
    end if

    m.libraryList.content = root
end sub

'-------------------------------------------------------------------------------
' updateLibraryButton
'-------------------------------------------------------------------------------
sub updateLibraryButton()
    if m.libraryButton = invalid then return

    buttonText = "Library"
    libraries = m.top.libraries
    if libraries <> invalid then
        for each library in libraries
            if library.id = m.top.currentLibraryId then
                buttonText = SafeString(library.name, buttonText)
                exit for
            end if
        end for
    end if

    m.libraryButton.text = buttonText
end sub
