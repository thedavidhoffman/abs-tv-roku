'-------------------------------------------------------------------------------
' ItemPoster data model
'-------------------------------------------------------------------------------
' itemContent carries item data such as title, author, cover URLs, focus state,
' series data, and progress values. Component fields carry presentation settings
' for this specific ItemPoster usage, such as posterWidth, showText, and
' showProgressBar.

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
    applyLayoutForWidth(getPosterWidth())
    updateTitleFocusDisplay()
end sub

'-------------------------------------------------------------------------------
' showContent
'-------------------------------------------------------------------------------
sub showContent()
    if m.poster = invalid then return
    
    ' RowList/Grid renderers are reused, so detach from the old content node
    ' before observing the new one. Otherwise stale focus changes can update
    ' a poster that no longer represents that item.
    if m.content <> invalid and m.content.focused <> invalid then
        m.content.unobserveFieldScoped("focused")
    end if

    ' itemContent is passed in and includes information about the item being displayed
    ' this information does not include behavioral flags for the component displayed
    ' such as "posterWidth", "showText" and "showProgressBar"
    item = m.top.itemContent
    m.content = item

    ' safety render if itemContent wasn't set
    if item = invalid then
        m.poster.uri = "pkg:/images/placeholder-cover.png"
        m.titleText = ""
        setLabelText(m.titleLabel, "")
        setLabelText(m.scrollingTitleLabel, "")
        setLabelText(m.authorLabel, "")
        updateSeriesSequence(invalid)
        updateTitleFocusDisplay()
        updateProgressFill(invalid)
        return
    end if

    ' render based on itemContent being set
    applyLayoutForWidth(getPosterWidth())
    m.poster.uri = getPosterUrl(item)
    m.titleText = getDisplayTitle(item)
    setLabelText(m.titleLabel, m.titleText)
    setLabelText(m.scrollingTitleLabel, "")
    setLabelText(m.authorLabel, getDisplayAuthor(item))
    updateSeriesSequence(item)

    ' Watch the content-level focused field so this reused poster can swap
    ' between the static and scrolling title displays as focus moves.
    if item.focused <> invalid then item.observeFieldScoped("focused", "onFocusedChanged")

    updateTitleFocusDisplay()
    updateProgressFill(item)
end sub

'-------------------------------------------------------------------------------
' onShowTextChanged
'-------------------------------------------------------------------------------
sub onShowTextChanged()
    updateTitleFocusDisplay()
end sub

'-------------------------------------------------------------------------------
' onShowProgressBarChanged
'-------------------------------------------------------------------------------
sub onShowProgressBarChanged()
    updateProgressFill(m.content)
end sub

'-------------------------------------------------------------------------------
' onPosterWidthChanged
'-------------------------------------------------------------------------------
sub onPosterWidthChanged()
    applyLayoutForWidth(getPosterWidth())
    updateProgressFill(m.content)
end sub

'-------------------------------------------------------------------------------
' getPosterWidth
'-------------------------------------------------------------------------------
function getPosterWidth() as integer
    width = m.top.posterWidth
    if width = invalid or width < 1 then width = 280
    return width
end function

'-------------------------------------------------------------------------------
' getPosterUrl
'-------------------------------------------------------------------------------
function getPosterUrl(item as dynamic) as string
    return SafeString(item.HDPosterUrl, SafeString(item.SDPosterUrl, "pkg:/images/placeholder-cover.png"))
end function

'-------------------------------------------------------------------------------
' applyLayoutForWidth
'-------------------------------------------------------------------------------
sub applyLayoutForWidth(width as integer)
    if width < 1 then width = 280

    scale = width / 280
    labelMargin = int(5 * scale)
    if labelMargin < 1 then labelMargin = 1

    textWidth = width - (labelMargin * 2)
    if textWidth < 1 then textWidth = 1

    progressHeight = int(10 * scale)
    if progressHeight < 1 then progressHeight = 1

    titleHeight = int(28 * scale)
    if titleHeight < 1 then titleHeight = 1

    titleY = width + int(12 * scale)
    authorY = width + int(42 * scale)

    if m.poster <> invalid then
        m.poster.width = width
        m.poster.height = width
    end if

    if m.progressFill <> invalid then
        m.progressFill.translation = [0, width - progressHeight]
        m.progressFill.height = progressHeight
    end if

    updateSeriesSequenceLayout(width, scale)

    if m.titleLabel <> invalid then
        m.titleLabel.translation = [labelMargin, titleY]
        m.titleLabel.width = textWidth
        m.titleLabel.height = titleHeight
    end if

    if m.scrollingTitleLabel <> invalid then
        m.scrollingTitleLabel.translation = [labelMargin, titleY]
        m.scrollingTitleLabel.maxWidth = textWidth
    end if

    if m.authorLabel <> invalid then
        m.authorLabel.translation = [labelMargin, authorY]
        m.authorLabel.width = textWidth
        m.authorLabel.height = titleHeight
    end if
