'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.frankButton = m.top.findNode("frankButton")
    m.top.fixedWidthField = 300
    m.top.observeField("focusedChild", "onFocusChanged")
    onFocusChanged()
end sub

'-------------------------------------------------------------------------------
' onFocusChanged
'-------------------------------------------------------------------------------
sub onFocusChanged()
    if m.frankButton <> invalid then m.frankButton.hasFocusVisual = m.top.isInFocusChain()
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "OK" or key = "select" then
        toggleFrankButtonText()
        return true
    end if

    return false
end function

'-------------------------------------------------------------------------------
' toggleFrankButtonText
'-------------------------------------------------------------------------------
sub toggleFrankButtonText()
    if m.frankButton = invalid then return

    if m.frankButton.text = "Frank" then
        m.frankButton.text = "Monkey"
    else
        m.frankButton.text = "Frank"
    end if
end sub
