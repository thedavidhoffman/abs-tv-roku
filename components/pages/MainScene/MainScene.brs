'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initHandlers()

    m.session = AuthStore_Load()
    m.isResumingSession = false
    m.loginActivationCounter = 0
    m.libraryItemBackStack = []
    m.mediaProgress = []
    m.focusSettingsAfterLibraryReload = false
    m.playerReturnTarget = ""

    preloadSavedFields()
    initStyle()
    tryResumeSession()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.bg = m.top.findNode("bg")
    m.login = m.top.findNode("login")
    m.authenticatedContent = m.top.findNode("authenticatedContent")
    m.header = m.top.findNode("header")
    m.homePage = m.top.findNode("homePage")
    m.library = m.top.findNode("library")
    m.search = m.top.findNode("search")
    m.settings = m.top.findNode("settings")
    m.diagnostics = m.top.findNode("diagnostics")
    m.player = m.top.findNode("player")
    m.apiTask = m.top.findNode("apiTask")
    m.libraryApiTask = m.top.findNode("libraryApiTask")
    m.personalizedApiTask = m.top.findNode("personalizedApiTask")
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.login.observeField("loginRequested", "onLoginRequested")
    m.header.observeField("homeSelected", "onHomePressed")
    m.header.observeField("librarySelected", "onLibraryPressed")
    m.header.observeField("searchSelected", "onSearchPressed")
    m.header.observeField("downSelected", "onHeaderDownPressed")
    m.header.observeField("settingsSelected", "onSettingsPressed")
    m.header.observeField("logoutSelected", "onLogoutPressed")
    m.header.observeField("changeServerSelected", "onChangeServerPressed")
    m.header.observeField("usernameUpSequenceSelected", "onDiagnosticsSequencePressed")
    m.homePage.observeField("backSelected", "onHomePageBackSelected")
    m.homePage.observeField("upFromFirstRowSelected", "onHomePageUpFromFirstRowSelected")
    m.homePage.observeField("playSelected", "onHomePagePlaySelected")
    m.library.observeField("errorResponse", "onLibraryError")
    m.library.observeField("playSelected", "onLibraryPlaySelected")
    m.library.observeField("seriesSelected", "onLibrarySeriesSelected")
    m.library.observeField("upFromFirstItemSelected", "onLibraryUpFromFirstItemSelected")
    m.library.observeField("backFromFirstItemSelected", "onLibraryBackFromFirstItemSelected")
    m.player.observeField("closeRequested", "onPlayerCloseRequested")
    m.player.observeField("errorResponse", "onPlayerError")
    m.player.observeField("playbackStartRequested", "onPlaybackStartRequested")
    m.settings.observeField("closeRequested", "onSettingsCloseRequested")
    m.settings.observeField("settingsSaved", "onSettingsSaved")
    m.diagnostics.observeField("closeRequested", "onDiagnosticsCloseRequested")
    m.apiTask.observeField("response", "onApiResponse")
    m.libraryApiTask.observeField("response", "onLibraryApiResponse")
    m.personalizedApiTask.observeField("response", "onPersonalizedApiResponse")
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
        startApiTask(m.apiTask, {
            action: "authorize"
            server: m.session.server
            token: m.session.token
        })
    else
        showLogin("Enter your Audiobookshelf server to begin.")
    end if
end sub

'-------------------------------------------------------------------------------
' onLoginRequested
'-------------------------------------------------------------------------------
sub onLoginRequested()
    request = m.login.loginRequested
    if request = invalid then return

    startApiTask(m.apiTask, request)
end sub

'-------------------------------------------------------------------------------
' onApiResponse
'-------------------------------------------------------------------------------
sub onApiResponse()
    response = m.apiTask.response
    if response = invalid then return
    action = getApiResponseAction(m.apiTask, response)

    if response.ok <> true then
        if m.isResumingSession then
            m.isResumingSession = false
            AuthStore_Clear(false)
            showLogin("Your saved session expired. Please sign in again.")
        else if response.authExpired = true then
            handleExpiredSession(response.errorMessage)
        else if action = "startPlayback" then
            if m.player <> invalid then m.player.playbackResponse = response
        else if action = "login" or m.login.visible then
            m.login.statusMessage = "Login failed: " + SafeString(response.errorMessage, "Unknown error.")
        end if
    else if action = "login" then
        storeAuthenticatedSession(response)
        storeMediaProgress(m.session.mediaProgress)
        showApp()
    else if action = "authorize" then
        m.isResumingSession = false
        storeAuthenticatedSession(response)
        storeMediaProgress(m.session.mediaProgress)
        showApp()
    else if action = "loadLibrary" then
        storeLibraryItems(response)
    else if action = "loadSeries" then
        storeSeriesItems(response)
    else if action = "startPlayback" then
        if m.player <> invalid then m.player.playbackResponse = response
    end if

