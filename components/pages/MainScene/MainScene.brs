'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initHandlers()
    initStyle()

    m.session = invalid
    m.loginActivationCounter = 0
    m.authResumeRequestCounter = 0
    m.authLogoutRequestCounter = 0
    m.seriesRowsRequestCounter = 0
    m.mediaProgress = []
    m.focusSettingsAfterLibraryReload = false
    m.playerReturnTarget = ""

    authPreloadSavedFields()
    authRequestResumeSession()
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
    m.seriesPage = m.top.findNode("seriesPage")
    m.search = m.top.findNode("search")
    m.player = m.top.findNode("player")
    m.overlayHost = m.top.findNode("overlayHost")
    m.authController = m.top.findNode("authController")
    m.libraryController = m.top.findNode("libraryController")
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.login.observeField("loginRequested", "authHandleLoginRequested")
    m.header.observeField("homeSelected", "homeHandlePressed")
    m.header.observeField("librarySelected", "libraryHandlePressed")
    m.header.observeField("seriesSelected", "seriesHandlePressed")
    m.header.observeField("searchSelected", "searchHandlePressed")
    m.header.observeField("currentLibrarySelected", "libraryHandleCurrentLibrarySelected")
    m.header.observeField("downSelected", "headerHandleDownPressed")
    m.header.observeField("backSelected", "headerHandleBackPressed")
    m.header.observeField("logoutSelected", "authHandleLogoutPressed")
    m.header.observeField("overlayRequested", "overlayHandleRequested")
    m.search.observeField("querySelected", "searchHandleQuerySelected")
    m.homePage.observeField("backSelected", "homeHandleBackSelected")
    m.homePage.observeField("upFromFirstRowSelected", "homeHandleUpFromFirstRowSelected")
    m.homePage.observeField("playSelected", "homeHandlePlaySelected")
    m.homePage.observeField("errorResponse", "homeHandleError")
    m.library.observeField("errorResponse", "libraryHandleError")
    m.library.observeField("playSelected", "libraryHandlePlaySelected")
    m.library.observeField("upFromFirstItemSelected", "libraryHandleUpFromFirstItemSelected")
    m.library.observeField("backFromFirstItemSelected", "libraryHandleBackFromFirstItemSelected")
    m.library.observeField("itemsReloaded", "libraryHandleItemsReloaded")
    m.library.observeField("mainListRestored", "libraryHandleMainListRestored")
    m.library.observeField("controllerSearchRequest", "libraryHandleSearchRequest")
    m.library.observeField("seriesItemsRequest", "libraryHandleSeriesItemsRequest")
    m.seriesPage.observeField("playSelected", "seriesHandlePlaySelected")
    m.seriesPage.observeField("upFromFirstRowSelected", "seriesHandleUpFromFirstRowSelected")
    m.seriesPage.observeField("backSelected", "seriesHandleBackSelected")
    m.seriesPage.observeField("errorResponse", "seriesHandleError")
    m.player.observeField("closeRequested", "playbackHandlePlayerCloseRequested")
    m.player.observeField("errorResponse", "playbackHandlePlayerError")
    m.overlayHost.observeField("closed", "overlayHandleClosed")
    m.authController.observeField("authenticatedSession", "authHandleAuthenticatedSession")
    m.authController.observeField("loginRequired", "authHandleLoginRequired")
    m.authController.observeField("loginFailed", "authHandleLoginFailed")
    m.authController.observeField("sessionExpired", "authHandleSessionExpired")
    m.libraryController.observeField("libraryItemsChanged", "libraryControllerHandleItemsChanged")
    m.libraryController.observeField("searchResponse", "libraryControllerHandleSearchResponse")
    m.libraryController.observeField("seriesItemsResponse", "libraryControllerHandleSeriesItemsResponse")
    m.libraryController.observeField("seriesRowsResponse", "libraryControllerHandleSeriesRowsResponse")
    m.libraryController.observeField("errorResponse", "libraryControllerHandleError")
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    if m.bg <> invalid then m.bg.color = palette.background.secondary
end sub

'-------------------------------------------------------------------------------
' reloadHomeShelvesAfterPlayback
'-------------------------------------------------------------------------------
sub reloadHomeShelvesAfterPlayback()
    if m.homePage <> invalid then m.homePage.callFunc("reloadPersonalizedShelves")
end sub

'===============================================================================
' Auth / Session
'===============================================================================

