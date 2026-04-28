'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.dialog = m.top.findNode("dialog")
    m.backdrop = m.top.findNode("backdrop")
    m.panel = m.top.findNode("panel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.titleRule = m.top.findNode("titleRule")
    m.content = m.top.findNode("content")

    initStyle()
    updateDialogSize()
    updateTitle()
    updateContentComponent()
end sub

'-------------------------------------------------------------------------------
' openDialog
'-------------------------------------------------------------------------------
sub openDialog()
    if m.dialog = invalid then return

    m.dialog.visible = true
    m.top.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' closeDialog
'-------------------------------------------------------------------------------
sub closeDialog()
    if m.dialog <> invalid then m.dialog.visible = false

    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    colors = Color()

    if m.backdrop <> invalid then m.backdrop.color = colors.dialog.backdrop
    if m.panel <> invalid then m.panel.color = colors.dialog.background
    if m.titleLabel <> invalid then m.titleLabel.color = &hF3F7FBFF
    if m.titleRule <> invalid then m.titleRule.color = &hF3F7FB33
end sub

'-------------------------------------------------------------------------------
' onTitleChanged
'-------------------------------------------------------------------------------
sub onTitleChanged()
    updateTitle()
end sub

'-------------------------------------------------------------------------------
' onDialogSizeChanged
'-------------------------------------------------------------------------------
sub onDialogSizeChanged()
    updateDialogSize()
end sub

'-------------------------------------------------------------------------------
' onContentComponentNameChanged
'-------------------------------------------------------------------------------
sub onContentComponentNameChanged()
    updateContentComponent()
end sub

'-------------------------------------------------------------------------------
' updateContentComponent
'-------------------------------------------------------------------------------
sub updateContentComponent()
    if m.content = invalid then return

    if m.contentComponent <> invalid then
        m.content.removeChild(m.contentComponent)
        m.contentComponent = invalid
    end if

    componentName = m.top.contentComponentName
    if componentName = invalid or componentName = "" then return

    m.contentComponent = CreateObject("roSGNode", componentName)
    if m.contentComponent <> invalid then m.content.appendChild(m.contentComponent)
end sub

'-------------------------------------------------------------------------------
' updateDialogSize
'-------------------------------------------------------------------------------
sub updateDialogSize()
    dialogWidth = getDialogSizeValue(m.top.dialogWidth, 1680)
    dialogHeight = getDialogSizeValue(m.top.dialogHeight, 900)
    panelX = int((1920 - dialogWidth) / 2)
    panelY = int((1080 - dialogHeight) / 2)
    contentMargin = 60
    innerWidth = dialogWidth - (contentMargin * 2)
    if innerWidth < 0 then innerWidth = dialogWidth

    if m.panel <> invalid then
        m.panel.translation = [panelX, panelY]
        m.panel.width = dialogWidth
        m.panel.height = dialogHeight
    end if

    if m.titleLabel <> invalid then
        m.titleLabel.translation = [panelX + contentMargin, panelY + 60]
        m.titleLabel.width = innerWidth
    end if

    if m.titleRule <> invalid then
        m.titleRule.translation = [panelX + contentMargin, panelY + 126]
        m.titleRule.width = innerWidth
    end if

    if m.content <> invalid then
        m.content.translation = [panelX + contentMargin, panelY + 170]
    end if
end sub

'-------------------------------------------------------------------------------
' getDialogSizeValue
'-------------------------------------------------------------------------------
function getDialogSizeValue(value as dynamic, defaultValue as integer) as integer
    if value = invalid or value <= 0 then return defaultValue
    return value
end function

'-------------------------------------------------------------------------------
' updateTitle
'-------------------------------------------------------------------------------
sub updateTitle()
    if m.titleLabel = invalid then return

    if m.top.title <> invalid and m.top.title <> "" then
        m.titleLabel.text = m.top.title
    else
        m.titleLabel.text = "Dialog"
    end if
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false
    if m.dialog = invalid or m.dialog.visible = false then return false

    if key = "back" or key = "OK" or key = "select" then
        closeDialog()
        return true
    end if

    return true
end function
