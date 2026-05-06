'-------------------------------------------------------------------------------
' Logger
'-------------------------------------------------------------------------------
' Creates a small logger object with buffered and unbuffered write paths.
' Unbuffered logging writes each line immediately when log.write(message) is
' called. Buffered logging stores lines until log.flush() writes the full buffer.
' The buffer exists for work that executes on its own task/thread, so related log
' statements can be grouped together instead of interleaved with other output.

'-------------------------------------------------------------------------------
' CreateLogger
'-------------------------------------------------------------------------------
function CreateLogger(label = "" as string, buffered = true as boolean) as object

    log = {
        label: label
        buffered: buffered
        buffer: []
        writeHead: __Logger_WriteHead
        write: __Logger_Write
        writeBracketed: __Logger_WriteBracketed
        error: __Logger_Error
        flush: __Logger_Flush
        text: __Logger_Text
    }

    if buffered = true then log.WriteHead()

    return log

end function

'-------------------------------------------------------------------------------
' __Logger_WriteHead
'-------------------------------------------------------------------------------
function __Logger_WriteHead() as object
    m.write("....................................")
    return m
end function

'-------------------------------------------------------------------------------
' __Logger_Write
'-------------------------------------------------------------------------------
function __Logger_Write(message as dynamic) as object

    line = __Logger_Format(message, m.label)

    if m.buffered then
        m.buffer.Push(line)
    else
        ? line
    end if

    return m

end function

'-------------------------------------------------------------------------------
' __Logger_WriteBracketed
'-------------------------------------------------------------------------------
function __Logger_WriteBracketed(array as dynamic) as object

    output = ""

    for each line in array
        output = output + "[" + line + "] "
    end for

    m.write(output)

    return m

end function

'-------------------------------------------------------------------------------
' __Logger_Error
'-------------------------------------------------------------------------------
function __Logger_Error(message as dynamic) as object

    message = "ERROR: " + message
    return m.write(message)

end function

'-------------------------------------------------------------------------------
' __Logger_Flush
'-------------------------------------------------------------------------------
sub __Logger_Flush()
    output = m.text()
    if output <> "" then ? output
    m.buffer = []
end sub

'-------------------------------------------------------------------------------
' __Logger_Text
'-------------------------------------------------------------------------------
function __Logger_Text() as string

    output = ""

    for each line in m.buffer
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
