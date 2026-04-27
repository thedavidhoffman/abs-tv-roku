'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.bg = m.top.findNode("bg")
    m.textLabel = m.top.findNode("textLabel")
    m.buttonSelectedCounter = 0
    if m.top.buttonWidth = invalid or m.top.buttonWidth <= 0 then m.top.buttonWidth = 300
    if m.top.buttonHeight = invalid or m.top.buttonHeight <= 0 then m.top.buttonHeight = 56
    if m.top.headerBgColor = invalid or m.top.headerBgColor = 0 then m.top.headerBgColor = &h12112BFF
    m.top.observeField("focusedChild", "onFocusChanged")
    onDimensionsChanged()
    onTextChanged()
    onFocusVisualChanged()
end sub

'-------------------------------------------------------------------------------
' onTextChanged
'-------------------------------------------------------------------------------
sub onTextChanged()
    if m.textLabel <> invalid then m.textLabel.text = m.top.text
end sub

'-------------------------------------------------------------------------------
' onDimensionsChanged
'-------------------------------------------------------------------------------
sub onDimensionsChanged()
    width = int(m.top.buttonWidth)
    height = int(m.top.buttonHeight)
    if width <= 0 then width = 300
    if height <= 0 then height = 56

    if m.bg <> invalid then
        m.bg.width = width
        m.bg.height = height
    end if

    if m.textLabel <> invalid then
        m.textLabel.width = width
        m.textLabel.translation = [0, int((height - 32) / 2)]
    end if
end sub

'-------------------------------------------------------------------------------
' onFocusVisualChanged
'-------------------------------------------------------------------------------
sub onFocusVisualChanged()
    
    if m.bg <> invalid then
        if m.top.hasFocusVisual = true then
            m.bg.color = &hFFFFFFFF
        else
            m.bg.color = &hFFFFFF00
        end if
    end if

    if m.textLabel <> invalid then
        if m.top.hasFocusVisual = true then
            m.textLabel.color = m.top.headerBgColor
        else
            m.textLabel.color = &hFFFFFFFF
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' onFocusChanged
'-------------------------------------------------------------------------------
sub onFocusChanged()
    m.top.hasFocusVisual = m.top.isInFocusChain()
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "OK" or key = "select" then
        m.buttonSelectedCounter = m.buttonSelectedCounter + 1
        m.top.buttonSelected = m.buttonSelectedCounter
        return true
    end if

    return false
end function
