'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.descriptionText = m.top.findNode("descriptionText")
    onTextChanged()
end sub

'-------------------------------------------------------------------------------
' onTextChanged
'-------------------------------------------------------------------------------
sub onTextChanged()
    if m.descriptionText <> invalid then m.descriptionText.text = m.top.text
end sub
