'-------------------------------------------------------------------------------
' LibraryItemLookup_Build
'-------------------------------------------------------------------------------
function LibraryItemLookup_Build(items as dynamic) as object
    lookup = {}
    if items = invalid then return lookup

    for each item in items
        if item <> invalid then
            __LibraryItemLookup_AddCandidate(lookup, item, item.id)
            __LibraryItemLookup_AddCandidate(lookup, item, item.libraryItemId)
            __LibraryItemLookup_AddCandidate(lookup, item, item.mediaItemId)
            if item.media <> invalid then
                __LibraryItemLookup_AddCandidate(lookup, item, item.media.id)
                __LibraryItemLookup_AddCandidate(lookup, item, item.media.libraryItemId)
            end if
        end if
    end for

    return lookup
end function

'-------------------------------------------------------------------------------
' LibraryItemLookup_GetItemsByIds
'-------------------------------------------------------------------------------
function LibraryItemLookup_GetItemsByIds(libraryItemIds as dynamic, lookup as object) as object
    items = []
    if lookup = invalid then return items

    ids = __LibraryItemLookup_GetIdList(libraryItemIds)
    for each id in ids
        item = lookup[id]
        if item <> invalid then items.Push(item)
    end for

    return items
end function

'-------------------------------------------------------------------------------
' __LibraryItemLookup_AddCandidate
'-------------------------------------------------------------------------------
sub __LibraryItemLookup_AddCandidate(lookup as object, item as dynamic, id as dynamic)
    idText = __LibraryItemLookup_GetText(id)
    if idText = "" then return
    if lookup[idText] = invalid then lookup[idText] = item
end sub

'-------------------------------------------------------------------------------
' __LibraryItemLookup_GetIdList
'-------------------------------------------------------------------------------
function __LibraryItemLookup_GetIdList(libraryItemIds as dynamic) as object
    ids = []
    if libraryItemIds = invalid then return ids

    idsType = Type(libraryItemIds)
    if idsType = "roArray" then
        for each id in libraryItemIds
            idText = __LibraryItemLookup_GetText(id)
            if idText <> "" then ids.Push(idText)
        end for
    else
        idText = __LibraryItemLookup_GetText(libraryItemIds)
        if idText <> "" then ids.Push(idText)
    end if

    return ids
end function

'-------------------------------------------------------------------------------
' __LibraryItemLookup_GetText
'-------------------------------------------------------------------------------
function __LibraryItemLookup_GetText(value as dynamic) as string
    if value = invalid then return ""
    return value.ToStr()
end function
