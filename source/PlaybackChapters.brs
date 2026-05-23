'-------------------------------------------------------------------------------
' PlaybackChapters_GetStartPositions
'-------------------------------------------------------------------------------
function PlaybackChapters_GetStartPositions(chapterItems as dynamic) as object
    positions = []
    if chapterItems = invalid then return positions

    for each chapter in chapterItems
        positions.Push(PlaybackChapters_GetStartPosition(chapter))
    end for

    return positions
end function

'-------------------------------------------------------------------------------
' PlaybackChapters_GetMarkerPositions
'-------------------------------------------------------------------------------
function PlaybackChapters_GetMarkerPositions(chapterItems as dynamic, startPositions as dynamic, durationSeconds as integer) as object
    positions = []
    if chapterItems = invalid or chapterItems.Count() <= 1 then return positions

    for i = 0 to chapterItems.Count() - 1
        chapterPosition = PlaybackChapters_GetPositionAtIndex(startPositions, i)
        if chapterPosition < 0 then chapterPosition = 0
        if durationSeconds > 0 and chapterPosition > durationSeconds then chapterPosition = durationSeconds
        positions.Push(chapterPosition)
    end for

    return positions
end function

'-------------------------------------------------------------------------------
' PlaybackChapters_GetCurrentIndex
'-------------------------------------------------------------------------------
function PlaybackChapters_GetCurrentIndex(chapterItems as dynamic, startPositions as dynamic, currentTime as dynamic, durationSeconds as integer) as integer
    if chapterItems = invalid or chapterItems.Count() = 0 then return 0

    currentIndex = 0
    currentTimeSeconds = PlaybackTrackTime_ClampGlobalTime(currentTime, durationSeconds)
    for i = 0 to chapterItems.Count() - 1
        if currentTimeSeconds >= PlaybackChapters_GetPositionAtIndex(startPositions, i) then currentIndex = i
    end for

    return currentIndex
end function

'-------------------------------------------------------------------------------
' PlaybackChapters_GetCurrentTitle
'-------------------------------------------------------------------------------
function PlaybackChapters_GetCurrentTitle(chapterItems as dynamic, startPositions as dynamic, currentTime as dynamic, durationSeconds as integer) as string
    if chapterItems = invalid or chapterItems.Count() <= 1 then return ""

    index = PlaybackChapters_GetCurrentIndex(chapterItems, startPositions, currentTime, durationSeconds)
    if index < 0 or index >= chapterItems.Count() then return ""

    chapter = chapterItems[index]
    if chapter = invalid then return ""
    return SafeString(chapter.title, "")
end function

'-------------------------------------------------------------------------------
' PlaybackChapters_GetStartPosition
'-------------------------------------------------------------------------------
function PlaybackChapters_GetStartPosition(chapter as dynamic) as integer
    if chapter = invalid then return 0
    if chapter.startOffset <> invalid then return int(val(chapter.startOffset.ToStr()))
    return 0
end function

'-------------------------------------------------------------------------------
' PlaybackChapters_GetPositionAtIndex
'-------------------------------------------------------------------------------
function PlaybackChapters_GetPositionAtIndex(startPositions as dynamic, index as integer) as integer
    if startPositions = invalid then return 0
    if index < 0 or index >= startPositions.Count() then return 0
    return int(val(startPositions[index].ToStr()))
end function
