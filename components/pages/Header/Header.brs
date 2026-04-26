'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initHandlers()

    m.booksSelectedCounter = 0
    m.seriesSelectedCounter = 0
    m.logoutSelectedCounter = 0
    m.changeServerSelectedCounter = 0

    if m.top.currentTab = invalid or m.top.currentTab = "" then m.top.currentTab = "books"
    initStyle()
    setMenuOpen(false)
    setLibraryMenuOpen(false)
    updateLibraryList()
    updateLibraryButton()
    styleTabs()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.headerBg = m.top.findNode("headerBg")
    m.booksTab = m.top.findNode("booksTab")
    m.seriesTab = m.top.findNode("seriesTab")
    m.libraryButton = m.top.findNode("libraryButton")
    m.libraryList = m.top.findNode("libraryList")
    m.userMenuButton = m.top.findNode("userMenuButton")
    m.menuPanel = m.top.findNode("menuPanel")
    m.logoutButton = m.top.findNode("logoutButton")
    m.changeServerButton = m.top.findNode("changeServerButton")
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.booksTab.observeField("buttonSelected", "onBooksTabPressed")
    m.seriesTab.observeField("buttonSelected", "onSeriesTabPressed")
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
    if m.headerBg <> invalid then m.headerBg.color = palette.background.primary
end sub

'-------------------------------------------------------------------------------
' onCurrentTabChanged
'-------------------------------------------------------------------------------
sub onCurrentTabChanged()
    styleTabs()
end sub

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
' onBooksTabPressed
'-------------------------------------------------------------------------------
sub onBooksTabPressed()
    m.booksSelectedCounter = m.booksSelectedCounter + 1
    m.top.booksSelected = m.booksSelectedCounter
end sub

'-------------------------------------------------------------------------------
' onSeriesTabPressed
'-------------------------------------------------------------------------------
sub onSeriesTabPressed()
    m.seriesSelectedCounter = m.seriesSelectedCounter + 1
    m.top.seriesSelected = m.seriesSelectedCounter
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

'-------------------------------------------------------------------------------
' styleTabs
'-------------------------------------------------------------------------------
sub styleTabs()
    if m.top.currentTab = "series" then
        m.booksTab.text = "Books"
        m.seriesTab.text = "Series *"
    else
        m.booksTab.text = "Books *"
        m.seriesTab.text = "Series"
    end if
end sub
