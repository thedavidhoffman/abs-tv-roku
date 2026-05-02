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
            itemId = __MediaProgressMapper_GetItemId(progress)
            if itemId = invalid or itemId = "" then itemId = __MediaProgressMapper_GetLegacyItemId(progress)

            mappedProgress.Push({
                itemId: itemId
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
