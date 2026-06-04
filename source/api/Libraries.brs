'-------------------------------------------------------------------------------
' Libraries API
'-------------------------------------------------------------------------------
' Loads and maps top-level Audiobookshelf libraries from /api/libraries. These
' are typically [audiobooks] or [audiobooks, podcasts].

'-------------------------------------------------------------------------------
' Libraries_Load
'-------------------------------------------------------------------------------
function Libraries_Load(server as string, token as dynamic) as object

    log = CreateLogger("(API) Libraries_Load")

    librariesUrl = server + "/api/libraries"
    log.write(librariesUrl)

    result = HttpClient_Request(librariesUrl, "GET", token, invalid)
    if result.ok <> true then return result

    libraries = LibraryMapper_Map(result.data)

    ' TEMP/DEV TOGGLE: limit libraries to the first entry for one-library testing.
    'if libraries <> invalid and libraries.Count() > 1 then libraries = [libraries[0]]

    return {
        ok: true
        libraries: libraries
    }
end function
