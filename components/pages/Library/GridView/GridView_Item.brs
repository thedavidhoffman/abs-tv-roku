'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.poster = m.top.findNode("poster")
    m.seriesTitleOverlay = m.top.findNode("seriesTitleOverlay")
    m.seriesTitleLabel = m.top.findNode("seriesTitleLabel")
    m.seriesOverlay = m.top.findNode("seriesOverlay")
    m.seriesLabel = m.top.findNode("seriesLabel")
    m.isSeriesItem = false
    m.seriesTitle = ""
end sub

'-------------------------------------------------------------------------------
' showContent
'-------------------------------------------------------------------------------
sub showContent()
    if m.poster = invalid then return

    item = m.top.itemContent
    if item = invalid then
        m.poster.uri = "pkg:/images/placeholder_cover.png"
        m.isSeriesItem = false
        m.seriesTitle = ""
        setSeriesDisplay(false, "")
        updateSeriesTitleOverlay()
        return
    end if

    m.poster.uri = SafeString(item.HDPosterUrl, SafeString(item.SDPosterUrl, "pkg:/images/placeholder_cover.png"))
    m.isSeriesItem = isSeriesItem(item)
    m.seriesTitle = getSeriesName(item)
    setSeriesDisplay(m.isSeriesItem, m.seriesTitle)
    updateSeriesTitleOverlay()
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
        m.seriesLabel.text = "SERIES" 'seriesName
    end if
end sub

'-------------------------------------------------------------------------------
' onFocusPercentChanged
'-------------------------------------------------------------------------------
sub onFocusPercentChanged()
    updateSeriesTitleOverlay()
end sub

'-------------------------------------------------------------------------------
' updateSeriesTitleOverlay
'-------------------------------------------------------------------------------
sub updateSeriesTitleOverlay()
    isVisible = (m.isSeriesItem = true and m.top.focusPercent > 0)
    if m.seriesTitleOverlay <> invalid then m.seriesTitleOverlay.visible = isVisible
    if m.seriesTitleLabel <> invalid then
        m.seriesTitleLabel.text = m.seriesTitle
        m.seriesTitleLabel.visible = isVisible
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
