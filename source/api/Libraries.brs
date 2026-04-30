'-------------------------------------------------------------------------------
' Libraries API
'-------------------------------------------------------------------------------
' Loads and maps top-level Audiobookshelf libraries from /api/libraries. These
' are typically [audiobooks] or [audiobooks, podcasts].

'-------------------------------------------------------------------------------
' Libraries_Load
'-------------------------------------------------------------------------------
function Libraries_Load(server as String, token as Dynamic) as Object

    ? "(API) Libraries_Load..."

    result = HttpClient_Request(server + "/api/libraries", "GET", token, invalid)
    if result.ok <> true then return result

    ? ""
    
    return {
        ok: true
        libraries: __Libraries_Map(result.data)
    }
end function

'-------------------------------------------------------------------------------
' __Libraries_Map
'-------------------------------------------------------------------------------
function __Libraries_Map(payload as Dynamic) as Object
    mappedLibraries = []
    libraries = invalid

    if payload <> invalid then
        if payload.libraries <> invalid then
            libraries = payload.libraries
        else if Type(payload) = "roArray" then
            libraries = payload
        end if
    end if

    if libraries <> invalid then
        for each library in libraries
            mappedLibraries.Push({
                id: library.id
                name: library.name
            })
        end for
    end if

    return mappedLibraries
end function
