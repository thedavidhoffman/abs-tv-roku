'-------------------------------------------------------------------------------
' StringUtils_Replace
'-------------------------------------------------------------------------------
function StringUtils_Replace(value as string, oldValue as string, newValue as string) as string
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
' StringUtils_CollapseWhitespace
'-------------------------------------------------------------------------------
function StringUtils_CollapseWhitespace(value as string) as string
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

    return TrimString(result)
end function

'-------------------------------------------------------------------------------
' StringUtils_StripHtmlMarkup
'-------------------------------------------------------------------------------
function StringUtils_StripHtmlMarkup(value as dynamic) as string
    text = SafeString(value, "")
    text = StringUtils_Replace(text, "</p> <p>", Chr(10))
    text = StringUtils_Replace(text, "</p><p>", Chr(10))
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

    result = StringUtils_Replace(result, "&nbsp;", " ")
    result = StringUtils_Replace(result, "&amp;", "&")
    result = StringUtils_Replace(result, "&quot;", Chr(34))
    result = StringUtils_Replace(result, "&#39;", "'")
    result = StringUtils_Replace(result, "&apos;", "'")
    result = StringUtils_Replace(result, "&lt;", "<")
    result = StringUtils_Replace(result, "&gt;", ">")

    return StringUtils_CollapseWhitespace(result)
end function

'-------------------------------------------------------------------------------
' StringUtils_IsYearText
'-------------------------------------------------------------------------------
function StringUtils_IsYearText(value as string) as boolean
    if Len(value) <> 4 then return false
    year = int(val(value))
    if year < 1000 or year > 9999 then return false
    return value = year.ToStr()
end function

'-------------------------------------------------------------------------------
' StringUtils_GetJoinedText
'-------------------------------------------------------------------------------
function StringUtils_GetJoinedText(values as dynamic) as string
    if values = invalid then return ""

    if Type(values) <> "roArray" and Type(values) <> "roAssociativeArray" then
        return TrimString(values.ToStr())
    end if

    result = ""
    for each value in values
        text = TrimString(value.ToStr())
        if text <> "" then
            if result <> "" then result = result + ", "
            result = result + text
        end if
    end for

    return result
end function
