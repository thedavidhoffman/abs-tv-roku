'-------------------------------------------------------------------------------
' String_Trim
'-------------------------------------------------------------------------------
function String_Trim(value as dynamic) as string
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
' String_Replace
'-------------------------------------------------------------------------------
function String_Replace(value as string, oldValue as string, newValue as string) as string
    result = ""
    remaining = value
    index = Instr(1, remaining, oldValue)

    while index > 0
        result = result + Left(remaining, index - 1) + newValue
        remaining = Mid(remaining, index + Len(oldValue))
        index = Instr(1, remaining, oldValue)
    end while

    return result + remaining
end function

'-------------------------------------------------------------------------------
' String_CollapseWhitespace
'-------------------------------------------------------------------------------
function String_CollapseWhitespace(value as string) as string
    result = ""
    previousWasSpace = false

    for i = 1 to Len(value)
        char = Mid(value, i, 1)
        isSpace = (char = " " or char = Chr(10) or char = Chr(13) or char = Chr(9))

        if isSpace then
            if previousWasSpace = false then result = result + " "
            previousWasSpace = true
        else
            result = result + char
            previousWasSpace = false
        end if
    end for

    return String_Trim(result)
end function

'-------------------------------------------------------------------------------
' String_StripHtmlMarkup
'-------------------------------------------------------------------------------
function String_StripHtmlMarkup(value as dynamic) as string
    text = SafeString(value, "")
    text = String_Replace(text, "</p> <p>", Chr(10))
    text = String_Replace(text, "</p><p>", Chr(10))
    result = ""
    insideTag = false

    for i = 1 to Len(text)
        char = Mid(text, i, 1)
        if char = "<" then
            insideTag = true
        else if char = ">" then
            insideTag = false
            result = result + " "
        else if insideTag = false then
            result = result + char
        end if
    end for

    result = String_Replace(result, "&nbsp;", " ")
    result = String_Replace(result, "&amp;", "&")
    result = String_Replace(result, "&quot;", Chr(34))
    result = String_Replace(result, "&#39;", "'")
    result = String_Replace(result, "&apos;", "'")
    result = String_Replace(result, "&lt;", "<")
    result = String_Replace(result, "&gt;", ">")

    return String_CollapseWhitespace(result)
end function

'-------------------------------------------------------------------------------
' String_IsYearText
'-------------------------------------------------------------------------------
function String_IsYearText(value as string) as boolean
    if Len(value) <> 4 then return false
    year = int(val(value))
    if year < 1000 or year > 9999 then return false
    return value = year.ToStr()
end function

'-------------------------------------------------------------------------------
' String_GetJoinedText
'-------------------------------------------------------------------------------
function String_GetJoinedText(values as dynamic) as string
    if values = invalid then return ""

    if Type(values) <> "roArray" and Type(values) <> "roAssociativeArray" then
        return String_Trim(values.ToStr())
    end if

    result = ""
    for each value in values
        text = String_Trim(value.ToStr())
        if text <> "" then
            if result <> "" then result = result + ", "
            result = result + text
        end if
    end for

    return result
end function
