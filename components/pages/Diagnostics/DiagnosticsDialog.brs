'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.dialog = m.top.findNode("diagnosticsDialog")
    if m.dialog <> invalid then m.dialog.observeField("closeRequested", "onDialogCloseRequested")
end sub

'-------------------------------------------------------------------------------
' openDiagnostics
'-------------------------------------------------------------------------------
sub openDiagnostics()
    if m.dialog = invalid then return

    content = m.dialog.callFunc("getContentComponent")
    if content <> invalid then content.callFunc("updateDiagnostics")
    m.dialog.callFunc("openDialog")
end sub

'-------------------------------------------------------------------------------
' onDialogCloseRequested
'-------------------------------------------------------------------------------
sub onDialogCloseRequested()
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub
