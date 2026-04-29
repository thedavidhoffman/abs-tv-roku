'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.settingsSavedCounter = 0
    m.dialog = m.top.findNode("settingsDialog")

    if m.dialog <> invalid then
        m.dialog.observeField("closeRequested", "onDialogCloseRequested")
    end if
end sub

'-------------------------------------------------------------------------------
' openSettings
'-------------------------------------------------------------------------------
sub openSettings()
    if m.dialog = invalid then return

    content = getSettingsContent()
    if content <> invalid then content.callFunc("loadSettingsValues")
    m.dialog.callFunc("openDialog")
    if content <> invalid then content.callFunc("focusFirstField")
end sub

'-------------------------------------------------------------------------------
' getSettingsContent
'-------------------------------------------------------------------------------
function getSettingsContent() as object
    if m.dialog = invalid then return invalid
    return m.dialog.callFunc("getContentComponent")
end function

'-------------------------------------------------------------------------------
' saveSettings
'-------------------------------------------------------------------------------
sub saveSettings()
    content = getSettingsContent()
    if content = invalid then return

    settings = content.callFunc("getSettingsValues")
    if settings = invalid then return

    SettingsStore_Save(settings.seriesDisplay, settings.itemDisplay)
    m.top.savedSettings = settings
    m.settingsSavedCounter = m.settingsSavedCounter + 1
    m.top.settingsSaved = m.settingsSavedCounter
end sub

'-------------------------------------------------------------------------------
' onDialogCloseRequested
'-------------------------------------------------------------------------------
sub onDialogCloseRequested()
    saveSettings()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub
