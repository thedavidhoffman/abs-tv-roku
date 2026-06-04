'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initStyle()
    renderCard()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.valueLabel = m.top.findNode("valueLabel")
    m.textLabel = m.top.findNode("textLabel")
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    palette = Color()
    m.valueLabel.color = palette.text.heading
    m.textLabel.color = palette.text.secondary
end sub

'-------------------------------------------------------------------------------
' onDataChanged
'-------------------------------------------------------------------------------
sub onDataChanged()
    renderCard()
end sub

'-------------------------------------------------------------------------------
' renderCard
'-------------------------------------------------------------------------------
sub renderCard()
    m.valueLabel.text = m.top.valueText
    m.textLabel.text = m.top.labelText
end sub
