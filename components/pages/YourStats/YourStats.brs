'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.log = CreateLogger("YourStats")

    initReferences()
    initValues()
    initHandlers()
    initStyle()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.titleLabel = m.top.findNode("titleLabel")
    m.sevenDayGraph = m.top.findNode("sevenDayGraph")
    m.yourStatsApiTask = m.top.findNode("yourStatsApiTask")
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.requestState = {
        loadRequest: invalid
        isLoading: false
    }
end sub

'-------------------------------------------------------------------------------
' initHandlers
'-------------------------------------------------------------------------------
sub initHandlers()
    m.yourStatsApiTask.observeField("response", "onYourStatsApiResponse")
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    if m.titleLabel <> invalid then m.titleLabel.color = palette.text.primary
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    m.requestState.loadRequest = m.top.loadRequest
end sub

'-------------------------------------------------------------------------------
' loadStats
'-------------------------------------------------------------------------------
sub loadStats()
    m.log.write("loadStats")

    loadRequest = m.requestState.loadRequest
    if loadRequest = invalid then return
    if loadRequest.server = invalid or loadRequest.server = "" then return
    if loadRequest.token = invalid or loadRequest.token = "" then return
    if m.yourStatsApiTask = invalid then return

    m.requestState.isLoading = true
    m.top.statusMessage = "Loading..."
    m.yourStatsApiTask.request = {
        action: "loadYourStats"
        server: loadRequest.server
        token: loadRequest.token
    }
    m.yourStatsApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onYourStatsApiResponse
'-------------------------------------------------------------------------------
sub onYourStatsApiResponse()
    response = m.yourStatsApiTask.response
    if response = invalid then return

    m.requestState.isLoading = false

    if response.ok <> true then
        m.top.statusMessage = SafeString(response.errorMessage, "Unable to load your stats.")
        m.top.errorResponse = response
        return
    end if

    m.top.stats = response.stats
    if m.sevenDayGraph <> invalid then m.sevenDayGraph.stats = response.stats
    m.top.statusMessage = ""
end sub

'-------------------------------------------------------------------------------
' focusYourStats
'-------------------------------------------------------------------------------
function focusYourStats() as boolean
    m.top.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "back" or key = "up" then
        m.top.backSelected = true
        return true
    end if

    return false
end function
