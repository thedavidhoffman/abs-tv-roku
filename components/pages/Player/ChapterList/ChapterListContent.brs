'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.chapterList = m.top.findNode("chapterList")
    m.focusedChapterIndex = 0

    if m.chapterList <> invalid then
        m.chapterList.observeField("itemSelected", "onChapterListItemSelected")
        m.chapterList.observeField("itemFocused", "onChapterListItemFocused")
    end if

    updateChapterListContent()
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
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "OK" or key = "select" then
        selectFocusedChapter()
        return true
    else if key = "down" then
        return isFocusedAtChapterBoundary(1)
    else if key = "up" then
        return isFocusedAtChapterBoundary(-1)
    end if

    return false
end function

'-------------------------------------------------------------------------------
' focusCurrentChapter
'-------------------------------------------------------------------------------
sub focusCurrentChapter()
    if m.chapterList = invalid then return

    currentIndex = getCurrentTrackIndex()
    updateFocusedChapterIndex(currentIndex)
    m.chapterList.jumpToItem = currentIndex
    m.chapterList.setFocus(true)
end sub

'-------------------------------------------------------------------------------
' isFocusedAtChapterBoundary
'-------------------------------------------------------------------------------
function isFocusedAtChapterBoundary(offset as integer) as boolean
    if m.chapterList = invalid then return false

    currentIndex = getFocusedChapterIndex()
    return getBoundedChapterIndex(currentIndex + offset) = currentIndex
end function

'-------------------------------------------------------------------------------
' getFocusedChapterIndex
'-------------------------------------------------------------------------------
function getFocusedChapterIndex() as integer
    if m.chapterList = invalid then return 0

    focusedIndex = m.chapterList.itemFocused
    if focusedIndex = invalid or focusedIndex < 0 then focusedIndex = m.focusedChapterIndex
    return getBoundedChapterIndex(focusedIndex)
end function

'-------------------------------------------------------------------------------
' getBoundedChapterIndex
'-------------------------------------------------------------------------------
function getBoundedChapterIndex(index as dynamic) as integer
    if index = invalid or index < 0 then return 0

    tracks = m.top.tracks
    if tracks = invalid or tracks.Count() = 0 then return 0

    lastIndex = tracks.Count() - 1
    if index > lastIndex then return lastIndex
    return index
end function

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
            node.description = getChapterListDuration(track)
            node.addFields({
                focused: i = m.focusedChapterIndex
            })
            root.appendChild(node)
        end for
    end if

    m.chapterList.content = root
end sub

'-------------------------------------------------------------------------------
' onChapterListItemFocused
'-------------------------------------------------------------------------------
sub onChapterListItemFocused()
    if m.chapterList = invalid then return
    updateFocusedChapterIndex(m.chapterList.itemFocused)
end sub

'-------------------------------------------------------------------------------
' updateFocusedChapterIndex
'-------------------------------------------------------------------------------
sub updateFocusedChapterIndex(index as dynamic)
    if index = invalid or index < 0 then return
    if m.chapterList = invalid or m.chapterList.content = invalid then return

    content = m.chapterList.content
    if index >= content.getChildCount() then return

    if m.focusedChapterIndex <> invalid and m.focusedChapterIndex >= 0 and m.focusedChapterIndex < content.getChildCount() then
        previousNode = content.getChild(m.focusedChapterIndex)
        if previousNode <> invalid and previousNode.focused <> invalid then previousNode.focused = false
    end if

    currentNode = content.getChild(index)
    if currentNode <> invalid and currentNode.focused <> invalid then currentNode.focused = true
    m.focusedChapterIndex = index
end sub

'-------------------------------------------------------------------------------
' getChapterListTitle
'-------------------------------------------------------------------------------
function getChapterListTitle(track as dynamic, index as integer) as string
    title = SafeString(track.title, "Track " + (index + 1).ToStr())
    if index = getCurrentTrackIndex() then return "Now playing: " + title
    return title
end function

'-------------------------------------------------------------------------------
' getChapterListDuration
'-------------------------------------------------------------------------------
function getChapterListDuration(track as dynamic) as string
    durationSeconds = getTrackDurationSeconds(track)
    if durationSeconds <= 0 then return ""
    return formatChapterDuration(durationSeconds)
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

    m.top.selectedChapter = {
        index: index
    }
end sub

'-------------------------------------------------------------------------------
' getCurrentTrackIndex
'-------------------------------------------------------------------------------
function getCurrentTrackIndex() as integer
    if m.top.currentTrackIndex = invalid then return 0
    return getBoundedChapterIndex(m.top.currentTrackIndex)
end function
