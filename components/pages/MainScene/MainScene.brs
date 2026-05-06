'===============================================================================
' Core
'===============================================================================

'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    coreInitReferences()
    coreInitHandlers()

    m.session = AuthStore_Load()
    m.isResumingSession = false
    m.loginActivationCounter = 0
    m.libraryItemBackStack = []
    m.mediaProgress = []
    m.focusSettingsAfterLibraryReload = false
    m.playerReturnTarget = ""

    authPreloadSavedFields()
    coreInitStyle()
    authResumeSession()
end sub

'-------------------------------------------------------------------------------
' coreInitReferences
'-------------------------------------------------------------------------------
sub coreInitReferences()
    m.bg = m.top.findNode("bg")
    m.login = m.top.findNode("login")
    m.authenticatedContent = m.top.findNode("authenticatedContent")
    m.header = m.top.findNode("header")
    m.homePage = m.top.findNode("homePage")
    m.library = m.top.findNode("library")
    m.search = m.top.findNode("search")
    m.player = m.top.findNode("player")
    m.overlayHost = m.top.findNode("overlayHost")
    m.apiTask = m.top.findNode("apiTask")
    m.playbackApiTask = m.top.findNode("playbackApiTask")
    m.libraryApiTask = m.top.findNode("libraryApiTask")
    m.personalizedApiTask = m.top.findNode("personalizedApiTask")
end sub

'-------------------------------------------------------------------------------
' coreInitHandlers
'-------------------------------------------------------------------------------
sub coreInitHandlers()
    m.login.observeField("loginRequested", "authHandleLoginRequested")
    m.header.observeField("homeSelected", "homeHandlePressed")
    m.header.observeField("librarySelected", "libraryHandlePressed")
    m.header.observeField("searchSelected", "searchHandlePressed")
    m.header.observeField("downSelected", "headerHandleDownPressed")
    m.header.observeField("backSelected", "headerHandleBackPressed")
    m.header.observeField("logoutSelected", "authHandleLogoutPressed")
    m.header.observeField("overlayRequested", "overlayHandleRequested")
    m.homePage.observeField("backSelected", "homeHandleBackSelected")
    m.homePage.observeField("upFromFirstRowSelected", "homeHandleUpFromFirstRowSelected")
    m.homePage.observeField("playSelected", "homeHandlePlaySelected")
    m.library.observeField("errorResponse", "libraryHandleError")
    m.library.observeField("playSelected", "libraryHandlePlaySelected")
    m.library.observeField("seriesSelected", "libraryHandleSeriesSelected")
    m.library.observeField("upFromFirstItemSelected", "libraryHandleUpFromFirstItemSelected")
    m.library.observeField("backFromFirstItemSelected", "libraryHandleBackFromFirstItemSelected")
    m.player.observeField("closeRequested", "playbackHandlePlayerCloseRequested")
    m.player.observeField("errorResponse", "playbackHandlePlayerError")
    m.player.observeField("playbackStartRequested", "playbackHandleStartRequested")
    m.player.observeField("playbackSyncRequested", "playbackHandleSyncRequested")
    m.player.observeField("playbackCloseRequested", "playbackHandleCloseRequested")
    m.overlayHost.observeField("closed", "overlayHandleClosed")
    m.apiTask.observeField("response", "taskHandleApiResponse")
    m.playbackApiTask.observeField("response", "taskHandlePlaybackResponse")
    m.libraryApiTask.observeField("response", "taskHandleLibraryResponse")
    m.personalizedApiTask.observeField("response", "taskHandlePersonalizedResponse")
end sub

'-------------------------------------------------------------------------------
' coreInitStyle
'-------------------------------------------------------------------------------
sub coreInitStyle()
    palette = Color()
    if m.bg <> invalid then m.bg.color = palette.background.secondary
end sub

'===============================================================================
' Auth / Session
'===============================================================================

'-------------------------------------------------------------------------------
' authPreloadSavedFields
'-------------------------------------------------------------------------------
sub authPreloadSavedFields()
    if m.session.server <> invalid and TrimString(m.session.server) <> "" then
        m.login.serverValue = m.session.server
    end if
    if m.session.username <> invalid and TrimString(m.session.username) <> "" then
        m.login.usernameValue = m.session.username
    end if
end sub

