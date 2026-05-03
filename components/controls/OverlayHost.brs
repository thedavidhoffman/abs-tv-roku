'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.activeOverlay = invalid
    m.closedCounter = 0
end sub

'-------------------------------------------------------------------------------
' openOverlay
'-------------------------------------------------------------------------------
function openOverlay(request as dynamic) as dynamic
    if request = invalid then return invalid

    closeOverlay()

    componentName = request.componentName
    if componentName = invalid or componentName = "" then return invalid

    overlay = CreateObject("roSGNode", componentName)
    if overlay = invalid then return invalid

    closeField = request.closeField
    if closeField <> invalid and closeField <> "" then
        overlay.observeField(closeField, "onOverlayClosed")
    end if

    m.top.appendChild(overlay)
    m.activeOverlay = overlay

    openFunction = request.openFunction
    if openFunction <> invalid and openFunction <> "" then overlay.callFunc(openFunction)

    return overlay
end function

'-------------------------------------------------------------------------------
' closeOverlay
'-------------------------------------------------------------------------------
sub closeOverlay()
    if m.activeOverlay = invalid then return

    m.top.removeChild(m.activeOverlay)
    m.activeOverlay = invalid
end sub

'-------------------------------------------------------------------------------
' onOverlayClosed
'-------------------------------------------------------------------------------
sub onOverlayClosed()
    closeOverlay()
    m.closedCounter = m.closedCounter + 1
    m.top.closedCounter = m.closedCounter
end sub
