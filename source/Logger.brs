'-------------------------------------------------------------------------------
' Logger
'-------------------------------------------------------------------------------
function Logger(label = "" as string) as object
    log = {
        label: label
        lines: []
        add: __Logger_Add
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
    text = SafeString(message, "")
    if m.label <> invalid and m.label <> "" then text = "[" + m.label + "] " + text
    m.lines.Push(text)
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