'-------------------------------------------------------------------------------
' authResumeSession
'-------------------------------------------------------------------------------
sub authResumeSession()
    if m.session.token <> invalid and m.session.token <> "" and m.session.server <> invalid and m.session.server <> "" then
        m.isResumingSession = true
        m.login.visible = false
        m.authenticatedContent.visible = false
        taskStartApi(m.apiTask, {
            action: "authorize"
            server: m.session.server
            token: m.session.token
        })
    else
        authShowLogin("Enter your Audiobookshelf server to begin.")
    end if
end sub

'-------------------------------------------------------------------------------
' authHandleLoginRequested
'-------------------------------------------------------------------------------
sub authHandleLoginRequested()
    request = m.login.loginRequested
    if request = invalid then return

    taskStartApi(m.apiTask, request)
end sub

'-------------------------------------------------------------------------------
' authShowLogin
'-------------------------------------------------------------------------------
sub authShowLogin(message as string)
    m.login.visible = true
    m.authenticatedContent.visible = false
    headerCloseMenu()
    m.login.statusMessage = message
    m.loginActivationCounter = m.loginActivationCounter + 1
    m.login.activationToken = m.loginActivationCounter
end sub

'-------------------------------------------------------------------------------
' authStoreSession
'-------------------------------------------------------------------------------
sub authStoreSession(response as object)
    m.session = Session_BuildAuthenticatedSession(response)
    Session_SaveAuthenticatedSession(m.session)
end sub

'-------------------------------------------------------------------------------
' authStoreMediaProgress
'-------------------------------------------------------------------------------
sub authStoreMediaProgress(mediaProgress as dynamic)
    if mediaProgress = invalid then
        m.mediaProgress = []
    else
        m.mediaProgress = mediaProgress
    end if

    if m.homePage <> invalid then m.homePage.mediaProgress = m.mediaProgress
    if m.library <> invalid then m.library.mediaProgress = m.mediaProgress
end sub

'-------------------------------------------------------------------------------
' authHandleExpiredSession
'-------------------------------------------------------------------------------
sub authHandleExpiredSession(message as string)
    AuthStore_Clear(false)
    if m.session <> invalid then m.session.token = ""
    m.login.passwordValue = ""
    authShowLogin(message)
end sub

'-------------------------------------------------------------------------------
' authHandleLogoutPressed
'-------------------------------------------------------------------------------
sub authHandleLogoutPressed()
    if m.session <> invalid and m.session.server <> invalid and m.session.token <> invalid and m.session.token <> "" then
        taskStartApi(m.apiTask, {
            action: "logout"
            server: m.session.server
            token: m.session.token
        })
    end if

    AuthStore_Clear(false)
    if m.session <> invalid then m.session.token = ""
    m.login.passwordValue = ""
    headerCloseMenu()
    authShowLogin("Signed out.")
end sub

'===============================================================================
' Task Responses
'===============================================================================

'-------------------------------------------------------------------------------
' taskHandleApiResponse
'-------------------------------------------------------------------------------
sub taskHandleApiResponse()

    response = m.apiTask.response
    if response = invalid then return
    action = taskGetResponseAction(m.apiTask, response)

    if response.ok <> true then

        if m.isResumingSession then
            m.isResumingSession = false
            AuthStore_Clear(false)
            authShowLogin("Your saved session expired. Please sign in again.")
        
        else if response.authExpired = true then
            authHandleExpiredSession(response.errorMessage)
        
        else if action = "startPlayback" then
            if m.player <> invalid then m.player.playbackResponse = response
        
        else if action = "login" or m.login.visible then
            m.login.statusMessage = "Login failed: " + SafeString(response.errorMessage, "Unknown error.")
        end if

    else if action = "login" then
        authStoreSession(response)
        authStoreMediaProgress(m.session.mediaProgress)
        navShowApp()

    else if action = "authorize" then
        m.isResumingSession = false
        authStoreSession(response)
        authStoreMediaProgress(m.session.mediaProgress)
        navShowApp()

    else if action = "loadLibrary" then
        libraryStoreItems(response)

    else if action = "loadSeries" then
        libraryStoreSeriesItems(response)

    else if action = "startPlayback" then
        if m.player <> invalid then m.player.playbackResponse = response
    end if

end sub

