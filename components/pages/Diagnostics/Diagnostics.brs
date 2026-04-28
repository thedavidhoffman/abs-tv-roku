'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.dialog = m.top.findNode("diagnosticsDialog")
    m.backdrop = m.top.findNode("diagnosticsBackdrop")
    m.panel = m.top.findNode("diagnosticsPanel")
    m.title = m.top.findNode("diagnosticsTitle")
    m.titleRule = m.top.findNode("diagnosticsTitleRule")
    m.deviceSectionTitle = m.top.findNode("deviceSectionTitle")
    m.deviceInfoKeysLabel = m.top.findNode("deviceInfoKeysLabel")
    m.deviceInfoValuesLabel = m.top.findNode("deviceInfoValuesLabel")
    m.registrySectionTitle = m.top.findNode("registrySectionTitle")
    m.registryKeysLabel = m.top.findNode("registryKeysLabel")
    m.registryValuesLabel = m.top.findNode("registryValuesLabel")

    initStyle()
end sub

'-------------------------------------------------------------------------------
' openDiagnostics
'-------------------------------------------------------------------------------
sub openDiagnostics()
    if m.dialog = invalid then return

    updateDiagnostics()
    m.dialog.visible = true
    m.top.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    colors = Color()

    if m.backdrop <> invalid then m.backdrop.color = colors.dialog.backdrop
    if m.panel <> invalid then m.panel.color = colors.dialog.background
    if m.title <> invalid then m.title.color = &hF3F7FBFF
    if m.titleRule <> invalid then m.titleRule.color = &hF3F7FB33
    setSectionTitleColor(m.deviceSectionTitle)
    setSectionTitleColor(m.registrySectionTitle)
    setBodyColor(m.deviceInfoKeysLabel)
    setBodyColor(m.deviceInfoValuesLabel)
    setBodyColor(m.registryKeysLabel)
    setBodyColor(m.registryValuesLabel)
end sub

'-------------------------------------------------------------------------------
' setSectionTitleColor
'-------------------------------------------------------------------------------
sub setSectionTitleColor(label as dynamic)
    if label <> invalid then label.color = &hF3F7FBFF
end sub

'-------------------------------------------------------------------------------
' setBodyColor
'-------------------------------------------------------------------------------
sub setBodyColor(label as dynamic)
    if label <> invalid then label.color = &hD5E0EAFF
end sub

'-------------------------------------------------------------------------------
' updateDiagnostics
'-------------------------------------------------------------------------------
sub updateDiagnostics()
    deviceInfoText = getDeviceInfoText()
    registryText = getApplicationRegistryText()

    setLabelText(m.deviceInfoKeysLabel, deviceInfoText.keys)
    setLabelText(m.deviceInfoValuesLabel, deviceInfoText.values)
    setLabelText(m.registryKeysLabel, registryText.keys)
    setLabelText(m.registryValuesLabel, registryText.values)
end sub

'-------------------------------------------------------------------------------
' getDeviceInfoText
'-------------------------------------------------------------------------------
function getDeviceInfoText() as object
    deviceInfo = CreateObject("roDeviceInfo")
    appInfo = CreateObject("roAppInfo")

    model = deviceInfo.GetModel()
    modelDisplayName = deviceInfo.GetModelDisplayName()
    osVersion = deviceInfo.GetOSVersion()
    uiResolution = deviceInfo.GetUIResolution()
    displaySize = deviceInfo.GetDisplaySize()
    displayMode = deviceInfo.GetDisplayMode()
    connectionInfo = deviceInfo.GetConnectionInfo()
    isDev = appInfo.IsDev()

    return keyValueText([
        { key: "model", value: modelDisplayName + " " + model }
        { key: "os version", value: osVersion }
        { key: "ui resolution", value: uiResolution }
        { key: "display mode", value: displayMode }
        { key: "connection Info", value: connectionInfo.type + " (" + LCase(connectionInfo.quality) + " quality)" }
        { key: "is Dev", value: isDev }
    ])
