'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    updateText()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.titleLabel = m.top.findNode("titleLabel")
    m.authorLabel = m.top.findNode("authorLabel")
    m.metadataLabel = m.top.findNode("metadataLabel")
    m.descriptionLabel = m.top.findNode("description")
end sub

'-------------------------------------------------------------------------------
' onTitleTextChanged
'-------------------------------------------------------------------------------
sub onTitleTextChanged()
    setLabelText(m.titleLabel, m.top.titleText)
    if m.descriptionLabel <> invalid then m.descriptionLabel.title = SafeString(m.top.titleText, "")
end sub

'-------------------------------------------------------------------------------
' onAuthorTextChanged
'-------------------------------------------------------------------------------
sub onAuthorTextChanged()
    setLabelText(m.authorLabel, m.top.authorText)
end sub

'-------------------------------------------------------------------------------
' onMetadataTextChanged
'-------------------------------------------------------------------------------
sub onMetadataTextChanged()
    setLabelText(m.metadataLabel, m.top.metadataText)
end sub

'-------------------------------------------------------------------------------
' onDescriptionTextChanged
'-------------------------------------------------------------------------------
sub onDescriptionTextChanged()
    setLabelText(m.descriptionLabel, m.top.descriptionText)
end sub

'-------------------------------------------------------------------------------
' descriptionHasFocus
'-------------------------------------------------------------------------------
function descriptionHasFocus() as boolean
    return m.descriptionLabel <> invalid and m.descriptionLabel.isInFocusChain()
end function

'-------------------------------------------------------------------------------
' canFocusDescription
'-------------------------------------------------------------------------------
function canFocusDescription() as boolean
    return m.descriptionLabel <> invalid and m.descriptionLabel.canAcceptFocus = true
end function

'-------------------------------------------------------------------------------
' focusDescription
'-------------------------------------------------------------------------------
function focusDescription() as boolean
    if canFocusDescription() <> true then return false

    m.descriptionLabel.setFocus(true)
    return true
end function

'-------------------------------------------------------------------------------
' dismissDescriptionDialog
'-------------------------------------------------------------------------------
sub dismissDescriptionDialog()
    if m.descriptionLabel <> invalid then m.descriptionLabel.callFunc("dismissDialog")
end sub

'-------------------------------------------------------------------------------
' updateText
'-------------------------------------------------------------------------------
sub updateText()
    setLabelText(m.titleLabel, m.top.titleText)
    setLabelText(m.authorLabel, m.top.authorText)
    setLabelText(m.metadataLabel, m.top.metadataText)
    setLabelText(m.descriptionLabel, m.top.descriptionText)
end sub

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as dynamic)
    if label <> invalid then label.text = SafeString(text, "")
end sub