'-------------------------------------------------------------------------------
' taskHandleLibraryResponse
'-------------------------------------------------------------------------------
sub taskHandleLibraryResponse()
    response = m.libraryApiTask.response
    if response = invalid then return

    if response.ok <> true then
        if response.authExpired = true then
            authHandleExpiredSession(response.errorMessage)
        else if m.library <> invalid then
            m.library.errorResponse = response
        end if
    else if response.action = "loadLibrary" then
        libraryStoreItems(response)
    else if response.action = "loadSeries" then
        libraryStoreSeriesItems(response)
    end if

end sub

'-------------------------------------------------------------------------------
' taskHandlePersonalizedResponse
'-------------------------------------------------------------------------------
sub taskHandlePersonalizedResponse()
    response = m.personalizedApiTask.response
    if response = invalid then return

    if response.ok <> true then
        if response.authExpired = true then
            authHandleExpiredSession(response.errorMessage)
        end if
    else if response.action = "loadPersonalized" then
        homeStorePersonalizedShelves(response)
    end if

end sub

'-------------------------------------------------------------------------------
' taskHandlePlaybackResponse
'-------------------------------------------------------------------------------
sub taskHandlePlaybackResponse()
    response = m.playbackApiTask.response
    if response = invalid then return

    if response.ok <> true and response.authExpired = true then
        authHandleExpiredSession(response.errorMessage)
    end if
end sub

'-------------------------------------------------------------------------------
' taskGetResponseAction
'-------------------------------------------------------------------------------
function taskGetResponseAction(task as dynamic, response as dynamic) as string
    if response <> invalid and response.action <> invalid then return response.action
    if task <> invalid and task.request <> invalid and task.request.action <> invalid then
        return task.request.action
    end if
    return ""
end function

'-------------------------------------------------------------------------------
' taskStartApi
'-------------------------------------------------------------------------------
sub taskStartApi(task as dynamic, request as object)
    if task = invalid then return

    task.request = request
    task.control = "run"
end sub

'===============================================================================
' Navigation / Header / Search
'===============================================================================

'-------------------------------------------------------------------------------
' navShowApp
'-------------------------------------------------------------------------------
sub navShowApp()
    m.login.visible = false
    m.authenticatedContent.visible = true
    headerCloseMenu()
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
    navShowHomePage()
    if m.homePage <> invalid then m.homePage.callFunc("focusHomePage")
    homeLoadPersonalizedShelves()
    if m.library <> invalid then
        m.library.loadRequest = {
            server: m.session.server
            token: m.session.token
            bookLibraryId: m.session.bookLibraryId
        }
    end if
    libraryReloadItems()
end sub

'-------------------------------------------------------------------------------
' navShowHomePage
'-------------------------------------------------------------------------------
sub navShowHomePage()
    if m.homePage <> invalid then m.homePage.visible = true
    if m.library <> invalid then
        m.library.visible = false
        libraryResetDrilldown()
    end if
end sub

'-------------------------------------------------------------------------------
' navShowLibraryPage
'-------------------------------------------------------------------------------
sub navShowLibraryPage()
    if m.homePage <> invalid then m.homePage.visible = false
    if m.library <> invalid then m.library.visible = true
end sub

'-------------------------------------------------------------------------------
' headerHandleDownPressed
'-------------------------------------------------------------------------------
sub headerHandleDownPressed()
    if m.homePage <> invalid and m.homePage.visible then
        m.homePage.callFunc("focusHomePage")
        return
    end if

    if m.library <> invalid and m.library.visible then
        m.library.callFunc("focusLibraryList")
    end if
end sub

'-------------------------------------------------------------------------------
' headerHandleBackPressed
'-------------------------------------------------------------------------------
sub headerHandleBackPressed()
    overlayOpenExitDialog()
end sub

'-------------------------------------------------------------------------------
' headerCloseMenu
'-------------------------------------------------------------------------------
sub headerCloseMenu()
    if m.header = invalid then return

    if m.closeHeaderMenuToken = invalid then m.closeHeaderMenuToken = 0
    m.closeHeaderMenuToken = m.closeHeaderMenuToken + 1
    m.header.closeMenuToken = m.closeHeaderMenuToken
end sub

'-------------------------------------------------------------------------------
' headerIsHomeButtonFocused
'-------------------------------------------------------------------------------
function headerIsHomeButtonFocused() as boolean
    if m.header = invalid then return false

    isFocused = m.header.callFunc("isHomeButtonFocused")
    return isFocused = true
