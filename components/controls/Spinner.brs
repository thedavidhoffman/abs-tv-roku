'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.background = m.top.findNode("background")
    m.busySpinner = m.top.findNode("busySpinner")

    if m.background <> invalid then m.background.color = Color().background.primary
    if m.busySpinner <> invalid and m.busySpinner.poster <> invalid then
        m.busySpinner.poster.uri = "pkg:/images/spinner.png"
    end if
    if m.busySpinner <> invalid then m.busySpinner.control = "start"
    m.isActive = false
    if m.top.active = invalid then m.top.active = true
    onActiveChanged()
end sub

'-------------------------------------------------------------------------------
' onActiveChanged
'-------------------------------------------------------------------------------
sub onActiveChanged()
    nextActive = (m.top.active = true)
    if m.isActive = nextActive then return
    m.isActive = nextActive

    nextOpacity = 0
    if nextActive then nextOpacity = 1

    if m.background <> invalid then m.background.opacity = nextOpacity
    if m.busySpinner <> invalid then m.busySpinner.opacity = nextOpacity
end sub
