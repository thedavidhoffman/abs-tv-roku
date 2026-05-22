'-------------------------------------------------------------------------------
' Settings Registry Storage
'-------------------------------------------------------------------------------
' roRegistrySection is Roku's persistent key/value storage API. This app uses the
' registry to remember display preferences and screensaver settings.
'
'-------------------------------------------------------------------------------
' GetSettingsStore
'-------------------------------------------------------------------------------
function GetSettingsStore() as object
    return CreateObject("roRegistrySection", "ABSTV")
end function

'-------------------------------------------------------------------------------
' SettingsStore_Save
'-------------------------------------------------------------------------------
sub SettingsStore_Save(seriesDisplay as string, itemDisplay as string, gridColumns as string, screensaverType as string, screensaverDelay as string)
    settingsStore = GetSettingsStore()
    settingsStore.Write("series-display", seriesDisplay)
    settingsStore.Write("item-display", itemDisplay)
    settingsStore.Write("grid-columns", gridColumns)
    settingsStore.Write("screensaver-type", screensaverType)
    settingsStore.Write("screensaver-delay", screensaverDelay)
    settingsStore.Flush()
end sub

'-------------------------------------------------------------------------------
' SettingsStore_Load
'-------------------------------------------------------------------------------
function SettingsStore_Load() as object
    settingsStore = GetSettingsStore()
    settings = {}
    settings["series-display"] = SettingsStore_ReadValue(settingsStore, "series-display", "collapse")
    settings["item-display"] = SettingsStore_ReadValue(settingsStore, "item-display", "grid")
    settings["grid-columns"] = SettingsStore_ReadValue(settingsStore, "grid-columns", "6")
    settings["screensaver-type"] = SettingsStore_ReadValue(settingsStore, "screensaver-type", "off")
    settings["screensaver-delay"] = SettingsStore_ReadValue(settingsStore, "screensaver-delay", "1")
    return settings
end function

'-------------------------------------------------------------------------------
' SettingsStore_Clear
'-------------------------------------------------------------------------------
sub SettingsStore_Clear()
    settingsStore = GetSettingsStore()
    settingsStore.Delete("series-display")
    settingsStore.Delete("item-display")
    settingsStore.Delete("grid-columns")
    settingsStore.Delete("screensaver-type")
    settingsStore.Delete("screensaver-delay")
    settingsStore.Flush()
end sub

'-------------------------------------------------------------------------------
' SettingsStore_ReadValue
'-------------------------------------------------------------------------------
function SettingsStore_ReadValue(settingsStore as object, key as string, defaultValue as string) as string
    value = settingsStore.Read(key)
    if value = invalid or value = "" then return defaultValue
    return value
end function
