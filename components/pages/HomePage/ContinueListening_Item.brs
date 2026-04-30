'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.poster = m.top.findNode("poster")
    m.progressFill = m.top.findNode("progressFill")
end sub

'-------------------------------------------------------------------------------
' showContent
'-------------------------------------------------------------------------------
sub showContent()
    if m.poster = invalid then return

    item = m.top.itemContent
    if item = invalid then
        m.poster.uri = "pkg:/images/placeholder_cover.png"
        updateProgressFill(invalid)
        return
    end if

    m.poster.uri = SafeString(item.HDPosterUrl, SafeString(item.SDPosterUrl, "pkg:/images/placeholder_cover.png"))
    updateProgressFill(item)
end sub

'-------------------------------------------------------------------------------
' updateProgressFill
'-------------------------------------------------------------------------------
sub updateProgressFill(item as dynamic)
    if m.progressFill = invalid then return

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
