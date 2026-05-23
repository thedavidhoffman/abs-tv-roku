'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.settingsSavedCounter = 0
    m.originalSettings = invalid
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
    if content <> invalid then
        content.callFunc("loadSettingsValues")
        m.originalSettings = content.callFunc("getSettingsValues")
    end if
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
    if areSettingsEqual(settings, m.originalSettings) then return

    keys = SettingsStore_Keys()
    SettingsStore_Save(settings[keys.seriesDisplay], settings[keys.itemDisplay], settings[keys.gridColumns], settings[keys.screensaverType], settings[keys.screensaverDelay])
    m.top.savedSettings = settings
    m.settingsSavedCounter = m.settingsSavedCounter + 1
    m.top.settingsSaved = m.settingsSavedCounter
end sub

'-------------------------------------------------------------------------------
' areSettingsEqual
'-------------------------------------------------------------------------------
function areSettingsEqual(settings as dynamic, previousSettings as dynamic) as boolean
    if settings = invalid or previousSettings = invalid then return false

    keys = SettingsStore_Keys()
    return settings[keys.seriesDisplay] = previousSettings[keys.seriesDisplay] and settings[keys.itemDisplay] = previousSettings[keys.itemDisplay] and settings[keys.gridColumns] = previousSettings[keys.gridColumns] and settings[keys.screensaverType] = previousSettings[keys.screensaverType] and settings[keys.screensaverDelay] = previousSettings[keys.screensaverDelay]
end function

'-------------------------------------------------------------------------------
' onDialogCloseRequested
'-------------------------------------------------------------------------------
sub onDialogCloseRequested()
    saveSettings()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub
