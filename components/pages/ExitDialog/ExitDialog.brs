'-------------------------------------------------------------------------------
' openConfirmation
'-------------------------------------------------------------------------------
sub openConfirmation()
    m.top.title = "Exit ABSTV?"
    m.top.dialogWidth = 800
    m.top.dialogHeight = 420
    m.top.contentComponentName = "ExitDialogContent"
    m.top.showButtons = true
    m.top.saveButtonText = "Exit"
    m.top.cancelButtonText = "Cancel"
    m.top.callFunc("openDialog")
    m.top.callFunc("focusSaveButton")
end sub

'-------------------------------------------------------------------------------
' closeConfirmation
'-------------------------------------------------------------------------------
sub closeConfirmation()
    closeDialogWithoutEvent()
end sub

'-------------------------------------------------------------------------------
' onSaveSelected
'-------------------------------------------------------------------------------
sub onSaveSelected()
    confirmExit()
end sub

'-------------------------------------------------------------------------------
' onCloseRequested
'-------------------------------------------------------------------------------
sub onCloseRequested()
    cancelExit()
end sub

'-------------------------------------------------------------------------------
' confirmExit
'-------------------------------------------------------------------------------
sub confirmExit()
    closeDialogWithoutEvent()

    if m.confirmedCounter = invalid then m.confirmedCounter = 0
    m.confirmedCounter = m.confirmedCounter + 1
    m.top.confirmed = m.confirmedCounter
end sub

'-------------------------------------------------------------------------------
' cancelExit
'-------------------------------------------------------------------------------
sub cancelExit()
    closeDialogWithoutEvent()

    if m.canceledCounter = invalid then m.canceledCounter = 0
    m.canceledCounter = m.canceledCounter + 1
    m.top.canceled = m.canceledCounter
end sub

'-------------------------------------------------------------------------------
' closeDialogWithoutEvent
'-------------------------------------------------------------------------------
sub closeDialogWithoutEvent()
    dialog = m.top.findNode("dialog")
    if dialog <> invalid then dialog.visible = false
end sub
