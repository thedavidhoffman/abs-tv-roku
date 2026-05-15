'-------------------------------------------------------------------------------
' SeriesProgress_GetProgress
'-------------------------------------------------------------------------------
function SeriesProgress_GetProgress(seriesItem as dynamic, allLibraryItemLookup as object, mediaProgress as dynamic) as object
    totalCurrentTime = 0.0
    totalDuration = 0.0

    childItems = __SeriesProgress_GetChildItems(seriesItem, allLibraryItemLookup)
    for each childItem in childItems
        childProgress = ProgressData_GetItemProgress(childItem, mediaProgress)
        childDuration = __SeriesProgress_GetChildDuration(childItem, childProgress)

        if childDuration > 0 then
            totalDuration = totalDuration + childDuration
            totalCurrentTime = totalCurrentTime + __SeriesProgress_GetChildCurrentTime(childProgress, childDuration)
        end if
    end for

    if totalDuration <= 0 then return __SeriesProgress_GetEmptyProgress()

    if totalCurrentTime > totalDuration then totalCurrentTime = totalDuration
    return {
        progress: totalCurrentTime / totalDuration
        currentTime: totalCurrentTime
        duration: totalDuration
        isFinished: totalCurrentTime >= totalDuration
    }
end function

'-------------------------------------------------------------------------------
' __SeriesProgress_GetChildItems
'-------------------------------------------------------------------------------
function __SeriesProgress_GetChildItems(seriesItem as dynamic, allLibraryItemLookup as object) as object
    if seriesItem = invalid then return []
    if seriesItem.collapsedSeries = invalid then return []
    if seriesItem.collapsedSeries.libraryItemIds = invalid then return []

    return LibraryItemLookup_GetItemsByIds(seriesItem.collapsedSeries.libraryItemIds, allLibraryItemLookup)
end function

'-------------------------------------------------------------------------------
' __SeriesProgress_GetChildDuration
'-------------------------------------------------------------------------------
function __SeriesProgress_GetChildDuration(item as dynamic, progress as object) as float
    duration = ProgressData_GetNumberFromFields(progress, ["duration"])
    if duration > 0 then return duration

    duration = invalid
    if item <> invalid and item.media <> invalid then duration = item.media.duration
    if duration = invalid and item <> invalid then duration = item.duration
    if duration = invalid then return 0

    return val(duration.ToStr())
end function

'-------------------------------------------------------------------------------
' __SeriesProgress_GetChildCurrentTime
'-------------------------------------------------------------------------------
function __SeriesProgress_GetChildCurrentTime(progress as object, duration as float) as float
    if progress = invalid or duration <= 0 then return 0
    if progress.isFinished = true then return duration

    currentTime = ProgressData_GetNumberFromFields(progress, ["currentTime"])
    if currentTime > 0 then return __SeriesProgress_ClampSeconds(currentTime, duration)

    return __SeriesProgress_ClampSeconds(ProgressData_GetDerivedCurrentTime(progress.progress, duration), duration)
end function

'-------------------------------------------------------------------------------
' __SeriesProgress_GetEmptyProgress
'-------------------------------------------------------------------------------
function __SeriesProgress_GetEmptyProgress() as object
    return {
        progress: 0
        currentTime: 0
        duration: 0
        isFinished: false
    }
end function

'-------------------------------------------------------------------------------
' __SeriesProgress_ClampSeconds
'-------------------------------------------------------------------------------
function __SeriesProgress_ClampSeconds(value as float, maxValue as float) as float
    if value < 0 then return 0
    if value > maxValue then return maxValue
    return value
end function
