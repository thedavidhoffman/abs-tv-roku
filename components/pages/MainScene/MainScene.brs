'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.bg = m.top.findNode("bg")
    m.login = m.top.findNode("login")
    m.authenticatedContent = m.top.findNode("authenticatedContent")
    m.header = m.top.findNode("header")
    m.homePage = m.top.findNode("homePage")
    m.library = m.top.findNode("library")
    m.player = m.top.findNode("player")
    m.continueGrid = m.top.findNode("continueGrid")
    m.recentGrid = m.top.findNode("recentGrid")
    m.seriesGrid = m.top.findNode("seriesGrid")
    m.apiTask = m.top.findNode("apiTask")

    m.login.observeField("loginSucceeded", "onLoginSucceeded")
    m.header.observeField("booksSelected", "onBooksTabPressed")
    m.header.observeField("seriesSelected", "onSeriesTabPressed")
    m.header.observeField("librarySelected", "onLibrarySelected")
    m.header.observeField("logoutSelected", "onLogoutPressed")
    m.header.observeField("changeServerSelected", "onChangeServerPressed")
    m.library.observeField("errorResponse", "onLibraryError")
    m.library.observeField("playSelected", "onLibraryPlaySelected")
    m.player.observeField("closeRequested", "onPlayerCloseRequested")
    m.player.observeField("errorResponse", "onPlayerError")
    m.apiTask.observeField("response", "onApiResponse")

    m.currentTab = "books"
    m.session = LoadAuthState()
    m.isLoadingBooks = false
    m.isLoadingSeries = false
    m.isResumingSession = false
    m.loginActivationCounter = 0

    preloadSavedFields()
    initStyle()
    styleTabs()
    tryResumeSession()
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    if m.bg <> invalid then m.bg.color = palette.background.secondary
end sub

'-------------------------------------------------------------------------------
' preloadSavedFields
'-------------------------------------------------------------------------------
sub preloadSavedFields()
    if m.session.server <> invalid and TrimString(m.session.server) <> "" then
        m.login.serverValue = m.session.server
    end if
    if m.session.username <> invalid and TrimString(m.session.username) <> "" then
        m.login.usernameValue = m.session.username
    end if
end sub

'-------------------------------------------------------------------------------
' tryResumeSession
'-------------------------------------------------------------------------------
sub tryResumeSession()
    if m.session.token <> invalid and m.session.token <> "" and m.session.server <> invalid and m.session.server <> "" then
        m.isResumingSession = true
        m.login.visible = false
        m.authenticatedContent.visible = false
        m.apiTask.request = {
            action: "authorize"
            server: m.session.server
            token: m.session.token
        }
        m.apiTask.control = "run"
    else
        showLogin("Enter your Audiobookshelf server to begin.")
    end if
end sub

'-------------------------------------------------------------------------------
' onLoginSucceeded
'-------------------------------------------------------------------------------
sub onLoginSucceeded()
    response = m.login.loginSucceeded
    if response = invalid then return

    storeAuthenticatedSession(response)
    showApp()
end sub

'-------------------------------------------------------------------------------
' onApiResponse
'-------------------------------------------------------------------------------
sub onApiResponse()
    response = m.apiTask.response
    if response = invalid then return

    if response.ok <> true then
        if m.isResumingSession then
            m.isResumingSession = false
            ClearAuthState(false)
            showLogin("Your saved session expired. Please sign in again.")
            return
        end if

        if response.authExpired = true then
            handleExpiredSession(response.errorMessage)
            return
        end if

        if m.login.visible then
            m.login.statusMessage = "Login failed: " + SafeString(response.errorMessage, "Unknown error.")
        else
            m.homePage.statusMessage = response.errorMessage
        end if
        return
    end if

    action = response.action
    if action = "authorize" then
        m.isResumingSession = false
        storeAuthenticatedSession(response)
        showApp()
        return
    end if

    if action = "loadBooks" then
        m.session.bookLibraryId = response.bookLibraryId
        populateContinueGrid(response.continueListening)
        populateRecentGrid(response.recentlyAdded)
        m.isLoadingBooks = false
        if m.currentTab = "books" then
            m.homePage.statusMessage = ""
            m.continueGrid.setFocus(true)
        end if
        return
    end if

    if action = "loadSeries" then
        m.session.bookLibraryId = response.bookLibraryId
        populateSeriesGrid(response.series)
        m.isLoadingSeries = false
        if m.currentTab = "series" then
            m.homePage.statusMessage = ""
            m.seriesGrid.setFocus(true)
        end if
        return
    end if