end function

'-------------------------------------------------------------------------------
' searchHandlePressed
'-------------------------------------------------------------------------------
sub searchHandlePressed()
    headerCloseMenu()
    if m.search <> invalid then m.search.callFunc("openSearch")
end sub

'===============================================================================
' Home
'===============================================================================

'-------------------------------------------------------------------------------
' homeHandlePressed
'-------------------------------------------------------------------------------
sub homeHandlePressed()
    headerCloseMenu()
    navShowHomePage()
    if m.homePage <> invalid then m.homePage.callFunc("focusHomePage")
    homeLoadPersonalizedShelves()
end sub

'-------------------------------------------------------------------------------
' homeHandleBackSelected
'-------------------------------------------------------------------------------
sub homeHandleBackSelected()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' homeHandleUpFromFirstRowSelected
'-------------------------------------------------------------------------------
sub homeHandleUpFromFirstRowSelected()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' homeHandlePlaySelected
'-------------------------------------------------------------------------------
sub homeHandlePlaySelected()
    selectedItem = m.homePage.playSelected
    m.playerReturnTarget = "home"
    playbackPlayItem(selectedItem)
end sub

'-------------------------------------------------------------------------------
' homeLoadPersonalizedShelves
'-------------------------------------------------------------------------------
sub homeLoadPersonalizedShelves()
    if m.session = invalid then return
    if m.session.server = invalid or m.session.server = "" then return
    if m.session.token = invalid or m.session.token = "" then return
    if m.personalizedApiTask = invalid then return

    taskStartApi(m.personalizedApiTask, {
        action: "loadPersonalized"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    })
end sub

'-------------------------------------------------------------------------------
' homeStorePersonalizedShelves
'-------------------------------------------------------------------------------
sub homeStorePersonalizedShelves(response as object)
    if response.bookLibraryId <> invalid and response.bookLibraryId <> "" then
        m.session.bookLibraryId = response.bookLibraryId
    end if

    if m.homePage = invalid then return
    m.homePage.personalizedShelves = response.shelves
end sub

'===============================================================================
' Library
'===============================================================================

'-------------------------------------------------------------------------------
' libraryHandlePressed
'-------------------------------------------------------------------------------
sub libraryHandlePressed()
    headerCloseMenu()
    navShowLibraryPage()
    if m.library <> invalid then m.library.callFunc("focusLibraryList")
end sub

'-------------------------------------------------------------------------------
' libraryHandleError
'-------------------------------------------------------------------------------
sub libraryHandleError()
    response = m.library.errorResponse
    if response = invalid then return

    if response.authExpired = true then
        authHandleExpiredSession(response.errorMessage)
    end if
end sub

'-------------------------------------------------------------------------------
' libraryHandlePlaySelected
'-------------------------------------------------------------------------------
sub libraryHandlePlaySelected()
    selectedItem = m.library.playSelected
    m.playerReturnTarget = "library"
    playbackPlayItem(selectedItem)
end sub

'-------------------------------------------------------------------------------
' libraryHandleSeriesSelected
'-------------------------------------------------------------------------------
sub libraryHandleSeriesSelected()
    selectedSeries = m.library.seriesSelected
    if selectedSeries = invalid or selectedSeries.seriesId = invalid then return
    if m.session = invalid then return
    if m.libraryApiTask = invalid then return

    taskStartApi(m.libraryApiTask, {
        action: "loadSeries"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
        seriesId: selectedSeries.seriesId
        sourceItemIndex: selectedSeries.itemIndex
    })
end sub

'-------------------------------------------------------------------------------
' libraryReloadItems
'-------------------------------------------------------------------------------
sub libraryReloadItems()
    if m.session = invalid then return
    if m.session.server = invalid or m.session.server = "" then return
    if m.session.token = invalid or m.session.token = "" then return
    if m.libraryApiTask = invalid then return

    taskStartApi(m.libraryApiTask, {
        action: "loadLibrary"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    })
end sub

