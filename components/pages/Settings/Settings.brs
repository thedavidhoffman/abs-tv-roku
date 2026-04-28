'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.dialog = invalid
end sub

'-------------------------------------------------------------------------------
' openSettings
'-------------------------------------------------------------------------------
sub openSettings()
    scene = m.top.getScene()
    if scene = invalid then return

    m.dialog = CreateObject("roSGNode", "SettingsDialog")
    m.dialog.observeField("buttonSelected", "onDialogButtonSelected")
    scene.dialog = m.dialog
    m.dialog.callFunc("focusCustomItem")
end sub

'-------------------------------------------------------------------------------
' onDialogButtonSelected
'-------------------------------------------------------------------------------
sub onDialogButtonSelected()
    scene = m.top.getScene()
    if scene <> invalid then scene.dialog = invalid

    m.dialog = invalid
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub
