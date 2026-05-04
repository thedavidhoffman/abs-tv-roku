'-------------------------------------------------------------------------------
' Libraries API
'-------------------------------------------------------------------------------
' Loads and maps top-level Audiobookshelf libraries from /api/libraries. These
' are typically [audiobooks] or [audiobooks, podcasts].

'-------------------------------------------------------------------------------
' Libraries_Load
'-------------------------------------------------------------------------------
function Libraries_Load(server as String, token as Dynamic) as Object

    log = CreateLogger("(API) Libraries_Load")

    librariesUrl = server + "/api/libraries"
    result = HttpClient_Request(librariesUrl, "GET", token, invalid)
    log.add(librariesUrl)
    log.add("status = " + SafeString(result.status, ""))
    if result.ok <> true then
        log.flush()
        return result
    end if

    log.flush()
    
    return {
        ok: true
        libraries: LibraryMapper_Map(result.data)
    }
end function
