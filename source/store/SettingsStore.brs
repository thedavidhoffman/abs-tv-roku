'-------------------------------------------------------------------------------
' Settings Registry Storage
'-------------------------------------------------------------------------------
' roRegistrySection is Roku's persistent key/value storage API. This app uses the
' registry to remember display preferences for series and library items.
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
sub SettingsStore_Save(seriesDisplay as string, itemDisplay as string)
    settingsStore = GetSettingsStore()
    settingsStore.Write("series-display", seriesDisplay)
    settingsStore.Write("item-display", itemDisplay)
    settingsStore.Flush()
end sub

'-------------------------------------------------------------------------------
' SettingsStore_Load
'-------------------------------------------------------------------------------
function SettingsStore_Load() as object
    settingsStore = GetSettingsStore()
    settings = {}
    settings["series-display"] = SettingsStore_ReadValue(settingsStore, "series-display", "collapse")
    settings["item-display"] = SettingsStore_ReadValue(settingsStore, "item-display", "list")
    return settings
end function

'-------------------------------------------------------------------------------
' SettingsStore_ReadValue
'-------------------------------------------------------------------------------
function SettingsStore_ReadValue(settingsStore as object, key as string, defaultValue as string) as string
    value = settingsStore.Read(key)
    if value = invalid or value = "" then return defaultValue
    return value
end function
