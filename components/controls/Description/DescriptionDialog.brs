'-------------------------------------------------------------------------------
' onTextChanged
'-------------------------------------------------------------------------------
sub onTextChanged()
    syncContent()
end sub

'-------------------------------------------------------------------------------
' syncContent
'-------------------------------------------------------------------------------
sub syncContent()
    content = m.top.callFunc("getContentComponent")
    if content <> invalid then content.text = SafeString(m.top.text)
end sub
