'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.poster = m.top.findNode("poster")
    m.progressFill = m.top.findNode("progressFill")
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
        updateTitleFocusDisplay()
        updateProgressFill(invalid)
        return
    end if

    m.poster.uri = SafeString(item.HDPosterUrl, SafeString(item.SDPosterUrl, "pkg:/images/placeholder_cover.png"))
    m.titleText = SafeString(item.title, "")
    setLabelText(m.titleLabel, m.titleText)
    setLabelText(m.scrollingTitleLabel, "")
    setLabelText(m.authorLabel, SafeString(item.author, ""))
    if item.focused <> invalid then item.observeFieldScoped("focused", "onFocusedChanged")
    updateTitleFocusDisplay()
    updateProgressFill(item)
end sub

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

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
