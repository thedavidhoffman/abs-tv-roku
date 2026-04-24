sub init()
    m.gettingStartedPage = m.top.findNode("gettingStartedPage")
    m.authenticatedContent = m.top.findNode("authenticatedContent")
    m.headerPanel = m.top.findNode("headerPanel")
    m.homePage = m.top.findNode("homePage")
    m.booksTab = m.top.findNode("booksTab")
    m.seriesTab = m.top.findNode("seriesTab")
    m.userMenuButton = m.top.findNode("userMenuButton")
    m.menuPanel = m.top.findNode("menuPanel")
    m.logoutButton = m.top.findNode("logoutButton")
    m.changeServerButton = m.top.findNode("changeServerButton")
    m.continueGrid = m.top.findNode("continueGrid")
    m.recentGrid = m.top.findNode("recentGrid")
    m.seriesGrid = m.top.findNode("seriesGrid")
    m.apiTask = m.top.findNode("apiTask")

    m.gettingStartedPage.observeField("loginRequested", "onLoginRequested")
    m.booksTab.observeField("buttonSelected", "onBooksTabPressed")
    m.seriesTab.observeField("buttonSelected", "onSeriesTabPressed")
    m.userMenuButton.observeField("buttonSelected", "onUserMenuPressed")
    m.logoutButton.observeField("buttonSelected", "onLogoutPressed")
    m.changeServerButton.observeField("buttonSelected", "onChangeServerPressed")
    m.apiTask.observeField("response", "onApiResponse")

    m.currentTab = "books"
    m.session = LoadAuthState()
    m.isLoadingBooks = false
    m.isLoadingSeries = false
    m.loginActivationCounter = 0

    preloadSavedFields()
    styleTabs()
    tryResumeSession()
end sub

sub preloadSavedFields()
    if m.session.server <> invalid and TrimString(m.session.server) <> "" then
        m.gettingStartedPage.serverValue = m.session.server
    end if
    if m.session.username <> invalid and TrimString(m.session.username) <> "" then
        m.gettingStartedPage.usernameValue = m.session.username
    end if
end sub

sub tryResumeSession()
    if m.session.token <> invalid and m.session.token <> "" and m.session.server <> invalid and m.session.server <> "" then
        m.gettingStartedPage.statusMessage = "Restoring your listening session..."
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

sub onLoginRequested()
    request = m.gettingStartedPage.loginRequested
    if request = invalid then return

    m.apiTask.request = {
        action: "login"
        server: request.server
        username: request.username
        password: request.password
    }
    m.apiTask.control = "run"
end sub

sub onApiResponse()
    response = m.apiTask.response
    if response = invalid then return

    if response.ok <> true then
        if response.authExpired = true then
            handleExpiredSession(response.errorMessage)
            return
        end if

        if m.gettingStartedPage.visible then
            m.gettingStartedPage.statusMessage = "Login failed: " + SafeString(response.errorMessage, "Unknown error.")
        else
            m.homePage.statusMessage = response.errorMessage
        end if
        return
    end if

    action = response.action
    if action = "login" or action = "authorize" then
        payload = response.payload
        sessionToken = payload.user.token
        server = response.server
        username = payload.user.username
        userId = payload.user.id

        m.session = {
            server: server
            username: username
            token: sessionToken
            userId: userId
            bookLibraryId: ResolveBookLibraryId(payload)
        }

        SaveAuthState(server, username, sessionToken, userId)
        showApp()
        loadBooks()
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

sub showLogin(message as string)
    m.gettingStartedPage.visible = true
    m.authenticatedContent.visible = false
    m.menuPanel.visible = false
    m.gettingStartedPage.statusMessage = message
    m.loginActivationCounter = m.loginActivationCounter + 1
    m.gettingStartedPage.activationToken = m.loginActivationCounter
end sub

sub showApp()
    m.gettingStartedPage.visible = false
    m.authenticatedContent.visible = true
    m.menuPanel.visible = false
    m.homePage.pageTitle = "Books"
    m.homePage.pageSubtitle = "Pick up right where you left off and see what arrived most recently."
    m.homePage.currentTab = "books"
    styleTabs()
end sub

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

function makePlaceholderNode(title as string, subtitle as string) as object
    node = CreateObject("roSGNode", "ContentNode")
    node.title = title
    node.subtitle = subtitle
    node.hdPosterUrl = "pkg:/images/placeholder_cover.png"
    node.sdPosterUrl = node.hdPosterUrl
    return node
end function

function buildCoverUrl(itemId as dynamic) as string
    if m.session = invalid or m.session.server = invalid or m.session.token = invalid or itemId = invalid then
        return "pkg:/images/placeholder_cover.png"
    end if
    return m.session.server + "/api/items/" + itemId.ToStr() + "/cover?width=400&token=" + m.session.token
end function

sub handleExpiredSession(message as string)
    ClearAuthState(false)
    if m.session <> invalid then m.session.token = ""
    m.gettingStartedPage.passwordValue = ""
    showLogin(message)
end sub

sub onBooksTabPressed()
    if m.currentTab <> "books" or m.isLoadingBooks then
        loadBooks()
    else
        m.continueGrid.setFocus(true)
    end if
end sub

sub onSeriesTabPressed()
    if m.currentTab <> "series" or m.isLoadingSeries then
        loadSeries()
    else
        m.seriesGrid.setFocus(true)
    end if
end sub

sub onUserMenuPressed()
    m.menuPanel.visible = not m.menuPanel.visible
    if m.menuPanel.visible then
        m.logoutButton.setFocus(true)
    end if
end sub

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
    m.gettingStartedPage.passwordValue = ""
    m.menuPanel.visible = false
    showLogin("Signed out.")
end sub

sub onChangeServerPressed()
    ClearAuthState(true)
    m.session = LoadAuthState()
    m.gettingStartedPage.serverValue = ""
    m.gettingStartedPage.usernameValue = ""
    m.gettingStartedPage.passwordValue = ""
    m.menuPanel.visible = false
    showLogin("Enter a new server address to continue.")
end sub

sub styleTabs()
    if m.currentTab = "series" then
        m.booksTab.text = "Books"
        m.seriesTab.text = "Series *"
    else
        m.booksTab.text = "Books *"
        m.seriesTab.text = "Series"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if m.menuPanel.visible and key = "back" then
        m.menuPanel.visible = false
        m.userMenuButton.setFocus(true)
        return true
    end if

    if not m.gettingStartedPage.visible and key = "back" then
        if m.currentTab = "series" then
            loadBooks()
            return true
        end if
    end if

    return false
end function