'-------------------------------------------------------------------------------
' authPreloadSavedFields
'-------------------------------------------------------------------------------
sub authPreloadSavedFields()
    if m.authController = invalid then return

    savedSession = m.authController.savedSession
    if savedSession = invalid then return

    if savedSession.server <> invalid and savedSession.server <> "" then
        m.login.serverValue = savedSession.server
    end if
    if savedSession.username <> invalid and savedSession.username <> "" then
        m.login.usernameValue = savedSession.username
    end if
end sub

'-------------------------------------------------------------------------------
' authRequestResumeSession
'-------------------------------------------------------------------------------
sub authRequestResumeSession()
    if m.authController = invalid then return

    m.login.visible = false
    m.authenticatedContent.visible = false
    m.authResumeRequestCounter = m.authResumeRequestCounter + 1
    m.authController.resumeRequested = m.authResumeRequestCounter
end sub

'-------------------------------------------------------------------------------
' authHandleLoginRequested
'-------------------------------------------------------------------------------
sub authHandleLoginRequested()
    request = m.login.loginRequested
    if request = invalid then return

    if m.authController <> invalid then m.authController.loginRequest = request
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
    if m.seriesPage <> invalid then m.seriesPage.mediaProgress = m.mediaProgress
end sub

'-------------------------------------------------------------------------------
' authHandleExpiredSession
'-------------------------------------------------------------------------------
sub authHandleExpiredSession(message as string)
    if m.authController <> invalid then m.authController.callFunc("clearSavedSession")
    if m.session <> invalid then m.session.token = ""
    m.login.passwordValue = ""
    authShowLogin(message)
end sub

'-------------------------------------------------------------------------------
' handleComponentError
'-------------------------------------------------------------------------------
function handleComponentError(response as dynamic) as boolean
    if response = invalid then return false

    if response.authExpired = true then
        authHandleExpiredSession(response.errorMessage)
        return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' authHandleLogoutPressed
'-------------------------------------------------------------------------------
sub authHandleLogoutPressed()
    request = {
        server: ""
        token: ""
    }
    if m.session <> invalid then
        if m.session.server <> invalid then request.server = m.session.server
        if m.session.token <> invalid then request.token = m.session.token
        m.session.token = ""
    end if
    m.authLogoutRequestCounter = m.authLogoutRequestCounter + 1
    request.counter = m.authLogoutRequestCounter
    if m.authController <> invalid then m.authController.logoutRequest = request

    m.login.passwordValue = ""
    headerCloseMenu()
end sub

'-------------------------------------------------------------------------------
' authHandleAuthenticatedSession
'-------------------------------------------------------------------------------
sub authHandleAuthenticatedSession()
    session = m.authController.authenticatedSession
    if session = invalid then return

    m.session = session
    authStoreMediaProgress(m.session.mediaProgress)
    navShowApp()
end sub

'-------------------------------------------------------------------------------
' authHandleLoginRequired
'-------------------------------------------------------------------------------
sub authHandleLoginRequired()
    request = m.authController.loginRequired
    if request = invalid then return

    authShowLogin(request.message)
end sub

'-------------------------------------------------------------------------------
' authHandleLoginFailed
'-------------------------------------------------------------------------------
sub authHandleLoginFailed()
    response = m.authController.loginFailed
    if response = invalid then return

    m.login.statusMessage = response.message
end sub

'-------------------------------------------------------------------------------
' authHandleSessionExpired
'-------------------------------------------------------------------------------
sub authHandleSessionExpired()
    response = m.authController.sessionExpired
    if response = invalid then return

    authHandleExpiredSession(response.message)
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
    loadRequest = buildSessionLoadRequest()
    if m.header <> invalid then
        m.header.visible = true
        m.header.username = m.session.username
        m.header.libraries = m.session.libraries
        m.header.currentLibraryId = m.session.bookLibraryId
    end if
    if m.homePage <> invalid then
        m.homePage.mediaProgress = m.mediaProgress
        m.homePage.loadRequest = loadRequest
    end if
    if m.library <> invalid then m.library.mediaProgress = m.mediaProgress
    if m.seriesPage <> invalid then
        m.seriesPage.mediaProgress = m.mediaProgress
        m.seriesPage.loadRequest = loadRequest
    end if
    navShowHomePage()
    focusHomePage()
    if m.library <> invalid then
        m.library.loadRequest = loadRequest
    end if
    if m.libraryController <> invalid then
        m.libraryController.loadRequest = loadRequest
    end if
end sub

'-------------------------------------------------------------------------------
' buildSessionLoadRequest
'-------------------------------------------------------------------------------
function buildSessionLoadRequest() as object
    if m.session = invalid then return {}

    return {
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    }
end function

