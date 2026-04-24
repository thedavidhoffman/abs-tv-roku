sub init()
    m.bg = m.top.findNode("bg")
    m.textLabel = m.top.findNode("textLabel")
    if m.top.buttonWidth = invalid or m.top.buttonWidth <= 0 then m.top.buttonWidth = 300
    if m.top.buttonHeight = invalid or m.top.buttonHeight <= 0 then m.top.buttonHeight = 56
    onDimensionsChanged()
    onTextChanged()
    onFocusVisualChanged()
end sub

sub onTextChanged()
    if m.textLabel <> invalid then m.textLabel.text = m.top.text
end sub

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

sub onFocusVisualChanged()
    if m.bg = invalid then return

    if m.top.hasFocusVisual = true then
        m.bg.color = &hE09B42FF
        if m.textLabel <> invalid then m.textLabel.color = &h0F1A2AFF
    else
        m.bg.color = &hE09B4280
        if m.textLabel <> invalid then m.textLabel.color = &h0F1A2AFF
    end if
end sub