'-------------------------------------------------------------------------------
' libraryHandleUpFromFirstItemSelected
'-------------------------------------------------------------------------------
sub libraryHandleUpFromFirstItemSelected()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' libraryHandleBackFromFirstItemSelected
'-------------------------------------------------------------------------------
sub libraryHandleBackFromFirstItemSelected()
    if libraryRestorePreviousItems() then return
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' libraryStoreItems
'-------------------------------------------------------------------------------
sub libraryStoreItems(response as object)
    if response.bookLibraryId <> invalid and response.bookLibraryId <> "" then
        m.session.bookLibraryId = response.bookLibraryId
    end if

    m.libraryItemBackStack = []
    if m.library <> invalid then m.library.libraryItems = response.libraryItems

    if m.focusSettingsAfterLibraryReload = true then
        m.focusSettingsAfterLibraryReload = false
        if m.header <> invalid and m.header.visible then m.header.callFunc("focusSettingsButton")
    end if
end sub

'-------------------------------------------------------------------------------
' libraryStoreSeriesItems
'-------------------------------------------------------------------------------
sub libraryStoreSeriesItems(response as object)
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
' libraryRestorePreviousItems
'-------------------------------------------------------------------------------
function libraryRestorePreviousItems() as boolean
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
' libraryResetDrilldown
'-------------------------------------------------------------------------------
sub libraryResetDrilldown()
    if m.library = invalid then return
    if m.libraryItemBackStack = invalid or m.libraryItemBackStack.Count() = 0 then return

    rootState = m.libraryItemBackStack[0]
    m.libraryItemBackStack = []

    if rootState <> invalid and rootState.items <> invalid then
        m.library.libraryItems = rootState.items
    end if
end sub

'-------------------------------------------------------------------------------
' libraryHasBackStack
'-------------------------------------------------------------------------------
function libraryHasBackStack() as boolean
    return m.libraryItemBackStack <> invalid and m.libraryItemBackStack.Count() > 0
end function

'-------------------------------------------------------------------------------
' libraryMoveGridFocusToFirstItem
'-------------------------------------------------------------------------------
function libraryMoveGridFocusToFirstItem() as boolean
    if m.library = invalid or m.library.visible <> true then return false

    handled = m.library.callFunc("moveFocusToFirstGridItem")
    return handled = true
end function

'===============================================================================
' Playback
'===============================================================================

'-------------------------------------------------------------------------------
' playbackPlayItem
'-------------------------------------------------------------------------------
sub playbackPlayItem(selectedItem as dynamic)
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
        startPositionSeconds: playbackGetStartPosition(selectedItem)
    }
end sub

'-------------------------------------------------------------------------------
' playbackHandleStartRequested
'-------------------------------------------------------------------------------
sub playbackHandleStartRequested()
    request = m.player.playbackStartRequested
    if request = invalid then return

    taskStartApi(m.apiTask, request)
end sub

'-------------------------------------------------------------------------------
' playbackHandleSyncRequested
'-------------------------------------------------------------------------------
sub playbackHandleSyncRequested()
    request = m.player.playbackSyncRequested
    if request = invalid then return

    taskStartApi(m.playbackApiTask, request)
end sub

'-------------------------------------------------------------------------------
' playbackHandleCloseRequested
'-------------------------------------------------------------------------------
sub playbackHandleCloseRequested()
    request = m.player.playbackCloseRequested
    if request = invalid then return

    taskStartApi(m.playbackApiTask, request)
end sub

