'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.spinnerGroup = m.top.findNode("spinnerGroup")
    m.spinnerTimer = m.top.findNode("spinnerTimer")

    if m.top.active = invalid then m.top.active = true

    if m.spinnerTimer <> invalid then m.spinnerTimer.observeField("fire", "onSpinnerTimerFired")

    onActiveChanged()
end sub

'-------------------------------------------------------------------------------
' onActiveChanged
'-------------------------------------------------------------------------------
sub onActiveChanged()
    isActive = (m.top.active = true)
    if m.spinnerGroup <> invalid then m.spinnerGroup.visible = isActive

    if m.spinnerTimer <> invalid then
        if isActive then
            m.spinnerTimer.control = "start"
        else
            m.spinnerTimer.control = "stop"
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' onSpinnerTimerFired
'-------------------------------------------------------------------------------
sub onSpinnerTimerFired()
    if m.spinnerGroup = invalid then return

    nextRotation = m.spinnerGroup.rotation + 0.392699
    if nextRotation >= 6.28318 then nextRotation = nextRotation - 6.28318
    m.spinnerGroup.rotation = nextRotation
end sub
