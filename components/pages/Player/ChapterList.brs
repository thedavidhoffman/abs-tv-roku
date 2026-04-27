'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.backdrop = m.top.findNode("backdrop")
    m.panel = m.top.findNode("panel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.chapterList = m.top.findNode("chapterList")
    m.closeButton = m.top.findNode("closeButton")
    m.closeHasFocus = false
    m.closedCounter = 0
    m.selectionCounter = 0

    if m.chapterList <> invalid then m.chapterList.observeField("itemSelected", "onChapterListItemSelected")
    styleChapterList()
    updateTitle()
    updateCloseFocus(false)
    updateChapterListContent()
end sub

'-------------------------------------------------------------------------------
' open
'-------------------------------------------------------------------------------
sub open()
    m.top.visible = true
    updateChapterListContent()
    updateCloseFocus(false)

    if m.chapterList <> invalid then
        m.chapterList.jumpToItem = getCurrentTrackIndex()
        m.chapterList.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' close
'-------------------------------------------------------------------------------
sub close()
    m.top.visible = false
    updateCloseFocus(false)
    m.closedCounter = m.closedCounter + 1
    m.top.closedCounter = m.closedCounter
end sub

'-------------------------------------------------------------------------------
' onTracksChanged
'-------------------------------------------------------------------------------
sub onTracksChanged()
    updateChapterListContent()
end sub

'-------------------------------------------------------------------------------
' onCurrentTrackIndexChanged
'-------------------------------------------------------------------------------
sub onCurrentTrackIndexChanged()
    updateChapterListContent()
end sub

'-------------------------------------------------------------------------------
' onAudiobookTitleChanged
'-------------------------------------------------------------------------------
sub onAudiobookTitleChanged()
    updateTitle()
end sub

'-------------------------------------------------------------------------------
' updateTitle
'-------------------------------------------------------------------------------
sub updateTitle()
    if m.titleLabel = invalid then return
    m.titleLabel.text = SafeString(m.top.audiobookTitle, "Chapters")
end sub

'-------------------------------------------------------------------------------
' styleChapterList
'-------------------------------------------------------------------------------
sub styleChapterList()
    if m.backdrop <> invalid then m.backdrop.color = &h000000FF
    if m.panel <> invalid then m.panel.color = &h101B2BFF
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "back" then
        close()
        return true
    end if

    if m.closeHasFocus then
        if key = "OK" or key = "select" then
            close()
            return true
        else if key = "left" or key = "up" then
            focusChapterList()
            return true
        end if
    else
        if key = "OK" or key = "select" then
            selectFocusedChapter()
            return true
        else if key = "down" then
            moveChapterListFocus(1)
            return true
        else if key = "up" then
            moveChapterListFocus(-1)
            return true
        else if key = "right" then
            focusCloseButton()
            return true
        end if
    end if

    return false
end function

'-------------------------------------------------------------------------------
' focusChapterList
'-------------------------------------------------------------------------------
sub focusChapterList()
    updateCloseFocus(false)
    if m.chapterList <> invalid then m.chapterList.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' focusCloseButton
'-------------------------------------------------------------------------------
sub focusCloseButton()
    updateCloseFocus(true)
    if m.closeButton <> invalid then m.closeButton.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' moveChapterListFocus
'-------------------------------------------------------------------------------
sub moveChapterListFocus(offset as integer)
    if m.chapterList = invalid then return

    tracks = m.top.tracks
    if tracks = invalid or tracks.Count() = 0 then return

    currentIndex = m.chapterList.itemFocused
    if currentIndex = invalid or currentIndex < 0 then currentIndex = 0

    nextIndex = currentIndex + offset
    if nextIndex < 0 then nextIndex = 0

    lastIndex = tracks.Count() - 1
    if nextIndex > lastIndex then
        focusCloseButton()
        return
    end if

    updateCloseFocus(false)
    m.chapterList.jumpToItem = nextIndex
    m.chapterList.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' updateCloseFocus
'-------------------------------------------------------------------------------
sub updateCloseFocus(hasFocus as boolean)
    m.closeHasFocus = hasFocus
    if m.closeButton <> invalid then m.closeButton.hasFocusVisual = hasFocus
end sub

'-------------------------------------------------------------------------------
' updateChapterListContent
'-------------------------------------------------------------------------------
sub updateChapterListContent()
    if m.chapterList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    tracks = m.top.tracks
    if tracks <> invalid then
        for i = 0 to tracks.Count() - 1
            track = tracks[i]
            node = CreateObject("roSGNode", "ContentNode")
            node.title = getChapterListTitle(track, i)
            root.appendChild(node)
        end for
    end if

    m.chapterList.content = root
end sub

'-------------------------------------------------------------------------------
' getChapterListTitle
'-------------------------------------------------------------------------------
function getChapterListTitle(track as dynamic, index as integer) as string
    title = SafeString(track.title, "Track " + (index + 1).ToStr())
    durationSeconds = getTrackDurationSeconds(track)
    if durationSeconds > 0 then title = title + "   (" + formatChapterDuration(durationSeconds) + ")"

    if index = getCurrentTrackIndex() then return "Now playing: " + title
    return title
end function

'-------------------------------------------------------------------------------
' getTrackDurationSeconds
'-------------------------------------------------------------------------------
function getTrackDurationSeconds(track as dynamic) as integer
    if track = invalid then return 0
    if track.durationSeconds = invalid then return 0
    return int(val(track.durationSeconds.ToStr()))
end function

'-------------------------------------------------------------------------------
' formatChapterDuration
'-------------------------------------------------------------------------------
function formatChapterDuration(totalSeconds as integer) as string
    if totalSeconds < 0 then totalSeconds = 0

    hours = int(totalSeconds / 3600)
    minutes = int((totalSeconds mod 3600) / 60)
    seconds = totalSeconds mod 60
    secondsText = seconds.ToStr()
    if seconds < 10 then secondsText = "0" + secondsText

    if hours > 0 then
        minutesText = minutes.ToStr()
        if minutes < 10 then minutesText = "0" + minutesText
        return hours.ToStr() + ":" + minutesText + ":" + secondsText
    end if

    return minutes.ToStr() + ":" + secondsText
end function

'-------------------------------------------------------------------------------
' onChapterListItemSelected
'-------------------------------------------------------------------------------
sub onChapterListItemSelected()
    if m.top.visible <> true then return
    if m.chapterList = invalid then return

    selectChapter(m.chapterList.itemSelected)
end sub

'-------------------------------------------------------------------------------
' selectFocusedChapter
'-------------------------------------------------------------------------------
sub selectFocusedChapter()
    if m.chapterList = invalid then return
    selectChapter(m.chapterList.itemFocused)
end sub

'-------------------------------------------------------------------------------
' selectChapter
'-------------------------------------------------------------------------------
sub selectChapter(index as dynamic)
    tracks = m.top.tracks
    if index = invalid then return
    if tracks = invalid then return
    if index < 0 or index >= tracks.Count() then return

    close()
    m.selectionCounter = m.selectionCounter + 1
    m.top.selectedChapter = {
        index: index
        counter: m.selectionCounter
    }
end sub

'-------------------------------------------------------------------------------
' getCurrentTrackIndex
'-------------------------------------------------------------------------------
function getCurrentTrackIndex() as integer
    if m.top.currentTrackIndex = invalid then return 0
    return m.top.currentTrackIndex
end function
