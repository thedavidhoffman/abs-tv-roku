'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetMetadata
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetMetadata(item as dynamic) as dynamic
    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then
        return item.media.metadata
    end if

    return {}
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetTitle
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetTitle(item as dynamic) as string
    title = "Untitled"

    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then
        title = FirstNonEmpty([item.media.metadata.title], title)
    else if item <> invalid and item.title <> invalid then
        title = SafeString(item.title, title)
    end if

    return title
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetAuthor
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetAuthor(metadata as dynamic) as string
    return FirstNonEmpty([metadata.authorName, metadata.author], "Unknown")
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetNarrators
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetNarrators(metadata as dynamic) as string
    return FirstNonEmpty([metadata.narratorName, metadata.narrator], "Unknown")
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetDescription
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetDescription(metadata as dynamic) as string
    return StringUtils_StripHtmlMarkup(FirstNonEmpty([metadata.description, metadata.subtitle], "No description available."))
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetPublishDate
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetPublishDate(metadata as dynamic) as string
    return FirstNonEmpty([metadata.publishedYear, metadata.publishedDate, metadata.releaseDate], "Unknown")
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetPublishYear
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetPublishYear(metadata as dynamic) as string
    year = FirstNonEmpty([metadata.publishedYear], "")
    if year <> "" then return year

    publishedDate = FirstNonEmpty([metadata.publishedDate, metadata.releaseDate], "")
    if Len(publishedDate) >= 4 then
        possibleYear = Left(publishedDate, 4)
        if StringUtils_IsYearText(possibleYear) then return possibleYear
    end if

    return "Unknown"
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetCategory
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetCategory(metadata as dynamic) as string
    category = StringUtils_GetJoinedText(metadata.genres)
    if category <> "" then return category

    category = StringUtils_GetJoinedText(metadata.categories)
    if category <> "" then return category

    return FirstNonEmpty([metadata.genre, metadata.category], "")
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetGenres
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetGenres(metadata as dynamic) as string
    genres = StringUtils_GetJoinedText(metadata.genres)
    if genres <> "" then return genres

    categories = StringUtils_GetJoinedText(metadata.categories)
    if categories <> "" then return categories

    return FirstNonEmpty([metadata.genre, metadata.category], "Unknown")
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetTags
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetTags(metadata as dynamic) as string
    tags = StringUtils_GetJoinedText(metadata.tags)
    if tags <> "" then return tags
    return FirstNonEmpty([metadata.tag, metadata.keywords], "None")
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetDuration
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetDuration(item as dynamic) as string
    totalSeconds = LibraryItemMetadata_GetDurationSeconds(item)
    if totalSeconds <= 0 then return "Unknown"

    hours = int(totalSeconds / 3600)
    minutes = int((totalSeconds mod 3600) / 60)

    if hours > 0 and minutes > 0 then return hours.ToStr() + " hr " + minutes.ToStr() + " min"
    if hours > 0 then return hours.ToStr() + " hr"
    if minutes > 0 then return minutes.ToStr() + " min"
    return "Less than 1 min"
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetDurationSeconds
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetDurationSeconds(item as dynamic) as integer
    duration = invalid
    if item <> invalid and item.media <> invalid then duration = item.media.duration
    if duration = invalid and item <> invalid then duration = item.duration
    if duration = invalid then return 0

    return int(val(duration.ToStr()))
end function

'-------------------------------------------------------------------------------
' LibraryItemMetadata_GetNameCount
'-------------------------------------------------------------------------------
function LibraryItemMetadata_GetNameCount(values as dynamic, fallbackText as string) as integer
    if values <> invalid then
        if Type(values) = "roArray" then return values.Count()
        if Type(values) = "roAssociativeArray" then return values.Count()
    end if

    text = TrimString(fallbackText)
    if text = "" or text = "Unknown" then return 0
    if Instr(1, text, ",") > 0 or Instr(1, text, " and ") > 0 or Instr(1, text, " & ") > 0 then return 2
    return 1
end function
