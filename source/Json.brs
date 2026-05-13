' JSON helpers for outbound API bodies.
'
' Roku FormatJson() lowercases object keys during serialization. Audiobookshelf
' API fields are case-sensitive, unlike many .NET JSON consumers where key
' casing may be tolerated. These helpers preserve exact key casing by requiring
' API field names as explicit string literals.

'-------------------------------------------------------------------------------
' Json_String
'-------------------------------------------------------------------------------
function Json_String(value as dynamic) as string
    text = SafeString(value, "")
    text = String_Replace(text, "\", "\\")
    text = String_Replace(text, Chr(34), "\" + Chr(34))
    return Chr(34) + text + Chr(34)
end function

'-------------------------------------------------------------------------------
' Json_Pair
'-------------------------------------------------------------------------------
function Json_Pair(name as string, value as dynamic) as string
    return Json_String(name) + ":" + Json_String(value)
end function

'-------------------------------------------------------------------------------
' Json_BooleanPair
'-------------------------------------------------------------------------------
function Json_BooleanPair(name as string, value as dynamic) as string
    text = "false"
    if value = true then text = "true"
    return Json_String(name) + ":" + text
end function

'-------------------------------------------------------------------------------
' Json_NumberPair
'-------------------------------------------------------------------------------
function Json_NumberPair(name as string, value as dynamic) as string
    return Json_String(name) + ":" + Json_Number(value)
end function

'-------------------------------------------------------------------------------
' Json_ArrayPair
'-------------------------------------------------------------------------------
function Json_ArrayPair(name as string, values as dynamic) as string
    parts = []
    if values <> invalid then
        for each value in values
            parts.Push(Json_String(value))
        end for
    end if

    return Json_String(name) + ":[" + Json_JoinParts(parts) + "]"
end function

'-------------------------------------------------------------------------------
' Json_ObjectPair
'-------------------------------------------------------------------------------
function Json_ObjectPair(name as string, parts as object) as string
    return Json_String(name) + ":" + Json_Object(parts)
end function

'-------------------------------------------------------------------------------
' Json_Object
'-------------------------------------------------------------------------------
function Json_Object(parts as object) as string
    return "{" + Json_JoinParts(parts) + "}"
end function

'-------------------------------------------------------------------------------
' Json_JoinParts
'-------------------------------------------------------------------------------
function Json_JoinParts(parts as object) as string
    if parts = invalid or parts.Count() = 0 then return ""

    text = ""
    for i = 0 to parts.Count() - 1
        if i > 0 then text = text + ","
        text = text + parts[i]
    end for

    return text
end function

'-------------------------------------------------------------------------------
' Json_Number
'-------------------------------------------------------------------------------
function Json_Number(value as dynamic) as string
    if value = invalid then return "0"
    numberValue = val(value.ToStr())
    text = numberValue.ToStr()
    if Instr(1, text, ",") > 0 then text = String_Replace(text, ",", "")
    return text
end function
