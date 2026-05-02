'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.backdrop = m.top.findNode("backdrop")
    m.panel = m.top.findNode("panel")
    m.exitButton = m.top.findNode("exitButton")
    m.cancelButton = m.top.findNode("cancelButton")
    m.confirmedCounter = 0
    m.canceledCounter = 0
    m.focusedAction = "exit"

    initStyle()
    updateButtonFocus()
end sub

'-------------------------------------------------------------------------------
' openConfirmation
'-------------------------------------------------------------------------------
sub openConfirmation()
    m.top.visible = true
    m.focusedAction = "exit"
    updateButtonFocus()
    m.top.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' closeConfirmation
'-------------------------------------------------------------------------------
sub closeConfirmation()
    m.top.visible = false
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    if m.backdrop <> invalid then m.backdrop.color = palette.dialog.backdrop
    if m.panel <> invalid then m.panel.color = palette.dialog.background
end sub

'-------------------------------------------------------------------------------
' confirmExit
'-------------------------------------------------------------------------------
sub confirmExit()
    closeConfirmation()
    m.confirmedCounter = m.confirmedCounter + 1
    m.top.confirmed = m.confirmedCounter
end sub

'-------------------------------------------------------------------------------
' cancelExit
'-------------------------------------------------------------------------------
sub cancelExit()
    closeConfirmation()
    m.canceledCounter = m.canceledCounter + 1
    m.top.canceled = m.canceledCounter
end sub

'-------------------------------------------------------------------------------
' updateButtonFocus
'-------------------------------------------------------------------------------
sub updateButtonFocus()
    if m.exitButton <> invalid then m.exitButton.hasFocusVisual = (m.focusedAction = "exit")
    if m.cancelButton <> invalid then m.cancelButton.hasFocusVisual = (m.focusedAction = "cancel")
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    if m.top.visible <> true then return false

    if key = "OK" or key = "select" then
        if m.focusedAction = "cancel" then
            cancelExit()
        else
            confirmExit()
        end if
        return true
    end if

    if key = "back" then
        cancelExit()
        return true
    end if

    if key = "left" then
        m.focusedAction = "exit"
        updateButtonFocus()
        return true
    end if

    if key = "right" then
        m.focusedAction = "cancel"
        updateButtonFocus()
        return true
    end if

    return false
end function