'-------------------------------------------------------------------------------
' navShowHomePage
'-------------------------------------------------------------------------------
sub navShowHomePage()
    if m.homePage <> invalid then m.homePage.visible = true
    if m.seriesPage <> invalid then m.seriesPage.visible = false
    if m.library <> invalid then
        m.library.visible = false
        m.library.callFunc("resetDrilldown")
    end if
end sub

'-------------------------------------------------------------------------------
' navShowLibraryPage
'-------------------------------------------------------------------------------
sub navShowLibraryPage()
    if m.homePage <> invalid then m.homePage.visible = false
    if m.seriesPage <> invalid then m.seriesPage.visible = false
    if m.library <> invalid then m.library.visible = true
end sub

'-------------------------------------------------------------------------------
' navShowSeriesPage
'-------------------------------------------------------------------------------
sub navShowSeriesPage()
    if m.homePage <> invalid then m.homePage.visible = false
    if m.library <> invalid then
        m.library.visible = false
        m.library.callFunc("resetDrilldown")
    end if
    if m.seriesPage <> invalid then m.seriesPage.visible = true
end sub

'-------------------------------------------------------------------------------
' headerHandleDownPressed
'-------------------------------------------------------------------------------
sub headerHandleDownPressed()
    if m.homePage <> invalid and m.homePage.visible then
        focusHomePage()
        return
    end if

    if m.library <> invalid and m.library.visible then
        focusLibraryList()
        return
    end if

    if m.seriesPage <> invalid and m.seriesPage.visible then
        focusSeriesPage()
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
' focusHeader
'-------------------------------------------------------------------------------
sub focusHeader()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' focusHomePage
'-------------------------------------------------------------------------------
sub focusHomePage()
    if m.homePage <> invalid then m.homePage.callFunc("focusHomePage")
end sub

'-------------------------------------------------------------------------------
' focusLibraryList
'-------------------------------------------------------------------------------
sub focusLibraryList()
    if m.library <> invalid then m.library.callFunc("focusLibraryList")
end sub

'-------------------------------------------------------------------------------
' focusSeriesPage
'-------------------------------------------------------------------------------
sub focusSeriesPage()
    if m.seriesPage <> invalid then m.seriesPage.callFunc("focusSeriesPage")
end sub

'-------------------------------------------------------------------------------
' focusSettingsButton
'-------------------------------------------------------------------------------
sub focusSettingsButton()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusSettingsButton")
end sub

'-------------------------------------------------------------------------------
' focusUserMenuButton
'-------------------------------------------------------------------------------
sub focusUserMenuButton()
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusUserMenuButton")
end sub

'-------------------------------------------------------------------------------
' searchHandlePressed
'-------------------------------------------------------------------------------
sub searchHandlePressed()
    headerCloseMenu()
    if m.search <> invalid then m.search.callFunc("openSearch")
end sub

'-------------------------------------------------------------------------------
' searchHandleQuerySelected
'-------------------------------------------------------------------------------
sub searchHandleQuerySelected()
    if m.search = invalid then return

    selectedQuery = m.search.querySelected
    if selectedQuery = invalid then return

    searchTerm = TrimString(selectedQuery.query)
    if m.session = invalid then return

    if m.header <> invalid then m.header.callFunc("activateSearchButton")
    navShowLibraryPage()
    if m.library <> invalid then
        m.library.searchRequest = {
            searchTerm: searchTerm
            counter: selectedQuery.counter
        }
    end if
end sub

'===============================================================================
' Home
'===============================================================================

'-------------------------------------------------------------------------------
' homeHandlePressed
'-------------------------------------------------------------------------------
sub homeHandlePressed()
    headerCloseMenu()
    if m.library <> invalid then m.library.callFunc("resetSearchResults")
    navShowHomePage()
    focusHomePage()
    if m.homePage <> invalid then m.homePage.callFunc("reloadPersonalizedShelves")
end sub

'-------------------------------------------------------------------------------
' homeHandleBackSelected
'-------------------------------------------------------------------------------
sub homeHandleBackSelected()
    focusHeader()
end sub

'-------------------------------------------------------------------------------
' homeHandleUpFromFirstRowSelected
'-------------------------------------------------------------------------------
sub homeHandleUpFromFirstRowSelected()
    focusHeader()
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
' homeHandleError
'-------------------------------------------------------------------------------
sub homeHandleError()
    handleComponentError(m.homePage.errorResponse)
