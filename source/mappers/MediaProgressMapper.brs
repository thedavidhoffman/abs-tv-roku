'-------------------------------------------------------------------------------
' MediaProgressMapper_Map
'-------------------------------------------------------------------------------
function MediaProgressMapper_Map(payload as dynamic) as object
    mappedProgress = []
    if payload = invalid or payload.user = invalid then return mappedProgress

    rawProgress = payload.user.mediaProgress
    if rawProgress = invalid then rawProgress = payload.user.oldMediaProgress
    if rawProgress = invalid then return mappedProgress

    progressItems = __MediaProgressMapper_ToArray(rawProgress)
    if progressItems = invalid then return mappedProgress

    for each progress in progressItems
        if progress <> invalid then
            mappedItem = __MediaProgressMapper_MapProgress(progress, invalid)
            if mappedItem <> invalid then mappedProgress.Push(mappedItem)
        end if
    end for

    return mappedProgress
end function

'-------------------------------------------------------------------------------
' MediaProgressMapper_MapProgressItem
'-------------------------------------------------------------------------------
function MediaProgressMapper_MapProgressItem(progress as dynamic) as dynamic
    return __MediaProgressMapper_MapProgress(progress, invalid)
end function

'-------------------------------------------------------------------------------
' MediaProgressMapper_MapInProgressItems
'-------------------------------------------------------------------------------
function MediaProgressMapper_MapInProgressItems(libraryItems as dynamic) as object
    mappedProgress = []
    progressItems = __MediaProgressMapper_ToArray(libraryItems)
    if progressItems = invalid then return mappedProgress

    for each item in progressItems
        if item <> invalid then
            progress = invalid
            if item.userMediaProgress <> invalid then
                progress = item.userMediaProgress
            else if item.mediaProgress <> invalid then
                progress = item.mediaProgress
            else if __MediaProgressMapper_HasProgressFields(item) then
                progress = item
            end if

            if progress <> invalid then
                mappedItem = __MediaProgressMapper_MapProgress(progress, item)
                if mappedItem <> invalid then mappedProgress.Push(mappedItem)
            end if
        end if
    end for

    return mappedProgress
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_MapProgress
'-------------------------------------------------------------------------------
function __MediaProgressMapper_MapProgress(progress as dynamic, item as dynamic) as dynamic
    itemId = __MediaProgressMapper_GetItemId(progress)
    if itemId = invalid or itemId = "" then itemId = __MediaProgressMapper_GetLegacyItemId(progress)
    if itemId = invalid or itemId = "" then itemId = __MediaProgressMapper_GetItemId(item)
    if itemId = invalid or itemId = "" then return invalid

    duration = Number_ToFloat(progress.duration)
    if duration <= 0 then duration = __MediaProgressMapper_GetItemDuration(item)

    return {
        itemId: itemId
        duration: duration
        progress: Number_ToFloat(progress.progress)
        currentTime: Number_ToFloat(progress.currentTime)
        isFinished: __MediaProgressMapper_GetBoolean(progress.isFinished)
    }
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_GetItemId
'-------------------------------------------------------------------------------
function __MediaProgressMapper_GetItemId(progress as dynamic) as dynamic
    if progress = invalid then return invalid
    if progress.itemId <> invalid then return progress.itemId
    if progress.libraryItemId <> invalid then return progress.libraryItemId
    if progress.mediaItemId <> invalid then return progress.mediaItemId
    if progress.id <> invalid then return progress.id

    return invalid
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_GetLegacyItemId
'-------------------------------------------------------------------------------
function __MediaProgressMapper_GetLegacyItemId(progress as dynamic) as dynamic
    if progress = invalid then return invalid
    if progress.extraData <> invalid and progress.extraData.libraryItemId <> invalid then return progress.extraData.libraryItemId
    return invalid
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_ToArray
'-------------------------------------------------------------------------------
function __MediaProgressMapper_ToArray(values as dynamic) as dynamic
    if values = invalid then return invalid

    valuesType = Type(values)
    if valuesType = "roArray" then return values
    if valuesType <> "roAssociativeArray" then return invalid

    arrayValues = []
    for each key in values
        value = values[key]
        valueType = Type(value)

        if valueType = "roAssociativeArray" then
            item = {}
            for each fieldName in value
                item[fieldName] = value[fieldName]
            end for

            if __MediaProgressMapper_HasAnyId(item) = false then item.itemId = key
            arrayValues.Push(item)
        else
            arrayValues.Push({
                itemId: key
                currentTime: value
            })
        end if
    end for

    return arrayValues
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_HasAnyId
'-------------------------------------------------------------------------------
function __MediaProgressMapper_HasAnyId(progress as dynamic) as boolean
    if progress = invalid then return false
    if progress.itemId <> invalid and progress.itemId <> "" then return true
    if progress.libraryItemId <> invalid and progress.libraryItemId <> "" then return true
    if progress.mediaItemId <> invalid and progress.mediaItemId <> "" then return true
    if progress.id <> invalid and progress.id <> "" then return true
    return false
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_HasProgressFields
'-------------------------------------------------------------------------------
function __MediaProgressMapper_HasProgressFields(progress as dynamic) as boolean
    if progress = invalid then return false
    if progress.currentTime <> invalid then return true
    if progress.progress <> invalid then return true
    if progress.isFinished <> invalid then return true
    if progress.hideFromContinueListening <> invalid then return true
    return false
end function

'-------------------------------------------------------------------------------
' __MediaProgressMapper_GetItemDuration
'-------------------------------------------------------------------------------
function __MediaProgressMapper_GetItemDuration(item as dynamic) as float
    if item = invalid then return 0
    if item.duration <> invalid then return Number_ToFloat(item.duration)
    if item.media <> invalid and item.media.duration <> invalid then return Number_ToFloat(item.media.duration)

    return 0
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
