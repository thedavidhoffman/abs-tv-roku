'-------------------------------------------------------------------------------
' NormalizeServerUrl
'-------------------------------------------------------------------------------
function NormalizeServerUrl(server as string) as string
    if server = invalid then return ""
    normalized = TrimString(server)
    if normalized = "" then return ""
    if Instr(1, LCase(normalized), "http://") <> 1 and Instr(1, LCase(normalized), "https://") <> 1 then
        normalized = "http://" + normalized
    end if
    while Right(normalized, 1) = "/"
        normalized = Left(normalized, Len(normalized) - 1)
    end while
    return normalized
end function

'-------------------------------------------------------------------------------
' SafeString
'-------------------------------------------------------------------------------
function SafeString(value as dynamic, fallback as string) as string
    if value = invalid then return fallback
    return value.ToStr()
end function

'-------------------------------------------------------------------------------
' FirstNonEmpty
'-------------------------------------------------------------------------------
function FirstNonEmpty(values as object, fallback as string) as string
    for each value in values
        if value <> invalid then
            text = TrimString(value.ToStr())
            if text <> "" then return text
        end if
    end for
    return fallback
end function

'-------------------------------------------------------------------------------
' TrimString
'-------------------------------------------------------------------------------
function TrimString(value as dynamic) as string
    if value = invalid then return ""

    text = value.ToStr()
    startIndex = 0
    endIndex = Len(text) - 1

    while startIndex <= endIndex and Mid(text, startIndex + 1, 1) = " "
        startIndex = startIndex + 1
    end while

    while endIndex >= startIndex and Mid(text, endIndex + 1, 1) = " "
        endIndex = endIndex - 1
    end while

    if startIndex > endIndex then return ""
    return Mid(text, startIndex + 1, endIndex - startIndex + 1)
end function

'-------------------------------------------------------------------------------
' ResolveBookLibraryId
'-------------------------------------------------------------------------------
function ResolveBookLibraryId(payload as dynamic) as dynamic
    if payload = invalid then return invalid

    if payload.userDefaultLibraryId <> invalid then
        defaultId = payload.userDefaultLibraryId.ToStr()
        if payload.libraries <> invalid then
            for each library in payload.libraries
                if library.id = defaultId and library.mediaType = "book" then
                    return defaultId
                end if
            end for
        end if
    end if

    libraries = invalid
    if payload.libraries <> invalid then libraries = payload.libraries
    if libraries = invalid and payload.user <> invalid and payload.user.librariesAccessible <> invalid then
        libraries = payload.user.librariesAccessible
    end if

    if libraries <> invalid then
        for each library in libraries
            if library.mediaType = "book" then return library.id
        end for
    end if

    return invalid
end function
