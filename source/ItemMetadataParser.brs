'-------------------------------------------------------------------------------
' ItemMetadataParser_GetMetadata
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetMetadata(item as dynamic) as dynamic
    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then
        return item.media.metadata
    end if

    return {}
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetTitle
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetTitle(item as dynamic) as string
    title = "Untitled"

    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then
        title = FirstNonEmpty([item.media.metadata.title], title)
    else if item <> invalid and item.title <> invalid then
        title = SafeString(item.title, title)
    end if

    return title
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetAuthor
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetAuthor(metadata as dynamic) as string
    return FirstNonEmpty([metadata.authorName, metadata.author], "Unknown")
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetNarrators
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetNarrators(metadata as dynamic) as string
    narrators = String_GetJoinedText(metadata.narrators)
    if narrators <> "" then return narrators
    return FirstNonEmpty([metadata.narratorName, metadata.narrator], "Unknown")
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetDescription
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetDescription(metadata as dynamic) as string
    return String_StripHtmlMarkup(FirstNonEmpty([metadata.description, metadata.subtitle], "No description available."))
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetPublishDate
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetPublishDate(metadata as dynamic) as string
    return FirstNonEmpty([metadata.publishedYear, metadata.publishedDate, metadata.releaseDate], "Unknown")
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetPublishYear
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetPublishYear(metadata as dynamic) as string
    year = FirstNonEmpty([metadata.publishedYear], "")
    if year <> "" then return year

    publishedDate = FirstNonEmpty([metadata.publishedDate, metadata.releaseDate], "")
    if Len(publishedDate) >= 4 then
        possibleYear = Left(publishedDate, 4)
        if String_IsYearText(possibleYear) then return possibleYear
    end if

    return "Unknown"
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetCategory
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetCategory(metadata as dynamic) as string
    category = String_GetJoinedText(metadata.genres)
    if category <> "" then return category

    category = String_GetJoinedText(metadata.categories)
    if category <> "" then return category

    return FirstNonEmpty([metadata.genre, metadata.category], "")
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetGenres
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetGenres(metadata as dynamic) as string
    genres = String_GetJoinedText(metadata.genres)
    if genres <> "" then return genres

    categories = String_GetJoinedText(metadata.categories)
    if categories <> "" then return categories

    return FirstNonEmpty([metadata.genre, metadata.category], "Unknown")
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetTags
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetTags(metadata as dynamic) as string
    tags = String_GetJoinedText(metadata.tags)
    if tags <> "" then return tags
    return FirstNonEmpty([metadata.tag, metadata.keywords], "None")
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetDuration
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetDuration(item as dynamic) as string
    totalSeconds = ItemMetadataParser_GetDurationSeconds(item)
    if totalSeconds <= 0 then return "Unknown"

    hours = int(totalSeconds / 3600)
    minutes = int((totalSeconds mod 3600) / 60)

    if hours > 0 and minutes > 0 then return hours.ToStr() + " hr " + minutes.ToStr() + " min"
    if hours > 0 then return hours.ToStr() + " hr"
    if minutes > 0 then return minutes.ToStr() + " min"
    return "Less than 1 min"
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetDurationSeconds
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetDurationSeconds(item as dynamic) as integer
    duration = invalid
    if item <> invalid and item.media <> invalid then duration = item.media.duration
    if duration = invalid and item <> invalid then duration = item.duration
    if duration = invalid then return 0

    return int(val(duration.ToStr()))
end function

'-------------------------------------------------------------------------------
' ItemMetadataParser_GetNameCount
'-------------------------------------------------------------------------------
function ItemMetadataParser_GetNameCount(values as dynamic, fallbackText as string) as integer
    if values <> invalid then
        if Type(values) = "roArray" then return values.Count()
        if Type(values) = "roAssociativeArray" then return values.Count()
    end if

    text = String_Trim(fallbackText)
    if text = "" or text = "Unknown" then return 0
    if Instr(1, text, ",") > 0 or Instr(1, text, " and ") > 0 or Instr(1, text, " & ") > 0 then return 2
    return 1
end function