end sub

'-------------------------------------------------------------------------------
' showLogin
'-------------------------------------------------------------------------------
sub showLogin(message as string)
    m.login.visible = true
    m.authenticatedContent.visible = false
    closeHeaderMenu()
    m.login.statusMessage = message
    m.loginActivationCounter = m.loginActivationCounter + 1
    m.login.activationToken = m.loginActivationCounter
end sub

'-------------------------------------------------------------------------------
' storeAuthenticatedSession
'-------------------------------------------------------------------------------
sub storeAuthenticatedSession(response as object)
    m.session = Session_BuildAuthenticatedSession(response)
    Session_SaveAuthenticatedSession(m.session)
end sub

'-------------------------------------------------------------------------------
' onLibraryError
'-------------------------------------------------------------------------------
sub onLibraryError()
    response = m.library.errorResponse
    if response = invalid then return

    if response.authExpired = true then
        handleExpiredSession(response.errorMessage)
    end if
end sub

'-------------------------------------------------------------------------------
' showApp
'-------------------------------------------------------------------------------
sub showApp()
    m.login.visible = false
    m.authenticatedContent.visible = true
    closeHeaderMenu()
    if m.header <> invalid then
        m.header.visible = true
        m.header.libraries = m.session.libraries
        if m.session.bookLibraryId <> invalid then m.header.currentLibraryId = m.session.bookLibraryId
    end if
    if m.library <> invalid then
        m.library.visible = true
        m.library.loadRequest = {
            server: m.session.server
            token: m.session.token
            bookLibraryId: m.session.bookLibraryId
        }
    end if
    if m.homePage <> invalid then m.homePage.visible = false
    m.homePage.pageTitle = "Books"
    m.homePage.pageSubtitle = "Pick up right where you left off and see what arrived most recently."
    m.homePage.currentTab = "books"
    styleTabs()
end sub

'-------------------------------------------------------------------------------
' onLibrarySelected
'-------------------------------------------------------------------------------
sub onLibrarySelected()
    selectedLibrary = m.header.librarySelected
    if selectedLibrary = invalid or selectedLibrary.id = invalid then return
    if m.session = invalid then return

    m.session.bookLibraryId = selectedLibrary.id

    if m.library <> invalid and m.library.visible then
        m.library.loadRequest = {
            server: m.session.server
            token: m.session.token
            bookLibraryId: m.session.bookLibraryId
        }
    end if

    if m.homePage <> invalid and m.homePage.visible then
        if m.currentTab = "series" then
            loadSeries()
        else
            loadBooks()
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' onLibraryPlaySelected
'-------------------------------------------------------------------------------
sub onLibraryPlaySelected()
    selectedItem = m.library.playSelected
    if selectedItem = invalid or selectedItem.id = invalid then return
    if m.session = invalid then return

    coverUrl = buildCoverUrl(selectedItem.id)
    m.authenticatedContent.visible = false
    m.player.visible = true
    m.player.setFocus(true)
    m.player.playRequest = {
        server: m.session.server
        token: m.session.token
        itemId: selectedItem.id
        title: selectedItem.title
        coverUrl: coverUrl
        details: selectedItem.details
    }
end sub

'-------------------------------------------------------------------------------
' onPlayerCloseRequested
'-------------------------------------------------------------------------------
sub onPlayerCloseRequested()
    m.player.visible = false
    m.authenticatedContent.visible = true
    if m.library <> invalid and m.library.visible then
        m.library.callFunc("focusLibraryList")
    end if
end sub

'-------------------------------------------------------------------------------
' onPlayerError
'-------------------------------------------------------------------------------
sub onPlayerError()
    response = m.player.errorResponse
    if response = invalid then return

    if response.authExpired = true then
        onPlayerCloseRequested()
        handleExpiredSession(response.errorMessage)
    end if
end sub

