'-------------------------------------------------------------------------------
' MediaProgressMapper_Map
'-------------------------------------------------------------------------------
function MediaProgressMapper_Map(payload as dynamic) as object
    mappedProgress = []
    if payload = invalid or payload.user = invalid or payload.user.mediaProgress = invalid then return mappedProgress

    for each progress in payload.user.mediaProgress
        if progress <> invalid then
            mappedProgress.Push({
                itemId: __MediaProgressMapper_GetItemId(progress)
                duration: __MediaProgressMapper_GetNumber(progress.duration)
                progress: __MediaProgressMapper_GetNumber(progress.progress)
                currentTime: __MediaProgressMapper_GetNumber(progress.currentTime)
                isFinished: __MediaProgressMapper_GetBoolean(progress.isFinished)
            })
        end if
    end for

    return mappedProgress
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_GetItemId
'-------------------------------------------------------------------------------
function __MediaProgressMapper_GetItemId(progress as dynamic) as dynamic
    if progress = invalid then return invalid
    if progress.itemId <> invalid then return progress.itemId
    if progress.libraryItemId <> invalid then return progress.libraryItemId
    if progress.mediaItemId <> invalid then return progress.mediaItemId

    return invalid
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_GetNumber
'-------------------------------------------------------------------------------
function __MediaProgressMapper_GetNumber(value as dynamic) as float
    if value = invalid then return 0
    return val(value.ToStr())
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_GetBoolean
'-------------------------------------------------------------------------------
function __MediaProgressMapper_GetBoolean(value as dynamic) as boolean
    if value = invalid then return false
    if Type(value) = "Boolean" or Type(value) = "roBoolean" then return value

    text = LCase(value.ToStr())
    return text = "true" or text = "1"
end function
