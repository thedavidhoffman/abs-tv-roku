'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.closeRequestedCounter = 0
    m.querySelectedCounter = 0
    m.keyboardDialog = invalid
    m.isClosingDialog = false
    m.hasEmittedClose = false
end sub

'-------------------------------------------------------------------------------
' openSearch
'-------------------------------------------------------------------------------
sub openSearch()
    scene = m.top.getScene()
    if scene = invalid then return

    m.isClosingDialog = false
    m.hasEmittedClose = false
    m.keyboardDialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    if m.keyboardDialog = invalid then return

    m.keyboardDialog.title = "Search"
    m.keyboardDialog.message = ["Enter a search term between " + SearchRules_MinLength().ToStr() + " and " + SearchRules_MaxLength().ToStr() + " characters to find audiobooks by title or author.", "If you click the Search button without entering the required minimum number of characters, the dialog will close and no search will be performed."]
    m.keyboardDialog.buttons = ["Search", "Cancel"]
    m.keyboardDialog.observeField("buttonSelected", "onButtonSelected")
    m.keyboardDialog.observeField("wasClosed", "onDialogClosed")
    scene.dialog = m.keyboardDialog
end sub

'-------------------------------------------------------------------------------
' onButtonSelected
'-------------------------------------------------------------------------------
sub onButtonSelected()
    if m.keyboardDialog = invalid then return

    selectedIndex = m.keyboardDialog.buttonSelected
    if selectedIndex = 0 then
        query = SearchRules_NormalizeTerm(m.keyboardDialog.text)
        if Len(query) >= SearchRules_MinLength() then
            m.querySelectedCounter = m.querySelectedCounter + 1
            m.top.querySelected = {
                query: query
                counter: m.querySelectedCounter
            }
        end if
    end if

    closeSearchDialog()
end sub

'-------------------------------------------------------------------------------
' onDialogClosed
'-------------------------------------------------------------------------------
sub onDialogClosed()
    emitCloseRequested()
end sub

'-------------------------------------------------------------------------------
' closeSearchDialog
'-------------------------------------------------------------------------------
sub closeSearchDialog()
    if m.isClosingDialog = true then return
    m.isClosingDialog = true

    scene = m.top.getScene()
    if scene <> invalid then scene.dialog = invalid

    emitCloseRequested()
end sub

'-------------------------------------------------------------------------------
' emitCloseRequested
'-------------------------------------------------------------------------------
sub emitCloseRequested()
    if m.hasEmittedClose = true then return

    m.hasEmittedClose = true
    if m.isClosingDialog = false then m.isClosingDialog = true

    m.keyboardDialog = invalid
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub
