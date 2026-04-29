'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.poster = m.top.findNode("poster")
    m.seriesOverlay = m.top.findNode("seriesOverlay")
    m.seriesLabel = m.top.findNode("seriesLabel")
end sub

'-------------------------------------------------------------------------------
' showContent
'-------------------------------------------------------------------------------
sub showContent()
    if m.poster = invalid then return

    item = m.top.itemContent
    if item = invalid then
        m.poster.uri = "pkg:/images/placeholder_cover.png"
        setSeriesDisplay(false, "")
        return
    end if

    m.poster.uri = SafeString(item.HDPosterUrl, SafeString(item.SDPosterUrl, "pkg:/images/placeholder_cover.png"))
    isSeries = isSeriesItem(item)
    setSeriesDisplay(isSeries, getSeriesName(item))
end sub

'-------------------------------------------------------------------------------
' isSeriesItem
'-------------------------------------------------------------------------------
function isSeriesItem(item as dynamic) as boolean
    if item = invalid then return false
    return item.isSeriesItem = true
end function

'-------------------------------------------------------------------------------
' setSeriesDisplay
'-------------------------------------------------------------------------------
sub setSeriesDisplay(isVisible as boolean, seriesName as string)
    if m.seriesOverlay <> invalid then m.seriesOverlay.visible = isVisible
    if m.seriesLabel <> invalid then
        m.seriesLabel.visible = isVisible
        m.seriesLabel.text = seriesName
    end if
end sub

'-------------------------------------------------------------------------------
' getSeriesName
'-------------------------------------------------------------------------------
function getSeriesName(item as dynamic) as string
    if item = invalid then return ""

    collapsedSeries = item.collapsedSeries
    if collapsedSeries = invalid then return ""

    if collapsedSeries.nameIgnorePrefix <> invalid then return collapsedSeries.nameIgnorePrefix
    return ""
end function