end function

'-------------------------------------------------------------------------------
' getApplicationRegistryText
'-------------------------------------------------------------------------------
function getApplicationRegistryText() as object
    auth = AuthStore_Load()
    settings = SettingsStore_Load()

    return keyValueText([
        { key: "server", value: auth.server }
        { key: "username", value: auth.username }
        { key: "userId", value: auth.userId }
        { key: "token", value: truncateText(auth.token, 50) + "..." }
        { key: "series-display", value: settings["series-display"] }
        { key: "item-display", value: settings["item-display"] }
    ])
end function

'-------------------------------------------------------------------------------
' truncateText
'-------------------------------------------------------------------------------
function truncateText(value as dynamic, maxLength as integer) as string
    text = formatValue(value)
    if Len(text) <= maxLength then return text
    return Left(text, maxLength)
end function

'-------------------------------------------------------------------------------
' keyValueText
'-------------------------------------------------------------------------------
function keyValueText(entries as object) as object
    keys = ""
    values = ""

    for each entry in entries
        if keys <> "" then
            keys = keys + Chr(10)
            values = values + Chr(10)
        end if

        keys = keys + UCase(entry.key) + ":"
        values = values + formatValue(entry.value)
    end for

    return {
        keys: keys
        values: values
    }
end function

'-------------------------------------------------------------------------------
' joinKeyValues
'-------------------------------------------------------------------------------
function joinKeyValues(lines as object) as string
    text = ""

    for each line in lines
        if text <> "" then text = text + Chr(10)
        text = text + line
    end for

    return text
end function

'-------------------------------------------------------------------------------
' formatValue
'-------------------------------------------------------------------------------
function formatValue(value as dynamic) as string
    if value = invalid then return "(not set)"

    valueType = Type(value)
    if valueType = "roAssociativeArray" or valueType = "roSGNodeEvent" then
        return formatAssocArray(value)
    end if

    if valueType = "roArray" then return formatArray(value)
    if valueType = "String" or valueType = "roString" then return value
    if valueType = "Boolean" or valueType = "roBoolean" then
        if value then return "true"
        return "false"
    end if
    if valueType = "Integer" or valueType = "roInt" or valueType = "LongInteger" or valueType = "roLongInteger" then return StrI(value)
    if valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" then return Str(value)

    return "(unsupported " + valueType + ")"
end function

'-------------------------------------------------------------------------------
' formatAssocArrayMultiline
'-------------------------------------------------------------------------------
function formatAssocArrayMultiline(value as dynamic) as string
    if value = invalid then return "(not set)"

    text = ""
    for each key in value
        if text <> "" then text = text + Chr(10)
        text = text + key + ": " + formatValue(value[key])
    end for

    return text
end function

'-------------------------------------------------------------------------------
' formatAssocArray
'-------------------------------------------------------------------------------
function formatAssocArray(value as object) as string
    text = "{"
    isFirst = true

    for each key in value
        if isFirst then
            isFirst = false
        else
            text = text + ", "
        end if

        text = text + key + ": " + formatValue(value[key])
    end for

    return text + "}"
end function

'-------------------------------------------------------------------------------
' formatArray
'-------------------------------------------------------------------------------
function formatArray(value as object) as string
    text = "["
    isFirst = true

    for each item in value
        if isFirst then
            isFirst = false
        else
            text = text + ", "
        end if

        text = text + formatValue(item)
    end for

    return text + "]"
end function

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

'-------------------------------------------------------------------------------
' closeDiagnostics
'-------------------------------------------------------------------------------
sub closeDiagnostics()
    if m.dialog <> invalid then m.dialog.visible = false

    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    if m.dialog = invalid or m.dialog.visible = false then return false

    if key = "back" or key = "OK" or key = "select" then
        closeDiagnostics()
        return true
    end if

    return true
end function
