'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.seriesIcon = m.top.findNode("seriesIcon")
    m.title = m.top.findNode("title")
    m.content = invalid
end sub

'-------------------------------------------------------------------------------
' showContent
'-------------------------------------------------------------------------------
sub showContent()
    item = m.top.itemContent
    m.content = item
    if item = invalid then return

    if m.title <> invalid then m.title.text = item.title
    updateSeriesIcon()
end sub

'-------------------------------------------------------------------------------
' updateSeriesIcon
'-------------------------------------------------------------------------------
sub updateSeriesIcon()
    if m.seriesIcon = invalid then return
    item = m.content
    if item = invalid then return

    isSeries = item.isSeries = true
    m.seriesIcon.visible = isSeries
    if isSeries = false then return

    if item.isExpanded = true then
        if m.top.focusPercent > 0 then
            m.seriesIcon.uri = "pkg:/images/icons/chevron_up_focus.png"
        else
            m.seriesIcon.uri = "pkg:/images/icons/chevron_up_primary.png"
        end if
    else
        if m.top.focusPercent > 0 then
            m.seriesIcon.uri = "pkg:/images/icons/chevron_down_focus.png"
        else
            m.seriesIcon.uri = "pkg:/images/icons/chevron_down_primary.png"
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' focusPercentChanged
'-------------------------------------------------------------------------------
sub focusPercentChanged()
    if m.title = invalid then return

    if m.top.focusPercent > 0 then
        m.title.color = &h0F1A2AFF
    else
        m.title.color = &hF3F7FBFF
    end if

    updateSeriesIcon()
end sub