end sub

'-------------------------------------------------------------------------------
' updateSeriesSequenceLayout
'-------------------------------------------------------------------------------
sub updateSeriesSequenceLayout(width as integer, scale as float)
    badgeWidth = int(70 * scale)
    if badgeWidth < 1 then badgeWidth = 1

    badgeHeight = int(35 * scale)
    if badgeHeight < 1 then badgeHeight = 1

    badgeMargin = int(10 * scale)
    if badgeMargin < 0 then badgeMargin = 0

    labelInsetX = int(4 * scale)
    labelOffsetY = int(8 * scale)
    labelWidth = badgeWidth - (labelInsetX * 2)
    if labelWidth < 1 then labelWidth = 1

    labelHeight = int(25 * scale)
    if labelHeight < 1 then labelHeight = 1

    badgeX = width - badgeWidth - badgeMargin
    if badgeX < 0 then badgeX = 0

    if m.seriesSequenceBackground <> invalid then
        m.seriesSequenceBackground.translation = [badgeX, badgeMargin]
        m.seriesSequenceBackground.width = badgeWidth
        m.seriesSequenceBackground.height = badgeHeight
    end if

    if m.seriesSequenceLabel <> invalid then
        m.seriesSequenceLabel.translation = [badgeX + labelInsetX, badgeMargin + labelOffsetY]
        m.seriesSequenceLabel.width = labelWidth
        m.seriesSequenceLabel.height = labelHeight
    end if
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
    badgeText = getSeriesBadgeText(item)
    isVisible = (badgeText <> "")

    if m.seriesSequenceBackground <> invalid then m.seriesSequenceBackground.visible = isVisible
    if m.seriesSequenceLabel <> invalid then
        m.seriesSequenceLabel.text = badgeText
        m.seriesSequenceLabel.visible = isVisible
    end if
end sub

'-------------------------------------------------------------------------------
' getSeriesBadgeText
'-------------------------------------------------------------------------------
function getSeriesBadgeText(item as dynamic) as string
    if isSeriesItem(item) then return getSeriesCount(item)
    if item <> invalid and item.showSeriesSequence = false then return ""

    sequence = getSeriesSequence(item)
    if sequence = "" then return ""
    return "#" + sequence
end function

'-------------------------------------------------------------------------------
' getSeriesCount
'-------------------------------------------------------------------------------
function getSeriesCount(item as dynamic) as string
    if item = invalid then return ""

    collapsedSeries = item.collapsedSeries
    if collapsedSeries = invalid then return ""
    if collapsedSeries.numBooks = invalid then return ""

    return collapsedSeries.numBooks.ToStr()
end function

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
    if shouldShowText() <> true then
        if m.titleLabel <> invalid then m.titleLabel.visible = false
        if m.scrollingTitleLabel <> invalid then
            m.scrollingTitleLabel.visible = false
            m.scrollingTitleLabel.text = ""
        end if
        if m.authorLabel <> invalid then m.authorLabel.visible = false
        return
    end if

    isFocused = (m.content <> invalid and m.content.focused = true)
    if m.titleLabel <> invalid then m.titleLabel.visible = not isFocused
    if m.scrollingTitleLabel <> invalid then
        if isFocused then
            m.scrollingTitleLabel.text = m.titleText
            m.scrollingTitleLabel.visible = true
        else
            m.scrollingTitleLabel.visible = false
            ' Clear the scrolling label while unfocused so refocusing starts the
            ' title animation from the beginning instead of its previous offset.
            m.scrollingTitleLabel.text = ""
        end if
    end if
    if m.authorLabel <> invalid then m.authorLabel.visible = true
end sub

'-------------------------------------------------------------------------------
' shouldShowText
'-------------------------------------------------------------------------------
function shouldShowText() as boolean
    return m.top.showText = true
end function

'-------------------------------------------------------------------------------
' updateProgressFill
'-------------------------------------------------------------------------------
sub updateProgressFill(item as dynamic)
    if m.progressFill = invalid then return
    if item = invalid or shouldShowProgressBar(item) <> true then
        m.progressFill.visible = false
        return
    end if

    percentComplete = getPercentComplete(item)
    posterWidth = getPosterWidth()
    fillWidth = int(posterWidth * percentComplete)

    if percentComplete <= 0 then
        m.progressFill.visible = false
        return
    end if

    if fillWidth < 1 then fillWidth = 1
    if fillWidth > posterWidth then fillWidth = posterWidth
    if item.progressIsFinished = true then
        m.progressFill.color = &h3BB273FF
    else
        m.progressFill.color = &hE09B42FF
    end if
    m.progressFill.width = fillWidth
    m.progressFill.visible = true
end sub

'-------------------------------------------------------------------------------
' shouldShowProgressBar
'-------------------------------------------------------------------------------
function shouldShowProgressBar(item as dynamic) as boolean
    if m.top.showProgressBar <> true then return false
    return true
end function

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