end sub

'-------------------------------------------------------------------------------
' onPersonalizedApiResponse
'-------------------------------------------------------------------------------
sub onPersonalizedApiResponse()
    response = m.personalizedApiTask.response
    if response = invalid then return

    if response.ok <> true then
        if response.authExpired = true then
            handleExpiredSession(response.errorMessage)
        end if
    else if response.action = "loadPersonalized" then
        storePersonalizedShelves(response)
    end if

end sub

'-------------------------------------------------------------------------------
' onLibraryApiResponse
'-------------------------------------------------------------------------------
sub onLibraryApiResponse()
    response = m.libraryApiTask.response
    if response = invalid then return

    if response.ok <> true then
        if response.authExpired = true then
            handleExpiredSession(response.errorMessage)
        else if m.library <> invalid then
            m.library.errorResponse = response
        end if
    else if response.action = "loadLibrary" then
        storeLibraryItems(response)
    else if response.action = "loadSeries" then
        storeSeriesItems(response)
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
' storeMediaProgress
'-------------------------------------------------------------------------------
sub storeMediaProgress(mediaProgress as dynamic)
    if mediaProgress = invalid then
        m.mediaProgress = []
    else
        m.mediaProgress = mediaProgress
    end if

    if m.homePage <> invalid then m.homePage.mediaProgress = m.mediaProgress
    if m.library <> invalid then m.library.mediaProgress = m.mediaProgress
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
        m.header.username = m.session.username
    end if
    if m.homePage <> invalid then
        m.homePage.server = m.session.server
        m.homePage.token = m.session.token
        m.homePage.mediaProgress = m.mediaProgress
    end if
    if m.library <> invalid then m.library.mediaProgress = m.mediaProgress
    showHomePage()
    if m.homePage <> invalid then m.homePage.callFunc("focusHomePage")
    loadPersonalizedShelves()
    if m.library <> invalid then
        m.library.loadRequest = {
            server: m.session.server
            token: m.session.token
            bookLibraryId: m.session.bookLibraryId
        }
    end if
    reloadLibraryItems()
end sub

'-------------------------------------------------------------------------------
' showHomePage
'-------------------------------------------------------------------------------
sub showHomePage()
    if m.homePage <> invalid then m.homePage.visible = true
    if m.library <> invalid then
        m.library.visible = false
        resetLibraryDrilldown()
    end if
end sub

'-------------------------------------------------------------------------------
' showLibraryPage
'-------------------------------------------------------------------------------
sub showLibraryPage()
    if m.homePage <> invalid then m.homePage.visible = false
    if m.library <> invalid then m.library.visible = true
end sub

'-------------------------------------------------------------------------------
' onHomePressed
'-------------------------------------------------------------------------------
sub onHomePressed()
    closeHeaderMenu()
    showHomePage()
    if m.homePage <> invalid then m.homePage.callFunc("focusHomePage")
    loadPersonalizedShelves()
end sub

'-------------------------------------------------------------------------------
' onHomePageBackSelected
'-------------------------------------------------------------------------------
sub onHomePageBackSelected()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' onHomePageUpFromFirstRowSelected
'-------------------------------------------------------------------------------
sub onHomePageUpFromFirstRowSelected()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' onHomePagePlaySelected
'-------------------------------------------------------------------------------
sub onHomePagePlaySelected()
    selectedItem = m.homePage.playSelected
    m.playerReturnTarget = "home"
    playLibraryItem(selectedItem)
end sub

'-------------------------------------------------------------------------------
' onLibraryPressed
'-------------------------------------------------------------------------------
sub onLibraryPressed()
    closeHeaderMenu()
    showLibraryPage()
    if m.library <> invalid then m.library.callFunc("focusLibraryList")
end sub

'-------------------------------------------------------------------------------
' onSearchPressed
'-------------------------------------------------------------------------------
sub onSearchPressed()
    closeHeaderMenu()
    if m.search <> invalid then m.search.callFunc("openSearch")
end sub

'-------------------------------------------------------------------------------
' onHeaderDownPressed
'-------------------------------------------------------------------------------
sub onHeaderDownPressed()
    if m.homePage <> invalid and m.homePage.visible then
        m.homePage.callFunc("focusHomePage")
        return
    end if

    if m.library <> invalid and m.library.visible then
        m.library.callFunc("focusLibraryList")
    end if
end sub

'-------------------------------------------------------------------------------
' onLibraryPlaySelected
'-------------------------------------------------------------------------------
sub onLibraryPlaySelected()
    selectedItem = m.library.playSelected
    m.playerReturnTarget = "library"
    playLibraryItem(selectedItem)
end sub

