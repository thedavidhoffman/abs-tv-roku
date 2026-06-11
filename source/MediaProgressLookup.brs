'-------------------------------------------------------------------------------
' MediaProgressLookup_GetStartPosition
'-------------------------------------------------------------------------------
function MediaProgressLookup_GetStartPosition(item as dynamic, mediaProgress as dynamic) as integer
    if item = invalid then return 0

    if item.startPositionSeconds <> invalid then
        startPosition = Number_ToInteger(item.startPositionSeconds)
        if startPosition > 0 then return startPosition
    end if

    candidateIds = __MediaProgressLookup_GetCandidateIds(item)
    for each candidateId in candidateIds
        startTime = __MediaProgressLookup_GetCurrentTime(candidateId, mediaProgress)
        if startTime > 0 then return startTime
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' __MediaProgressLookup_GetCurrentTime
'-------------------------------------------------------------------------------
function __MediaProgressLookup_GetCurrentTime(itemId as dynamic, mediaProgress as dynamic) as integer
    if itemId = invalid then return 0
    if mediaProgress = invalid then return 0

    targetItemId = itemId.ToStr()
    for each progress in mediaProgress
        if progress <> invalid and progress.itemId <> invalid and progress.itemId.ToStr() = targetItemId then
            if progress.isFinished = true then return 0

            currentTime = 0
            if progress.currentTime <> invalid then currentTime = Number_ToInteger(progress.currentTime)
            if currentTime > 0 then return currentTime

            duration = 0
            if progress.duration <> invalid then duration = Number_ToFloat(progress.duration)

            progressValue = 0
            if progress.progress <> invalid then progressValue = Number_ToFloat(progress.progress)
            if duration > 0 and progressValue > 0 then
                if progressValue > 1 then progressValue = progressValue / 100
                if progressValue > 1 then progressValue = 1
                return int(progressValue * duration)
            end if
        end if
    end for

    return 0
end function

'-------------------------------------------------------------------------------
' __MediaProgressLookup_GetCandidateIds
'-------------------------------------------------------------------------------
function __MediaProgressLookup_GetCandidateIds(item as dynamic) as object
    ids = []
    if item = invalid then return ids

    if item.id <> invalid then ids.Push(item.id)
    if item.libraryItemId <> invalid then ids.Push(item.libraryItemId)
    if item.mediaItemId <> invalid then ids.Push(item.mediaItemId)
    if item.media <> invalid and item.media.id <> invalid then ids.Push(item.media.id)

    return ids
end function
