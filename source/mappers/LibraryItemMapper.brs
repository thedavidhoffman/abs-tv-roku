'-------------------------------------------------------------------------------
' LibraryItemMapper_Map
'-------------------------------------------------------------------------------
function LibraryItemMapper_Map(value as dynamic) as object
    mappedItems = []
    items = __LibraryItemMapper_ToArray(value)
    if items = invalid then return mappedItems

    for each item in items
        mappedItem = __LibraryItemMapper_MapItem(item)
        mappedItems.Push(mappedItem)
    end for

    return mappedItems
end function

'-------------------------------------------------------------------------------
' __LibraryItemMapper_ToArray
'-------------------------------------------------------------------------------
function __LibraryItemMapper_ToArray(value as dynamic) as dynamic
    if value = invalid then return invalid

    valueType = Type(value)
    if valueType = "roArray" then return value
    if valueType <> "roAssociativeArray" then return invalid

    if value.results <> invalid then return value.results

    return invalid
end function

'-------------------------------------------------------------------------------
' __LibraryItemMapper_MapItem
'-------------------------------------------------------------------------------
function __LibraryItemMapper_MapItem(item as dynamic) as object
    mappedItem = {
        id: item.id
        libraryItemId: item.libraryItemId
        mediaItemId: item.mediaItemId
        mediaType: item.mediaType
        title: item.title
        duration: item.duration
        series: item.series
        seriesId: item.seriesId
        seriesSequence: item.seriesSequence
        sequence: item.sequence
        progress: item.progress
        currentTime: item.currentTime
        progressCurrentTime: item.progressCurrentTime
        progressDuration: item.progressDuration
        isFinished: item.isFinished
        progressIsFinished: item.progressIsFinished
    }

    if item.media <> invalid then mappedItem.media = __LibraryItemMapper_MapMedia(item.media)
    if item.userMediaProgress <> invalid then mappedItem.userMediaProgress = __LibraryItemMapper_MapProgress(item.userMediaProgress)
    if item.mediaProgress <> invalid then mappedItem.mediaProgress = __LibraryItemMapper_MapProgress(item.mediaProgress)
    if item.collapsedSeries <> invalid then mappedItem.collapsedSeries = __LibraryItemMapper_MapCollapsedSeries(item.collapsedSeries)

    return mappedItem
end function

'-------------------------------------------------------------------------------
' __LibraryItemMapper_MapMedia
'-------------------------------------------------------------------------------
function __LibraryItemMapper_MapMedia(media as dynamic) as object
    mappedMedia = {
        id: media.id
        libraryItemId: media.libraryItemId
        duration: media.duration
    }

    if media.metadata <> invalid then mappedMedia.metadata = __LibraryItemMapper_MapMetadata(media.metadata)

    return mappedMedia
end function

'-------------------------------------------------------------------------------
' __LibraryItemMapper_MapMetadata
'-------------------------------------------------------------------------------
function __LibraryItemMapper_MapMetadata(metadata as dynamic) as object
    return {
        title: metadata.title
        authorName: metadata.authorName
        author: metadata.author
        authors: metadata.authors
        narrators: metadata.narrators
        narratorName: metadata.narratorName
        narrator: metadata.narrator
        description: metadata.description
        subtitle: metadata.subtitle
        publisher: metadata.publisher
        publishedYear: metadata.publishedYear
        publishedDate: metadata.publishedDate
        releaseDate: metadata.releaseDate
        genres: metadata.genres
        categories: metadata.categories
        genre: metadata.genre
        category: metadata.category
        tags: metadata.tags
        tag: metadata.tag
        keywords: metadata.keywords
        series: metadata.series
        seriesId: metadata.seriesId
        seriesSequence: metadata.seriesSequence
        sequence: metadata.sequence
    }
end function

'-------------------------------------------------------------------------------
' __LibraryItemMapper_MapProgress
'-------------------------------------------------------------------------------
function __LibraryItemMapper_MapProgress(progress as dynamic) as object
    return {
        progress: progress.progress
        currentTime: progress.currentTime
        duration: progress.duration
        isFinished: progress.isFinished
    }
end function

'-------------------------------------------------------------------------------
' __LibraryItemMapper_MapCollapsedSeries
'-------------------------------------------------------------------------------
function __LibraryItemMapper_MapCollapsedSeries(collapsedSeries as dynamic) as object
    return {
        id: collapsedSeries.id
        libraryItemId: collapsedSeries.libraryItemId
        libraryItemIds: collapsedSeries.libraryItemIds
        nameIgnorePrefix: collapsedSeries.nameIgnorePrefix
        name: collapsedSeries.name
        title: collapsedSeries.title
        numBooks: collapsedSeries.numBooks
        bookCount: collapsedSeries.bookCount
        count: collapsedSeries.count
        numItems: collapsedSeries.numItems
    }
end function