end sub

'===============================================================================
' Library
'===============================================================================

'-------------------------------------------------------------------------------
' libraryHandlePressed
'-------------------------------------------------------------------------------
sub libraryHandlePressed()
    headerCloseMenu()
    if m.library <> invalid then m.library.callFunc("resetSearchResults")
    navShowLibraryPage()
    focusLibraryList()
end sub

'-------------------------------------------------------------------------------
' libraryHandleCurrentLibrarySelected
'-------------------------------------------------------------------------------
sub libraryHandleCurrentLibrarySelected()
    if m.header = invalid then return
    if m.session = invalid then return

    selectedLibrary = m.header.currentLibrarySelected
    if selectedLibrary = invalid or selectedLibrary.id = invalid then return
    if selectedLibrary.id = m.session.bookLibraryId then return

    m.session.bookLibraryId = selectedLibrary.id
    m.header.currentLibraryId = m.session.bookLibraryId

    loadRequest = buildSessionLoadRequest()
    if m.library <> invalid then
        m.library.callFunc("resetNavigationState")
        m.library.loadRequest = loadRequest
    end if
    if m.homePage <> invalid then m.homePage.loadRequest = loadRequest
    if m.seriesPage <> invalid then
        m.seriesPage.callFunc("resetSeriesRows")
        m.seriesPage.loadRequest = loadRequest
    end if
    if m.libraryController <> invalid then m.libraryController.loadRequest = loadRequest
    if m.seriesPage <> invalid and m.seriesPage.visible = true then requestSeriesRows()
end sub

'-------------------------------------------------------------------------------
' libraryHandleSearchRequest
'-------------------------------------------------------------------------------
sub libraryHandleSearchRequest()
    if m.library = invalid then return
    if m.libraryController = invalid then return

    m.libraryController.searchRequest = m.library.controllerSearchRequest
end sub

'-------------------------------------------------------------------------------
' libraryHandleSeriesItemsRequest
'-------------------------------------------------------------------------------
sub libraryHandleSeriesItemsRequest()
    if m.library = invalid then return
    if m.libraryController = invalid then return

    m.libraryController.seriesItemsRequest = m.library.seriesItemsRequest
end sub

'-------------------------------------------------------------------------------
' libraryControllerHandleItemsChanged
'-------------------------------------------------------------------------------
sub libraryControllerHandleItemsChanged()
    if m.libraryController = invalid then return
    if m.library <> invalid then m.library.rootLibraryItems = m.libraryController.libraryItems
end sub

'-------------------------------------------------------------------------------
' libraryControllerHandleSearchResponse
'-------------------------------------------------------------------------------
sub libraryControllerHandleSearchResponse()
    if m.libraryController = invalid then return
    if m.library <> invalid then m.library.searchResponse = m.libraryController.searchResponse
end sub

'-------------------------------------------------------------------------------
' libraryControllerHandleSeriesItemsResponse
'-------------------------------------------------------------------------------
sub libraryControllerHandleSeriesItemsResponse()
    if m.libraryController = invalid then return
    if m.library <> invalid then m.library.seriesItemsResponse = m.libraryController.seriesItemsResponse
end sub

'-------------------------------------------------------------------------------
' libraryControllerHandleSeriesRowsResponse
'-------------------------------------------------------------------------------
sub libraryControllerHandleSeriesRowsResponse()
    if m.libraryController = invalid then return
    if m.seriesPage <> invalid then m.seriesPage.seriesRowsResponse = m.libraryController.seriesRowsResponse
end sub

'-------------------------------------------------------------------------------
' libraryControllerHandleError
'-------------------------------------------------------------------------------
sub libraryControllerHandleError()
    if m.libraryController = invalid then return

    response = m.libraryController.errorResponse
    if response = invalid then return
    if handleComponentError(response) then return
    if m.library <> invalid and m.library.visible = true then m.library.errorResponse = response
    if m.seriesPage <> invalid and m.seriesPage.visible = true then m.seriesPage.errorResponse = response
end sub

'-------------------------------------------------------------------------------
' libraryHandleError
'-------------------------------------------------------------------------------
sub libraryHandleError()
    handleComponentError(m.library.errorResponse)
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
' libraryHandleUpFromFirstItemSelected
'-------------------------------------------------------------------------------
sub libraryHandleUpFromFirstItemSelected()
    focusHeader()
end sub

'-------------------------------------------------------------------------------
' libraryHandleBackFromFirstItemSelected
'-------------------------------------------------------------------------------
sub libraryHandleBackFromFirstItemSelected()
    focusHeader()
