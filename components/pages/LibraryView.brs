'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.libraryStatus = m.top.findNode("libraryStatus")
    m.libraryList = m.top.findNode("libraryList")
    m.libraryApiTask = m.top.findNode("libraryApiTask")

    m.libraryApiTask.observeField("response", "onLibraryApiResponse")
    onLibraryItemsChanged()
end sub

'-------------------------------------------------------------------------------
' onLoadRequestChanged
'-------------------------------------------------------------------------------
sub onLoadRequestChanged()
    request = m.top.loadRequest
    if request = invalid then return

    setStatus("Loading library...")
    m.libraryApiTask.request = {
        action: "loadLibrary"
        server: request.server
        token: request.token
        bookLibraryId: request.bookLibraryId
    }
    m.libraryApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onLibraryApiResponse
'-------------------------------------------------------------------------------
sub onLibraryApiResponse()
    response = m.libraryApiTask.response
    if response = invalid then return

    if response.ok <> true then
        m.top.errorResponse = response
        setStatus(response.errorMessage)
        return
    end if

    if response.action = "loadLibrary" then
        m.top.libraryItems = response.libraryItems
        setStatus("")
    end if
end sub

'-------------------------------------------------------------------------------
' onLibraryItemsChanged
'-------------------------------------------------------------------------------
sub onLibraryItemsChanged()
    if m.libraryList = invalid then return

    root = CreateObject("roSGNode", "ContentNode")
    items = m.top.libraryItems

    if items <> invalid then
        for each item in items
            if item.mediaType = invalid or item.mediaType = "book" then
                node = CreateObject("roSGNode", "ContentNode")
                node.title = getLibraryItemTitle(item)
                root.appendChild(node)
            end if
        end for
    end if

    if root.getChildCount() = 0 then
        node = CreateObject("roSGNode", "ContentNode")
        node.title = "No titles found"
        root.appendChild(node)
    end if

    m.libraryList.content = root
end sub

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as dynamic)
    if m.libraryStatus = invalid then return
    m.libraryStatus.text = SafeString(message, "")
end sub

'-------------------------------------------------------------------------------
' getLibraryItemTitle
'-------------------------------------------------------------------------------
function getLibraryItemTitle(item as dynamic) as string
    title = "Untitled"

    if item <> invalid and item.media <> invalid and item.media.metadata <> invalid then
        title = FirstNonEmpty([item.media.metadata.title], title)
    else if item <> invalid and item.title <> invalid then
        title = SafeString(item.title, title)
    end if

    return title
end function
