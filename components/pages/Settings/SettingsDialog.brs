'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.dialog = m.top.findNode("settingsDialog")
    m.backdrop = m.top.findNode("settingsBackdrop")
    m.panel = m.top.findNode("settingsPanel")
    m.title = m.top.findNode("settingsTitle")
    m.titleRule = m.top.findNode("settingsTitleRule")
    m.form = m.top.findNode("settingsForm")
    m.saveButton = m.top.findNode("saveButton")
    m.cancelButton = m.top.findNode("cancelButton")

    initStyle()
end sub

'-------------------------------------------------------------------------------
' openSettings
'-------------------------------------------------------------------------------
sub openSettings()
    if m.dialog = invalid then return

    m.dialog.visible = true
    m.top.setFocus(true)
    focusFormFirstField()
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    colors = Color()

    if m.panel <> invalid then m.panel.color = colors.background.primary
    if m.title <> invalid then m.title.color = &hF3F7FBFF
    if m.titleRule <> invalid then m.titleRule.color = &hF3F7FB33
end sub

'-------------------------------------------------------------------------------
' closeSettings
'-------------------------------------------------------------------------------
sub closeSettings()
    if m.dialog <> invalid then m.dialog.visible = false
    updateButtonFocus("")

    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' saveSettings
'-------------------------------------------------------------------------------
sub saveSettings()
    if m.form = invalid then return

    settings = m.form.callFunc("getSettingsValues")
    if settings = invalid then return

    SettingsStore_Save(settings.seriesDisplay, settings.itemDisplay)
end sub

'-------------------------------------------------------------------------------
' focusFormFirstField
'-------------------------------------------------------------------------------
sub focusFormFirstField()
    updateButtonFocus("")
    if m.form <> invalid then m.form.callFunc("focusFirstField")
end sub

'-------------------------------------------------------------------------------
' focusFormLastField
'-------------------------------------------------------------------------------
sub focusFormLastField()
    updateButtonFocus("")
    if m.form <> invalid then m.form.callFunc("focusLastField")
end sub

'-------------------------------------------------------------------------------
' focusSaveButton
'-------------------------------------------------------------------------------
sub focusSaveButton()
    updateButtonFocus("save")
    if m.saveButton <> invalid then m.saveButton.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' focusCancelButton
'-------------------------------------------------------------------------------
sub focusCancelButton()
    updateButtonFocus("cancel")
    if m.cancelButton <> invalid then m.cancelButton.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' updateButtonFocus
'-------------------------------------------------------------------------------
sub updateButtonFocus(focusedButton as string)
    if m.saveButton <> invalid then m.saveButton.hasFocusVisual = (focusedButton = "save")
    if m.cancelButton <> invalid then m.cancelButton.hasFocusVisual = (focusedButton = "cancel")
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    if m.dialog = invalid or m.dialog.visible = false then return false

    if key = "back" then
        closeSettings()
        return true
    end if

    if m.form <> invalid and m.form.isInFocusChain() then
        if key = "down" then
            focusSaveButton()
            return true
        end if

        return false
    end if

    if m.saveButton <> invalid and m.saveButton.isInFocusChain() then
        if key = "up" then
            focusFormLastField()
            return true
        else if key = "right" then
            focusCancelButton()
            return true
        else if key = "OK" or key = "select" then
            saveSettings()
            closeSettings()
            return true
        end if
    end if

    if m.cancelButton <> invalid and m.cancelButton.isInFocusChain() then
        if key = "up" then
            focusFormLastField()
            return true
        else if key = "left" then
            focusSaveButton()
            return true
        else if key = "OK" or key = "select" then
            closeSettings()
            return true
        end if
    end if

    return false
end function
