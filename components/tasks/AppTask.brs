'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.top.functionName = "executeRequest"
end sub

'-------------------------------------------------------------------------------
' executeRequest
'-------------------------------------------------------------------------------
sub executeRequest()
    request = m.top.request
    if request = invalid then
        m.top.response = { ok: false, errorMessage: "Invalid request." }
        return
    end if

    action = request.action
    if action = "login" then
        m.top.response = Authentication_Login(request)
    else if action = "authorize" then
        m.top.response = Authentication_AuthorizeToken(request)
    else if action = "logout" then
        m.top.response = Authentication_Logout(request)
    else if action = "loadLibrary" then
        m.top.response = loadLibrary(request)
    else if action = "startPlayback" then
        m.top.response = startPlayback(request)
    else if action = "loadBooks" then
        m.top.response = loadBooks(request)
    else if action = "loadSeries" then
        m.top.response = loadSeries(request)
    else
        m.top.response = { ok: false, errorMessage: "Unknown request action." }
    end if
end sub

'-------------------------------------------------------------------------------
' loadLibrary
'-------------------------------------------------------------------------------
function loadLibrary(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authResult = HttpClient_Request(server + "/api/authorize", "POST", token, "")
        if authResult.ok <> true then return authResult
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    allItems = []
    page = 0
    limit = 100
    keepLoading = true

    while keepLoading
        libraryUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=" + limit.ToStr() + "&page=" + page.ToStr() + "&sort=media.metadata.title&desc=0&minified=0&collapseseries=0"
        libraryResult = HttpClient_Request(libraryUrl, "GET", token, invalid)
        if libraryResult.ok <> true then return libraryResult

        results = invalid
        if libraryResult.data <> invalid and libraryResult.data.results <> invalid then results = libraryResult.data.results

        if results = invalid or results.Count() = 0 then
            keepLoading = false
        else
            for each item in results
                allItems.Push(item)
            end for

            page = page + 1
            keepLoading = (results.Count() = limit)
        end if
    end while

    return {
        ok: true
        action: "loadLibrary"
        bookLibraryId: bookLibraryId
        libraryItems: allItems
    }
end function

'-------------------------------------------------------------------------------
' loadBooks
'-------------------------------------------------------------------------------
function loadBooks(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authResult = HttpClient_Request(server + "/api/authorize", "POST", token, "")
        if authResult.ok <> true then return authResult
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    continueResult = HttpClient_Request(server + "/api/me/items-in-progress?limit=20", "GET", token, invalid)
    if continueResult.ok <> true then return continueResult

    recentUrl = server + "/api/libraries/" + bookLibraryId + "/items?limit=10&page=0&sort=addedAt&desc=1&minified=0&collapseseries=0"
    recentResult = HttpClient_Request(recentUrl, "GET", token, invalid)
    if recentResult.ok <> true then return recentResult

    return {
        ok: true
        action: "loadBooks"
        bookLibraryId: bookLibraryId
        continueListening: continueResult.data
        recentlyAdded: recentResult.data
    }
end function

'-------------------------------------------------------------------------------
' loadSeries
'-------------------------------------------------------------------------------
function loadSeries(request as Object) as Object
    server = NormalizeServerUrl(request.server)
    token = request.token
    bookLibraryId = request.bookLibraryId

    if bookLibraryId = invalid or bookLibraryId = "" then
        authResult = HttpClient_Request(server + "/api/authorize", "POST", token, "")
        if authResult.ok <> true then return authResult
        bookLibraryId = ResolveBookLibraryId(authResult.data)
    end if

    if bookLibraryId = invalid or bookLibraryId = "" then
        return { ok: false, errorMessage: "No book library was found for this account." }
    end if

    seriesUrl = server + "/api/libraries/" + bookLibraryId + "/series?limit=50&page=0&sort=addedAt&desc=1"
    seriesResult = HttpClient_Request(seriesUrl, "GET", token, invalid)
    if seriesResult.ok <> true then return seriesResult

    return {
        ok: true
        action: "loadSeries"
        bookLibraryId: bookLibraryId
        series: seriesResult.data
    }
end function

