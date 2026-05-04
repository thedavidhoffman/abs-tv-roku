'-------------------------------------------------------------------------------
' CreateLogger
'-------------------------------------------------------------------------------
function CreateLogger(label = "" as string) as object
    log = {
        label: label
        lines: []
        add: __Logger_Add
        log: __Logger_Log
        flush: __Logger_Flush
        text: __Logger_Text
    }

    log.add("....................................")
    return log
end function

'-------------------------------------------------------------------------------
' __Logger_Add
'-------------------------------------------------------------------------------
sub __Logger_Add(message as dynamic)
    m.lines.Push(__Logger_Format(message, m.label))
end sub

'-------------------------------------------------------------------------------
' __Logger_Log
'-------------------------------------------------------------------------------
sub __Logger_Log(message as dynamic)
    text = __Logger_Format(message, m.label)
    m.lines.Push(text)
    ? text
end sub

'-------------------------------------------------------------------------------
' __Logger_Flush
'-------------------------------------------------------------------------------
sub __Logger_Flush()
    output = m.text()
    if output <> "" then ? output
end sub

'-------------------------------------------------------------------------------
' __Logger_Text
'-------------------------------------------------------------------------------
function __Logger_Text() as string

    output = ""

    for each line in m.lines
        output = output + line + Chr(10)
    end for

    return output

end function

'-------------------------------------------------------------------------------
' __Logger_Format
'-------------------------------------------------------------------------------
function __Logger_Format(message as dynamic, label as dynamic) as string

    text = SafeString(message, "")
    if label <> invalid and label <> "" then text = "[" + label + "] " + text
    return text
    
end function