'-------------------------------------------------------------------------------
' playLibraryItem
'-------------------------------------------------------------------------------
sub playLibraryItem(selectedItem as dynamic)
    if selectedItem = invalid or selectedItem.id = invalid then return
    if m.session = invalid then return

    coverUrl = Cover_BuildUrl(m.session.server, m.session.token, selectedItem.id, 400)
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
        startPositionSeconds: getMediaProgressCurrentTime(selectedItem.id)
    }
end sub

'-------------------------------------------------------------------------------
' onPlaybackStartRequested
'-------------------------------------------------------------------------------
sub onPlaybackStartRequested()
    request = m.player.playbackStartRequested
    if request = invalid then return

    startApiTask(m.apiTask, request)
end sub

'-------------------------------------------------------------------------------
' getMediaProgressCurrentTime
'-------------------------------------------------------------------------------
function getMediaProgressCurrentTime(itemId as dynamic) as integer
    if itemId = invalid then return 0
    if m.mediaProgress = invalid then return 0

    targetItemId = itemId.ToStr()
    for each progress in m.mediaProgress
        if progress <> invalid and progress.itemId <> invalid and progress.itemId.ToStr() = targetItemId then
            if progress.isFinished = true then return 0
            if progress.currentTime <> invalid then return int(val(progress.currentTime.ToStr()))
        end if
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' onLibrarySeriesSelected
'-------------------------------------------------------------------------------
sub onLibrarySeriesSelected()
    selectedSeries = m.library.seriesSelected
    if selectedSeries = invalid or selectedSeries.seriesId = invalid then return
    if m.session = invalid then return
    if m.libraryApiTask = invalid then return

    startApiTask(m.libraryApiTask, {
        action: "loadSeries"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
        seriesId: selectedSeries.seriesId
        sourceItemIndex: selectedSeries.itemIndex
    })
end sub

'-------------------------------------------------------------------------------
' onSettingsPressed
'-------------------------------------------------------------------------------
sub onSettingsPressed()
    closeHeaderMenu()
    if m.settings <> invalid then m.settings.callFunc("openSettings")
end sub

'-------------------------------------------------------------------------------
' onSettingsCloseRequested
'-------------------------------------------------------------------------------
sub onSettingsCloseRequested()
end sub

'-------------------------------------------------------------------------------
' onSettingsSaved
'-------------------------------------------------------------------------------
sub onSettingsSaved()
    if m.library <> invalid and m.settings <> invalid then
        m.library.displaySettings = m.settings.savedSettings
    end if
    m.focusSettingsAfterLibraryReload = true
    reloadLibraryItems()
end sub

'-------------------------------------------------------------------------------
' reloadLibraryItems
'-------------------------------------------------------------------------------
sub reloadLibraryItems()
    if m.session = invalid then return
    if m.session.server = invalid or m.session.server = "" then return
    if m.session.token = invalid or m.session.token = "" then return
    if m.libraryApiTask = invalid then return

    startApiTask(m.libraryApiTask, {
        action: "loadLibrary"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    })
end sub

'-------------------------------------------------------------------------------
' loadPersonalizedShelves
'-------------------------------------------------------------------------------
sub loadPersonalizedShelves()
    if m.session = invalid then return
    if m.session.server = invalid or m.session.server = "" then return
    if m.session.token = invalid or m.session.token = "" then return
    if m.personalizedApiTask = invalid then return

    startApiTask(m.personalizedApiTask, {
        action: "loadPersonalized"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    })
end sub

'-------------------------------------------------------------------------------
' onLibraryUpFromFirstItemSelected
'-------------------------------------------------------------------------------
sub onLibraryUpFromFirstItemSelected()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' onLibraryBackFromFirstItemSelected
'-------------------------------------------------------------------------------
sub onLibraryBackFromFirstItemSelected()
    if restorePreviousLibraryItems() then return
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' storePersonalizedShelves
'-------------------------------------------------------------------------------
sub storePersonalizedShelves(response as object)
    if response.bookLibraryId <> invalid and response.bookLibraryId <> "" then
        m.session.bookLibraryId = response.bookLibraryId
    end if

    if m.homePage = invalid then return
    m.homePage.personalizedShelves = response.shelves
end sub

'-------------------------------------------------------------------------------
' storeLibraryItems
'-------------------------------------------------------------------------------
sub storeLibraryItems(response as object)
    if response.bookLibraryId <> invalid and response.bookLibraryId <> "" then
        m.session.bookLibraryId = response.bookLibraryId
    end if

    m.libraryItemBackStack = []
    if m.library <> invalid then m.library.libraryItems = response.libraryItems

    if m.focusSettingsAfterLibraryReload = true then
        m.focusSettingsAfterLibraryReload = false
    end if
end sub

