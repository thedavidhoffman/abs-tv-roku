'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.contentArea = m.top.findNode("contentArea")
    m.settingsCustomItem = invalid
    initContent()
    initStyle()
end sub

'-------------------------------------------------------------------------------
' initContent
'-------------------------------------------------------------------------------
sub initContent()
    if m.contentArea = invalid then return

    m.settingsCustomItem = CreateObject("roSGNode", "SettingsCustomItem")
    m.contentArea.appendChild(m.settingsCustomItem)
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    colors = Color()
    palette = CreateObject("roSGNode", "RSGPalette")
    palette.colors = {
        DialogBackgroundColor: colors.dialog.backgroundHex
        DialogTextColor: colors.dialog.textHex
        DialogFocusColor: colors.dialog.focusHex
        DialogFocusItemColor: colors.dialog.focusTextHex
        DialogSecondaryItemColor: colors.dialog.secondaryHex
        DialogFootprintColor: colors.dialog.footprintHex
    }

    m.top.palette = palette
end sub

'-------------------------------------------------------------------------------
' focusCustomItem
'-------------------------------------------------------------------------------
sub focusCustomItem()
    if m.settingsCustomItem <> invalid then m.settingsCustomItem.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "up" and m.top.buttonFocused = 0 then
        focusCustomItem()
        return true
    end if

    return false
end function