end sub

'-------------------------------------------------------------------------------
' libraryHandleItemsReloaded
'-------------------------------------------------------------------------------
sub libraryHandleItemsReloaded()
    if m.focusSettingsAfterLibraryReload = true then
        m.focusSettingsAfterLibraryReload = false
        focusSettingsButton()
    end if
end sub

'-------------------------------------------------------------------------------
' libraryHandleMainListRestored
'-------------------------------------------------------------------------------
sub libraryHandleMainListRestored()
    if m.header <> invalid then m.header.callFunc("activateLibraryButton")
end sub

'===============================================================================
' Series
'===============================================================================

'-------------------------------------------------------------------------------
' seriesHandlePressed
'-------------------------------------------------------------------------------
sub seriesHandlePressed()
    headerCloseMenu()
    if m.library <> invalid then m.library.callFunc("resetSearchResults")
    navShowSeriesPage()
    requestSeriesRows()
    focusSeriesPage()
end sub

'-------------------------------------------------------------------------------
' requestSeriesRows
'-------------------------------------------------------------------------------
sub requestSeriesRows()
    if m.libraryController = invalid then return

    if m.seriesRowsRequestCounter = invalid then m.seriesRowsRequestCounter = 0
    m.seriesRowsRequestCounter = m.seriesRowsRequestCounter + 1
    m.libraryController.seriesRowsRequest = {
        action: "loadSeriesRows"
        counter: m.seriesRowsRequestCounter
    }
end sub

'-------------------------------------------------------------------------------
' seriesHandlePlaySelected
'-------------------------------------------------------------------------------
sub seriesHandlePlaySelected()
    selectedItem = m.seriesPage.playSelected
    m.playerReturnTarget = "series"
    playbackPlayItem(selectedItem)
end sub

'-------------------------------------------------------------------------------
' seriesHandleBackSelected
'-------------------------------------------------------------------------------
sub seriesHandleBackSelected()
    focusHeader()
end sub

'-------------------------------------------------------------------------------
' seriesHandleUpFromFirstRowSelected
'-------------------------------------------------------------------------------
sub seriesHandleUpFromFirstRowSelected()
    focusHeader()
end sub

'-------------------------------------------------------------------------------
' seriesHandleError
'-------------------------------------------------------------------------------
sub seriesHandleError()
    handleComponentError(m.seriesPage.errorResponse)
end sub

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
        startPositionSeconds: MediaProgressLookup_GetStartPosition(selectedItem, m.mediaProgress)
    }
end sub

'-------------------------------------------------------------------------------
' playbackHandlePlayerCloseRequested
'-------------------------------------------------------------------------------
sub playbackHandlePlayerCloseRequested()
    
    m.player.visible = false
    m.authenticatedContent.visible = true
    reloadHomeShelvesAfterPlayback()

    if m.playerReturnTarget = "home" and m.homePage <> invalid and m.homePage.visible then
        focusHomePage()
        return
    end if

    if m.playerReturnTarget = "series" and m.seriesPage <> invalid and m.seriesPage.visible then
        focusSeriesPage()
        return
    end if

    if m.library <> invalid and m.library.visible then
        focusLibraryList()
    end if

end sub

'-------------------------------------------------------------------------------
' playbackHandlePlayerError
'-------------------------------------------------------------------------------
sub playbackHandlePlayerError()
    response = m.player.errorResponse
    if response <> invalid and response.authExpired = true then
        playbackHandlePlayerCloseRequested()
    end if

    handleComponentError(response)
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
        focusSettingsButton()
        return
    end if

    if closed <> invalid and closed.request <> invalid and closed.request.id = "exit" and closed.overlay <> invalid then
        if closed.overlay.confirmed <> invalid and closed.overlay.confirmed > 0 then
            m.top.closeRequested = true
            return
        end if

        focusHeader()
        return
    end if

    focusUserMenuButton()
end sub

'-------------------------------------------------------------------------------
' overlayHandleSettingsSaved
'-------------------------------------------------------------------------------
sub overlayHandleSettingsSaved(savedSettings as dynamic)
    if savedSettings = invalid then return

    if m.library <> invalid then m.library.displaySettings = savedSettings
    if m.libraryController <> invalid then m.libraryController.displaySettings = savedSettings
    m.focusSettingsAfterLibraryReload = true
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
        if m.library <> invalid and m.library.callFunc("handleBackNavigation") then return true
    end if

    return false
end function