'-------------------------------------------------------------------------------
' storeSeriesItems
'-------------------------------------------------------------------------------
sub storeSeriesItems(response as object)
    if response.bookLibraryId <> invalid and response.bookLibraryId <> "" then
        m.session.bookLibraryId = response.bookLibraryId
    end if

    if m.library <> invalid then
        if m.library.libraryItems <> invalid then
            m.libraryItemBackStack.Push({
                items: m.library.libraryItems
                focusIndex: response.sourceItemIndex
            })
        end if
        m.library.libraryItems = response.libraryItems
    end if
end sub

'-------------------------------------------------------------------------------
' restorePreviousLibraryItems
'-------------------------------------------------------------------------------
function restorePreviousLibraryItems() as boolean
    if m.library = invalid then return false
    if m.libraryItemBackStack = invalid or m.libraryItemBackStack.Count() = 0 then return false

    lastIndex = m.libraryItemBackStack.Count() - 1
    previousState = m.libraryItemBackStack[lastIndex]
    m.libraryItemBackStack.Delete(lastIndex)

    m.library.libraryItems = previousState.items
    m.library.callFunc("focusItemAtIndex", previousState.focusIndex)
    return true
end function

'-------------------------------------------------------------------------------
' resetLibraryDrilldown
'-------------------------------------------------------------------------------
sub resetLibraryDrilldown()
    if m.library = invalid then return
    if m.libraryItemBackStack = invalid or m.libraryItemBackStack.Count() = 0 then return

    rootState = m.libraryItemBackStack[0]
    m.libraryItemBackStack = []

    if rootState <> invalid and rootState.items <> invalid then
        m.library.libraryItems = rootState.items
    end if
end sub

'-------------------------------------------------------------------------------
' onDiagnosticsSequencePressed
'-------------------------------------------------------------------------------
sub onDiagnosticsSequencePressed()
    closeHeaderMenu()
    if m.diagnostics <> invalid then m.diagnostics.callFunc("openDiagnostics")
end sub

'-------------------------------------------------------------------------------
' onDiagnosticsCloseRequested
'-------------------------------------------------------------------------------
sub onDiagnosticsCloseRequested()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusUserMenuButton")
end sub

' onPlayerCloseRequested
'-------------------------------------------------------------------------------
sub onPlayerCloseRequested()
    m.player.visible = false
    m.authenticatedContent.visible = true
    if m.playerReturnTarget = "home" and m.homePage <> invalid and m.homePage.visible then
        m.homePage.callFunc("focusHomePage")
        return
    end if

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
' handleExpiredSession
'-------------------------------------------------------------------------------
sub handleExpiredSession(message as string)
    AuthStore_Clear(false)
    if m.session <> invalid then m.session.token = ""
    m.login.passwordValue = ""
    showLogin(message)
end sub

'-------------------------------------------------------------------------------
' onLogoutPressed
'-------------------------------------------------------------------------------
sub onLogoutPressed()
    if m.session <> invalid and m.session.server <> invalid and m.session.token <> invalid and m.session.token <> "" then
        startApiTask(m.apiTask, {
            action: "logout"
            server: m.session.server
            token: m.session.token
        })
    end if

    AuthStore_Clear(false)
    if m.session <> invalid then m.session.token = ""
    m.login.passwordValue = ""
    closeHeaderMenu()
    showLogin("Signed out.")
end sub

'-------------------------------------------------------------------------------
' onChangeServerPressed
'-------------------------------------------------------------------------------
sub onChangeServerPressed()

    m.session = AuthStore_Load()
    m.login.serverValue = ""
    m.login.usernameValue = ""
    m.login.passwordValue = ""
    closeHeaderMenu()
    showLogin("Enter a new server address to continue.")
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
        if hasLibraryBackStack() then
            if moveLibraryGridFocusToFirstItem() then return true
            if restorePreviousLibraryItems() then return true
        end if

        if moveLibraryGridFocusToFirstItem() then return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' hasLibraryBackStack
'-------------------------------------------------------------------------------
function hasLibraryBackStack() as boolean
    return m.libraryItemBackStack <> invalid and m.libraryItemBackStack.Count() > 0
end function

'-------------------------------------------------------------------------------
' moveLibraryGridFocusToFirstItem
'-------------------------------------------------------------------------------
function moveLibraryGridFocusToFirstItem() as boolean
    if m.library = invalid or m.library.visible <> true then return false

    handled = m.library.callFunc("moveFocusToFirstGridItem")
    return handled = true
end function

'-------------------------------------------------------------------------------
' getApiResponseAction
'-------------------------------------------------------------------------------
function getApiResponseAction(task as dynamic, response as dynamic) as string
    if response <> invalid and response.action <> invalid then return response.action
    if task <> invalid and task.request <> invalid and task.request.action <> invalid then
        return task.request.action
    end if
    return ""
end function

'-------------------------------------------------------------------------------
' startApiTask
'-------------------------------------------------------------------------------
sub startApiTask(task as dynamic, request as object)
    if task = invalid then return

    task.request = request
    task.control = "run"
end sub
