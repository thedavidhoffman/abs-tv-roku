'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()

    m.log = CreateLogger("ScreensaverOverlay", false)
    m.log.write("init")

    m.screensaverDelayTimer = m.top.findNode("screensaverDelayTimer")
    m.screensaverLayer = m.top.findNode("screensaverLayer")
    m.activeScreensaver = invalid
    m.screensaverType = "off"
    m.screensaverEnabled = false

    m.screensaverDelayTimer.observeField("fire", "onScreensaverDelayTimerFired")

end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    if isVisible() <> true then return false

    recordActivity()
    return true
end function

'-------------------------------------------------------------------------------
' startDelay
'-------------------------------------------------------------------------------
sub startDelay()

    m.log.write("startDelay")

    stopDelayTimer()

    settings = getDisplaySettings()
    m.screensaverType = getScreensaverType(settings)

    ' if the screensaver is already running, then return out
    m.screensaverEnabled = (m.screensaverType <> "off")
    if m.screensaverEnabled <> true then return

    ' start the timer
    m.screensaverDelayTimer.duration = getScreensaverDelaySeconds(settings)
    m.screensaverDelayTimer.control = "start"
    
end sub

'-------------------------------------------------------------------------------
' stopOverlay
'-------------------------------------------------------------------------------
sub stopOverlay()

    m.log.write("stopOverlay")

    stopDelayTimer()
    removeScreensaver()
end sub

'-------------------------------------------------------------------------------
' recordActivity
'-------------------------------------------------------------------------------
function recordActivity() as boolean

    m.log.write("recordActivity")

    wasVisible = isVisible()

    if wasVisible then
        removeScreensaver()
        publishDismissed()
    end if
    if m.screensaverEnabled <> true then return wasVisible
    startDelay()

    return wasVisible
end function

'-------------------------------------------------------------------------------
' isVisible
'-------------------------------------------------------------------------------
function isVisible() as boolean
    return m.activeScreensaver <> invalid
end function

'-------------------------------------------------------------------------------
' stopDelayTimer
'-------------------------------------------------------------------------------
sub stopDelayTimer()
    if m.screensaverDelayTimer <> invalid then m.screensaverDelayTimer.control = "stop"
end sub

'-------------------------------------------------------------------------------
' onScreensaverDelayTimerFired
'-------------------------------------------------------------------------------
sub onScreensaverDelayTimerFired()

    m.log.write("onScreensaverDelayTimerFired")

    stopDelayTimer()
    showConfiguredScreensaver()
end sub

'-------------------------------------------------------------------------------
' showConfiguredScreensaver
'-------------------------------------------------------------------------------
sub showConfiguredScreensaver()

    m.log.write("showConfiguredScreensaver")

    if m.screensaverLayer = invalid then return

    settings = getDisplaySettings()
    m.screensaverType = getScreensaverType(settings)
    m.screensaverEnabled = (m.screensaverType <> "off")
    if m.screensaverEnabled <> true then return

    removeScreensaver()

    componentName = ""
    if m.screensaverType = "bounce" then
        componentName = "Bounce"
    else if m.screensaverType = "starfield" then
        componentName = "Starfield"
    end if
    if componentName = "" then return

    screensaver = CreateObject("roSGNode", componentName)
    if screensaver = invalid then return

    if m.screensaverType = "bounce" then updateBounceScreensaverNode(screensaver)
    m.screensaverLayer.appendChild(screensaver)
    m.activeScreensaver = screensaver
    m.top.setFocus(true)
    publishShown()
end sub

'-------------------------------------------------------------------------------
' publishShown
'-------------------------------------------------------------------------------
sub publishShown()
    m.top.shown = true
end sub

'-------------------------------------------------------------------------------
' publishDismissed
'-------------------------------------------------------------------------------
sub publishDismissed()
    m.top.dismissed = true
end sub

'-------------------------------------------------------------------------------
' removeScreensaver
'-------------------------------------------------------------------------------
sub removeScreensaver()

    m.log.write("removeScreensaver")

    if m.screensaverLayer <> invalid then
        while m.screensaverLayer.getChildCount() > 0
            child = m.screensaverLayer.getChild(0)
            if child = invalid then exit while
            m.screensaverLayer.removeChild(child)
        end while
    end if

    m.activeScreensaver = invalid
end sub

'-------------------------------------------------------------------------------
' updateBounceScreensaverNode
'-------------------------------------------------------------------------------
sub updateBounceScreensaverNode(screensaver as object)

    m.log.write("updateBounceScreensaverNode")

    request = m.top.playbackRequest
    if screensaver = invalid or request = invalid then return

    screensaver.server = SafeString(request.server, "")
    screensaver.token = SafeString(request.token, "")
    screensaver.itemId = SafeString(request.itemId, "")
end sub

'-------------------------------------------------------------------------------
' getScreensaverType
'-------------------------------------------------------------------------------
function getScreensaverType(settings as dynamic) as string
    if settings = invalid then return "off"

    keys = SettingsStore_Keys()
    screensaverType = SafeString(settings[keys.screensaverType], "off")
    if screensaverType = "bounce" or screensaverType = "starfield" then return screensaverType

    return "off"
end function

'-------------------------------------------------------------------------------
' getDisplaySettings
'-------------------------------------------------------------------------------
function getDisplaySettings() as dynamic
    return m.top.displaySettings
end function

'-------------------------------------------------------------------------------
' getScreensaverDelaySeconds
'-------------------------------------------------------------------------------
function getScreensaverDelaySeconds(settings as dynamic) as integer
    if settings = invalid then return 60

    keys = SettingsStore_Keys()
    delayMinutes = int(val(SafeString(settings[keys.screensaverDelay], "1")))
    if delayMinutes <> 1 and delayMinutes <> 5 and delayMinutes <> 15 and delayMinutes <> 30 then delayMinutes = 1

    return delayMinutes * 60
end function
