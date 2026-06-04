'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.focusBg = m.top.findNode("focusBg")
    m.poster = m.top.findNode("poster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.authorLabel = m.top.findNode("authorLabel")
    m.dateLabel = m.top.findNode("dateLabel")
    m.durationLabel = m.top.findNode("durationLabel")
    m.deviceLabel = m.top.findNode("deviceLabel")
    m.content = invalid
end sub

'-------------------------------------------------------------------------------
' showContent
'-------------------------------------------------------------------------------
sub showContent()
    item = m.top.itemContent
    m.content = item
    if item = invalid then return

    m.poster.itemContent = item
    m.titleLabel.text = FirstNonEmpty([item.title], "Untitled")
    m.authorLabel.text = FirstNonEmpty([item.author], "Unknown")
    m.dateLabel.text = SafeString(item.sessionDateText, "")
    m.durationLabel.text = SafeString(item.sessionDurationText, "")
    m.deviceLabel.text = SafeString(item.sessionDeviceText, "")

    updateVisualState()
end sub

'-------------------------------------------------------------------------------
' focusPercentChanged
'-------------------------------------------------------------------------------
sub focusPercentChanged()
    updateVisualState()
end sub

'-------------------------------------------------------------------------------
' updateVisualState
'-------------------------------------------------------------------------------
sub updateVisualState()
    hasFocus = m.top.focusPercent > 0
    m.focusBg.visible = hasFocus
end sub
