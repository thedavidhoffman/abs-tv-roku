'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.bg = m.top.findNode("bg")
    m.login = m.top.findNode("login")
    m.authenticatedContent = m.top.findNode("authenticatedContent")
    m.header = m.top.findNode("header")
    m.library = m.top.findNode("library")
    m.settings = m.top.findNode("settings")
    m.diagnostics = m.top.findNode("diagnostics")
    m.player = m.top.findNode("player")
    m.apiTask = m.top.findNode("apiTask")

    m.login.observeField("loginSucceeded", "onLoginSucceeded")
    m.header.observeField("downSelected", "onHeaderDownPressed")
    m.header.observeField("settingsSelected", "onSettingsPressed")
    m.header.observeField("logoutSelected", "onLogoutPressed")
    m.header.observeField("changeServerSelected", "onChangeServerPressed")
    m.header.observeField("usernameUpSequenceSelected", "onDiagnosticsSequencePressed")
    m.library.observeField("errorResponse", "onLibraryError")
    m.library.observeField("playSelected", "onLibraryPlaySelected")
    m.library.observeField("seriesSelected", "onLibrarySeriesSelected")
    m.player.observeField("closeRequested", "onPlayerCloseRequested")
    m.player.observeField("errorResponse", "onPlayerError")
    m.settings.observeField("closeRequested", "onSettingsCloseRequested")
    m.settings.observeField("settingsSaved", "onSettingsSaved")
    m.diagnostics.observeField("closeRequested", "onDiagnosticsCloseRequested")
    m.apiTask.observeField("response", "onApiResponse")

    m.session = AuthStore_Load()
    m.isResumingSession = false
    m.loginActivationCounter = 0
    m.libraryItemBackStack = []

    preloadSavedFields()
    initStyle()
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
            AuthStore_Clear(false)
            showLogin("Your saved session expired. Please sign in again.")
            return
        end if

        if response.authExpired = true then
            handleExpiredSession(response.errorMessage)
            return
        end if

        if m.login.visible then m.login.statusMessage = "Login failed: " + SafeString(response.errorMessage, "Unknown error.")
        return
    end if

    action = response.action
    if action = "authorize" then
        m.isResumingSession = false
        storeAuthenticatedSession(response)
        showApp()
        return
    else if action = "loadLibrary" then
        storeLibraryItems(response)
        return
    else if action = "loadSeries" then
        storeSeriesItems(response)
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
        m.header.username = m.session.username
    end if
    if m.library <> invalid then
        m.library.visible = true
        m.library.loadRequest = {
            server: m.session.server
            token: m.session.token
            bookLibraryId: m.session.bookLibraryId
        }
    end if
end sub

'-------------------------------------------------------------------------------
' onHeaderDownPressed
'-------------------------------------------------------------------------------
sub onHeaderDownPressed()
    if m.library <> invalid and m.library.visible then
        m.library.callFunc("focusLibraryList")
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
' onLibrarySeriesSelected
'-------------------------------------------------------------------------------
sub onLibrarySeriesSelected()
    selectedSeries = m.library.seriesSelected
    if selectedSeries = invalid or selectedSeries.seriesId = invalid then return
    if m.session = invalid then return
    if m.apiTask = invalid then return

    m.apiTask.request = {
        action: "loadSeries"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
        seriesId: selectedSeries.seriesId
        sourceItemIndex: selectedSeries.itemIndex
    }
    m.apiTask.control = "run"
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
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
end sub

'-------------------------------------------------------------------------------
' onSettingsSaved
'-------------------------------------------------------------------------------
sub onSettingsSaved()
    if m.library <> invalid and m.settings <> invalid then
        m.library.displaySettings = m.settings.savedSettings
    end if
    reloadLibraryItems()
end sub

'-------------------------------------------------------------------------------
' reloadLibraryItems
'-------------------------------------------------------------------------------
sub reloadLibraryItems()
    if m.session = invalid then return
    if m.session.server = invalid or m.session.server = "" then return
    if m.session.token = invalid or m.session.token = "" then return
    if m.apiTask = invalid then return

    m.apiTask.request = {
        action: "loadLibrary"
        server: m.session.server
        token: m.session.token
        bookLibraryId: m.session.bookLibraryId
    }
    m.apiTask.control = "run"
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
    if m.header <> invalid and m.header.visible then m.header.callFunc("focusHeader")
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
        m.apiTask.request = {
            action: "logout"
            server: m.session.server
            token: m.session.token
        }
        m.apiTask.control = "run"
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
        if restorePreviousLibraryItems() then return true

        if m.header <> invalid and m.header.visible and not m.header.isInFocusChain() then
            if m.header.callFunc("focusHeader") then return true
        end if
    end if

    return false
end function
