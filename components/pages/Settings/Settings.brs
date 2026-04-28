'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.settingsBackdrop = m.top.findNode("settingsBackdrop")
    m.settingsPanel = m.top.findNode("settingsPanel")
    m.closeRequestedCounter = 0
    initStyle()
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    if m.settingsBackdrop <> invalid then m.settingsBackdrop.color = palette.background.backdrop
    if m.settingsPanel <> invalid then m.settingsPanel.color = palette.background.primary
end sub

'-------------------------------------------------------------------------------
' closeSettings
'-------------------------------------------------------------------------------
sub closeSettings()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "back" then
        closeSettings()
        return true
    end if

    return false
end function