'-------------------------------------------------------------------------------
' loadBooks
'-------------------------------------------------------------------------------
sub loadBooks()
    if m.session = invalid then return
    m.isLoadingBooks = true
    m.currentTab = "books"
    m.homePage.currentTab = "books"
    m.homePage.pageTitle = "Books"
    m.homePage.pageSubtitle = "Pick up right where you left off and see what arrived most recently."
    styleTabs()
    m.homePage.statusMessage = "Loading your listening activity and newest arrivals..."
    m.apiTask.request = {
        action: "loadBooks"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    }
    m.apiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' loadSeries
'-------------------------------------------------------------------------------
sub loadSeries()
    if m.session = invalid then return
    m.isLoadingSeries = true
    m.currentTab = "series"
    m.homePage.currentTab = "series"
    m.homePage.pageTitle = "Series"
    m.homePage.pageSubtitle = "Browse your audiobook series in a clean, artwork-first layout."
    styleTabs()
    m.homePage.statusMessage = "Loading series..."
    m.apiTask.request = {
        action: "loadSeries"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    }
    m.apiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' populateContinueGrid
'-------------------------------------------------------------------------------
sub populateContinueGrid(payload as dynamic)
    root = CreateObject("roSGNode", "ContentNode")
    items = invalid
    if payload <> invalid and payload.libraryItems <> invalid then items = payload.libraryItems

    if items <> invalid then
        for each item in items
            if item.mediaType = "book" then
                progress = invalid
                if item.mediaProgress <> invalid then progress = item.mediaProgress
                if progress = invalid and item.userMediaProgress <> invalid then progress = item.userMediaProgress

                remainingSeconds = invalid
                if progress <> invalid and progress.duration <> invalid and progress.currentTime <> invalid then
                    remainingSeconds = progress.duration - progress.currentTime
                else if item.media <> invalid and item.media.duration <> invalid then
                    remainingSeconds = item.media.duration
                end if

                node = CreateObject("roSGNode", "ContentNode")
                title = "Untitled"
                if item.media <> invalid and item.media.metadata <> invalid then
                    title = FirstNonEmpty([item.media.metadata.title], title)
                end if
                node.title = title
                node.subtitle = FormatRemainingTime(remainingSeconds)
                node.hdPosterUrl = buildCoverUrl(item.id)
                node.sdPosterUrl = node.hdPosterUrl
                root.appendChild(node)
            end if
        end for
    end if

    if root.getChildCount() = 0 then
        root.appendChild(makePlaceholderNode("Nothing in progress yet", "Start a book on Audiobookshelf and it will appear here."))
    end if

    m.continueGrid.content = root
end sub

'-------------------------------------------------------------------------------
' populateRecentGrid
'-------------------------------------------------------------------------------
sub populateRecentGrid(payload as dynamic)
    root = CreateObject("roSGNode", "ContentNode")
    results = invalid
    if payload <> invalid and payload.results <> invalid then results = payload.results

    if results <> invalid then
        for each item in results
            if item.mediaType = "book" then
                node = CreateObject("roSGNode", "ContentNode")
                author = ""
                title = "Untitled"
                if item.media <> invalid and item.media.metadata <> invalid then
                    author = FirstNonEmpty([item.media.metadata.authorName, item.media.metadata.author], "")
                    title = FirstNonEmpty([item.media.metadata.title], title)
                end if
                node.title = title
                node.subtitle = author
                node.hdPosterUrl = buildCoverUrl(item.id)
                node.sdPosterUrl = node.hdPosterUrl
                root.appendChild(node)
            end if
        end for
    end if

    if root.getChildCount() = 0 then
        root.appendChild(makePlaceholderNode("No books found", "Your most recent audiobooks will appear here."))
    end if

    m.recentGrid.content = root
end sub

