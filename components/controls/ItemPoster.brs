'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.poster = m.top.findNode("poster")
    m.progressFill = m.top.findNode("progressFill")
    m.seriesSequenceBackground = m.top.findNode("seriesSequenceBackground")
    m.seriesSequenceLabel = m.top.findNode("seriesSequenceLabel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.scrollingTitleLabel = m.top.findNode("scrollingTitleLabel")
    m.authorLabel = m.top.findNode("authorLabel")
    m.content = invalid
    m.titleText = ""
    updateTitleFocusDisplay()
end sub

'-------------------------------------------------------------------------------
' showContent
'-------------------------------------------------------------------------------
sub showContent()
    if m.poster = invalid then return
    if m.content <> invalid then m.content.unobserveFieldScoped("focused")

    item = m.top.itemContent
    m.content = item
    if item = invalid then
        m.poster.uri = "pkg:/images/placeholder_cover.png"
        m.titleText = ""
        setLabelText(m.titleLabel, "")
        setLabelText(m.scrollingTitleLabel, "")
        setLabelText(m.authorLabel, "")
        updateSeriesSequence(invalid)
        updateTitleFocusDisplay()
        updateProgressFill(invalid)
        return
    end if

    m.poster.uri = SafeString(item.HDPosterUrl, SafeString(item.SDPosterUrl, "pkg:/images/placeholder_cover.png"))
    m.titleText = getDisplayTitle(item)
    setLabelText(m.titleLabel, m.titleText)
    setLabelText(m.scrollingTitleLabel, "")
    setLabelText(m.authorLabel, getDisplayAuthor(item))
    updateSeriesSequence(item)
    if item.focused <> invalid then item.observeFieldScoped("focused", "onFocusedChanged")
    updateTitleFocusDisplay()
    updateProgressFill(item)
end sub

'-------------------------------------------------------------------------------
' getDisplayTitle
'-------------------------------------------------------------------------------
function getDisplayTitle(item as dynamic) as string
    if isSeriesItem(item) then
        seriesName = getSeriesName(item)
        if seriesName <> "" then return seriesName
    end if

    return SafeString(item.title, "")
end function

'-------------------------------------------------------------------------------
' getDisplayAuthor
'-------------------------------------------------------------------------------
function getDisplayAuthor(item as dynamic) as string
    if isSeriesItem(item) then return "SERIES"
    return SafeString(item.author, "")
end function

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

'-------------------------------------------------------------------------------
' updateSeriesSequence
'-------------------------------------------------------------------------------
sub updateSeriesSequence(item as dynamic)
    sequence = getSeriesSequence(item)
    isVisible = (sequence <> "")

    if m.seriesSequenceBackground <> invalid then m.seriesSequenceBackground.visible = isVisible
    if m.seriesSequenceLabel <> invalid then
        m.seriesSequenceLabel.text = "#" + sequence
        m.seriesSequenceLabel.visible = isVisible
    end if
end sub

'-------------------------------------------------------------------------------
' getSeriesSequence
'-------------------------------------------------------------------------------
function getSeriesSequence(item as dynamic) as string
    if item = invalid then return ""

    if item.seriesSequence <> invalid then return item.seriesSequence.ToStr()
    if item.sequence <> invalid then return item.sequence.ToStr()

    collapsedSeries = item.collapsedSeries
    if collapsedSeries <> invalid then
        if collapsedSeries.sequence <> invalid then return collapsedSeries.sequence.ToStr()
        if collapsedSeries.seriesSequence <> invalid then return collapsedSeries.seriesSequence.ToStr()
    end if

    return ""
end function

'-------------------------------------------------------------------------------
' onFocusedChanged
'-------------------------------------------------------------------------------
sub onFocusedChanged()
    updateTitleFocusDisplay()
end sub

'-------------------------------------------------------------------------------
' updateTitleFocusDisplay
'-------------------------------------------------------------------------------
sub updateTitleFocusDisplay()
    isFocused = (m.content <> invalid and m.content.focused = true)
    if m.titleLabel <> invalid then m.titleLabel.visible = not isFocused
    if m.scrollingTitleLabel <> invalid then
        if isFocused then
            m.scrollingTitleLabel.text = m.titleText
            m.scrollingTitleLabel.visible = true
        else
            m.scrollingTitleLabel.visible = false
            m.scrollingTitleLabel.text = ""
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' updateProgressFill
'-------------------------------------------------------------------------------
sub updateProgressFill(item as dynamic)
    if m.progressFill = invalid then return
    if item = invalid or item.showProgressBar = false then
        m.progressFill.visible = false
        return
    end if

    percentComplete = getPercentComplete(item)
    fillWidth = int(280 * percentComplete)

    if percentComplete <= 0 then
        m.progressFill.visible = false
        return
    end if

    if fillWidth < 1 then fillWidth = 1
    if fillWidth > 280 then fillWidth = 280
    if item.progressIsFinished = true then
        m.progressFill.color = &h3BB273FF
    else
        m.progressFill.color = &hE09B42FF
    end if
    m.progressFill.width = fillWidth
    m.progressFill.visible = true
end sub

'-------------------------------------------------------------------------------
' getPercentComplete
'-------------------------------------------------------------------------------
function getPercentComplete(item as dynamic) as float
    if item = invalid then return 0

    progress = getNumber(item.progressPercent)
    if progress > 0 then return clampPercent(progress)

    duration = getNumber(item.progressDuration)
    if duration <= 0 then return 0

    currentTime = getNumber(item.progressCurrentTime)
    return clampPercent(currentTime / duration)
end function

'-------------------------------------------------------------------------------
' getNumber
'-------------------------------------------------------------------------------
function getNumber(value as dynamic) as float
    if value = invalid then return 0
    return val(value.ToStr())
end function

'-------------------------------------------------------------------------------
' clampPercent
'-------------------------------------------------------------------------------
function clampPercent(value as float) as float
    if value < 0 then return 0
    if value > 1 then return 1
    return value
end function

'-------------------------------------------------------------------------------
' isSeriesItem
'-------------------------------------------------------------------------------
function isSeriesItem(item as dynamic) as boolean
    if item = invalid then return false
    return item.isSeriesItem = true
end function

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
