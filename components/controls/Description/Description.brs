'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.descriptionFocusRing = m.top.findNode("descriptionFocusRing")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.top.observeField("focusedChild", "onFocusChanged")

    ' padding value for focus ring
    m.focusRingPadding = 20

    ' for computing the height of the focus ring per line of text
    m.focusRingLineHeightTranslation = 46

    ' default width and numLines if not set
    if m.top.width = invalid or m.top.width <= 0 then m.top.width = 1040
    if m.top.numLines = invalid or m.top.numLines <= 0 then m.top.numLines = 5

    onTextChanged()
    onWidthChanged()
    onNumLinesChanged()
end sub

'-------------------------------------------------------------------------------
' onTextChanged
'-------------------------------------------------------------------------------
sub onTextChanged()
    if m.descriptionLabel <> invalid then m.descriptionLabel.text = m.top.text
    updateTruncationState()
end sub

'-------------------------------------------------------------------------------
' onWidthChanged
'-------------------------------------------------------------------------------
sub onWidthChanged()
    if m.descriptionLabel <> invalid then m.descriptionLabel.width = m.top.width

    if m.descriptionFocusRing <> invalid then

        ' add padding to the width of the focus ring
        m.descriptionFocusRing.width = m.top.width + (m.focusRingPadding * 2)

        ' postition the focus ring left by half its padding
        translation = m.descriptionFocusRing.translation
        y = 0
        if translation <> invalid and translation.Count() > 1 then y = translation[1]
        m.descriptionFocusRing.translation = [-m.focusRingPadding, y]

    end if

    updateTruncationState()
end sub

'-------------------------------------------------------------------------------
' onNumLinesChanged
'-------------------------------------------------------------------------------
sub onNumLinesChanged()

    if m.descriptionLabel <> invalid then m.descriptionLabel.numLines = m.top.numLines

    if m.descriptionFocusRing <> invalid then

        ' add padding to the height of the focus ring
        m.descriptionFocusRing.height = m.top.numLines * m.focusRingLineHeightTranslation

        ' postition the focus ring up by half its padding
        translation = m.descriptionFocusRing.translation
        x = 0
        if translation <> invalid and translation.Count() > 0 then x = translation[0]
        m.descriptionFocusRing.translation = [x, -m.focusRingPadding]

    end if

    updateTruncationState()

end sub

'-------------------------------------------------------------------------------
' updateTruncationState
'-------------------------------------------------------------------------------
sub updateTruncationState()
    isTruncated = descriptionNeedsFocus()
    m.top.isTruncated = isTruncated
    m.top.canAcceptFocus = isTruncated
    updateFocusRingVisibility()
end sub

'-------------------------------------------------------------------------------
' onFocusChanged
'-------------------------------------------------------------------------------
sub onFocusChanged()
    updateFocusRingVisibility()
end sub

'-------------------------------------------------------------------------------
' updateFocusRingVisibility
'-------------------------------------------------------------------------------
sub updateFocusRingVisibility()
    if m.descriptionFocusRing = invalid then return
    m.descriptionFocusRing.visible = (m.top.isInFocusChain() and m.top.isTruncated)
end sub

'-------------------------------------------------------------------------------
' descriptionNeedsFocus
'-------------------------------------------------------------------------------
function descriptionNeedsFocus() as boolean

    text = SafeString(m.top.text)
    if text = "" then return false

    lineLimit = m.top.numLines
    if lineLimit = invalid or lineLimit <= 0 then lineLimit = 5

    width = m.top.width
    if width = invalid or width <= 0 then width = 1040

    charsPerLine = int(width / 12)
    if charsPerLine < 1 then charsPerLine = 1

    estimatedLines = 1
    currentLineLength = 0

    for i = 1 to Len(text)

        char = Mid(text, i, 1)
        
        if char = Chr(10) or char = Chr(13) then
            estimatedLines = estimatedLines + 1
            currentLineLength = 0
        else
            currentLineLength = currentLineLength + 1
            if currentLineLength > charsPerLine then
                estimatedLines = estimatedLines + 1
                currentLineLength = 1
            end if
        end if

        if estimatedLines > lineLimit then return true

    end for

    return false
end function
