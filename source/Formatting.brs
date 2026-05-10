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
function SafeString(value as dynamic, fallback = "" as string) as string
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
' FormatWithCommas
'-------------------------------------------------------------------------------
function FormatWithCommas(value as dynamic) as string
    if value = invalid then return ""

    text = TrimString(value.ToStr())
    result = ""
    groupCount = 0

    for i = Len(text) to 1 step -1
        result = Mid(text, i, 1) + result
        groupCount = groupCount + 1

        if groupCount = 3 and i > 1 then
            result = "," + result
            groupCount = 0
        end if
    end for

    return result
end function