'-------------------------------------------------------------------------------
' populateSeriesGrid
'-------------------------------------------------------------------------------
sub populateSeriesGrid(payload as dynamic)
    root = CreateObject("roSGNode", "ContentNode")
    results = invalid
    if payload <> invalid and payload.results <> invalid then results = payload.results

    if results <> invalid then
        for each series in results
            node = CreateObject("roSGNode", "ContentNode")
            node.title = FirstNonEmpty([series.name], "Untitled Series")
            node.subtitle = SafeString(series.numBooks, "0") + " books"
            if series.books <> invalid and series.books.Count() > 0 then
                firstBook = series.books[0]
                node.hdPosterUrl = buildCoverUrl(firstBook.id)
                node.sdPosterUrl = node.hdPosterUrl
            end if
            root.appendChild(node)
        end for
    end if

    if root.getChildCount() = 0 then
        root.appendChild(makePlaceholderNode("No series available", "Series data will appear here when your library includes it."))
    end if

    m.seriesGrid.content = root
end sub

'-------------------------------------------------------------------------------
' makePlaceholderNode
'-------------------------------------------------------------------------------
function makePlaceholderNode(title as string, subtitle as string) as object
    node = CreateObject("roSGNode", "ContentNode")
    node.title = title
    node.subtitle = subtitle
    node.hdPosterUrl = "pkg:/images/placeholder_cover.png"
    node.sdPosterUrl = node.hdPosterUrl
    return node
end function

'-------------------------------------------------------------------------------
' buildCoverUrl
'-------------------------------------------------------------------------------
function buildCoverUrl(itemId as dynamic) as string
    if m.session = invalid or m.session.server = invalid or m.session.token = invalid or itemId = invalid then
        return "pkg:/images/placeholder_cover.png"
    end if
    return m.session.server + "/api/items/" + itemId.ToStr() + "/cover?width=400&token=" + m.session.token
end function

'-------------------------------------------------------------------------------
' handleExpiredSession
'-------------------------------------------------------------------------------
sub handleExpiredSession(message as string)
    ClearAuthState(false)
    if m.session <> invalid then m.session.token = ""
    m.login.passwordValue = ""
    showLogin(message)
end sub

'-------------------------------------------------------------------------------
' onBooksTabPressed
'-------------------------------------------------------------------------------
sub onBooksTabPressed()
    if m.currentTab <> "books" or m.isLoadingBooks then
        loadBooks()
    else
        m.continueGrid.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' onSeriesTabPressed
'-------------------------------------------------------------------------------
sub onSeriesTabPressed()
    if m.currentTab <> "series" or m.isLoadingSeries then
        loadSeries()
    else
        m.seriesGrid.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' onLogoutPressed
'-------------------------------------------------------------------------------
sub onLogoutPressed()
    if m.session <> invalid and m.session.server <> invalid and m.session.token <> invalid and m.session.token <> "" then
        m.apiTask.request = {
            action: "logout"
            server: m.session.server
            token: m.session.token
        }
        m.apiTask.control = "run"
    end if

    ClearAuthState(false)
    if m.session <> invalid then m.session.token = ""
    m.login.passwordValue = ""
    closeHeaderMenu()
    showLogin("Signed out.")
end sub

'-------------------------------------------------------------------------------
' onChangeServerPressed
'-------------------------------------------------------------------------------
sub onChangeServerPressed()

    m.session = LoadAuthState()
    m.login.serverValue = ""
    m.login.usernameValue = ""
    m.login.passwordValue = ""
    closeHeaderMenu()
    showLogin("Enter a new server address to continue.")
end sub

'-------------------------------------------------------------------------------
' styleTabs
'-------------------------------------------------------------------------------
sub styleTabs()
    if m.header <> invalid then m.header.currentTab = m.currentTab
end sub

'-------------------------------------------------------------------------------
' closeHeaderMenu
'-------------------------------------------------------------------------------
sub closeHeaderMenu()
    if m.header = invalid then return

    if m.closeHeaderMenuToken = invalid then m.closeHeaderMenuToken = 0
    m.closeHeaderMenuToken = m.closeHeaderMenuToken + 1
    m.header.closeMenuToken = m.closeHeaderMenuToken
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if m.player <> invalid and m.player.visible then
        return false
    end if

    if m.header <> invalid and m.header.menuOpen and key = "back" then
        closeHeaderMenu()
        return true
    end if

    if not m.login.visible and key = "back" then
        if m.header <> invalid and m.header.visible and not m.header.isInFocusChain() then
            if m.header.callFunc("focusHeader") then return true
        end if

        if m.currentTab = "series" then
            loadBooks()
            return true
        end if
    end if

    return false
end function