'-------------------------------------------------------------------------------
' playbackGetMediaProgressCurrentTime
'-------------------------------------------------------------------------------
function playbackGetMediaProgressCurrentTime(itemId as dynamic) as integer
    if itemId = invalid then return 0
    if m.mediaProgress = invalid then return 0

    targetItemId = itemId.ToStr()
    for each progress in m.mediaProgress
        if progress <> invalid and progress.itemId <> invalid and progress.itemId.ToStr() = targetItemId then
            if progress.isFinished = true then return 0

            currentTime = 0
            if progress.currentTime <> invalid then currentTime = int(val(progress.currentTime.ToStr()))
            if currentTime > 0 then return currentTime

            duration = 0
            if progress.duration <> invalid then duration = val(progress.duration.ToStr())

            progressValue = 0
            if progress.progress <> invalid then progressValue = val(progress.progress.ToStr())
            if duration > 0 and progressValue > 0 then
                if progressValue > 1 then progressValue = progressValue / 100
                if progressValue > 1 then progressValue = 1
                return int(progressValue * duration)
            end if
        end if
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' playbackGetStartPosition
'-------------------------------------------------------------------------------
function playbackGetStartPosition(selectedItem as dynamic) as integer
    if selectedItem = invalid then return 0

    if selectedItem.startPositionSeconds <> invalid then
        startPosition = int(val(selectedItem.startPositionSeconds.ToStr()))
        if startPosition > 0 then return startPosition
    end if

    candidateIds = playbackGetProgressCandidateIds(selectedItem)
    for each candidateId in candidateIds
        startTime = playbackGetMediaProgressCurrentTime(candidateId)
        if startTime > 0 then return startTime
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' playbackGetProgressCandidateIds
'-------------------------------------------------------------------------------
function playbackGetProgressCandidateIds(item as dynamic) as object
    ids = []
    if item = invalid then return ids

    if item.id <> invalid then ids.Push(item.id)
    if item.libraryItemId <> invalid then ids.Push(item.libraryItemId)
    if item.mediaItemId <> invalid then ids.Push(item.mediaItemId)
    if item.media <> invalid and item.media.id <> invalid then ids.Push(item.media.id)

    return ids
end function

'-------------------------------------------------------------------------------
' playbackHandlePlayerCloseRequested
'-------------------------------------------------------------------------------
sub playbackHandlePlayerCloseRequested()
    
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
' playbackHandlePlayerError
'-------------------------------------------------------------------------------
sub playbackHandlePlayerError()
    response = m.player.errorResponse
    if response = invalid then return

    if response.authExpired = true then
        playbackHandlePlayerCloseRequested()
        authHandleExpiredSession(response.errorMessage)
    end if
end sub

'===============================================================================
' Overlays
'===============================================================================

'-------------------------------------------------------------------------------
' overlayHandleRequested
'-------------------------------------------------------------------------------
sub overlayHandleRequested()
    headerCloseMenu()
    if m.overlayHost = invalid then return

    request = m.header.overlayRequested
    if request = invalid then return

    m.overlayHost.callFunc("openOverlay", request)
end sub

'-------------------------------------------------------------------------------
' overlayHandleClosed
'-------------------------------------------------------------------------------
sub overlayHandleClosed()
    closed = m.overlayHost.closed
    if closed <> invalid and closed.request <> invalid and closed.request.id = "settings" and closed.overlay <> invalid then
        overlayHandleSettingsSaved(closed.overlay.savedSettings)
        if m.header <> invalid and m.header.visible then m.header.callFunc("focusSettingsButton")
        return
    end if

    if closed <> invalid and closed.request <> invalid and closed.request.id = "exit" and closed.overlay <> invalid then
        if closed.overlay.confirmed <> invalid and closed.overlay.confirmed > 0 then
            m.top.closeRequested = true
            return
        end if

        if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
        return
    end if

    if m.header <> invalid and m.header.visible then m.header.callFunc("focusUserMenuButton")
end sub

'-------------------------------------------------------------------------------
' overlayHandleSettingsSaved
'-------------------------------------------------------------------------------
sub overlayHandleSettingsSaved(savedSettings as dynamic)
    if savedSettings = invalid then return

    if m.library <> invalid then m.library.displaySettings = savedSettings
    m.focusSettingsAfterLibraryReload = true
    libraryReloadItems()
end sub

'-------------------------------------------------------------------------------
' overlayOpenExitDialog
'-------------------------------------------------------------------------------
sub overlayOpenExitDialog()
    if m.overlayHost = invalid then return

    m.overlayHost.callFunc("openOverlay", {
        id: "exit"
        componentName: "ExitDialog"
        closeFields: ["confirmed", "canceled"]
        openFunction: "openConfirmation"
    })
end sub

'===============================================================================
' Input
'===============================================================================

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if m.player <> invalid and m.player.visible then
        return false
    end if

    if m.header <> invalid and m.header.menuOpen and key = "back" then
        headerCloseMenu()
        return true
    end if

    if key = "back" and headerIsHomeButtonFocused() then
        overlayOpenExitDialog()
        return true
    end if

    if not m.login.visible and key = "back" then
        if libraryHasBackStack() then
            if libraryMoveGridFocusToFirstItem() then return true
            if libraryRestorePreviousItems() then return true
        end if

        if libraryMoveGridFocusToFirstItem() then return true
    end if

    return false
end function
