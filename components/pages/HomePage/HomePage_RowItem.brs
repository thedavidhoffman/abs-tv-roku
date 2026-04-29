'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.itemVisual = m.top.findNode("itemVisual")
    m.focusFrame = m.top.findNode("focusFrame")
    m.coverPoster = m.top.findNode("coverPoster")
end sub

'-------------------------------------------------------------------------------
' onItemContentChanged
'-------------------------------------------------------------------------------
sub onItemContentChanged()
    item = m.top.itemContent
    if m.coverPoster = invalid or item = invalid then return

    if item.HDPosterUrl <> invalid and item.HDPosterUrl <> "" then
        m.coverPoster.uri = item.HDPosterUrl
    else
        m.coverPoster.uri = "pkg:/images/placeholder_cover.png"
    end if
end sub

'-------------------------------------------------------------------------------
' onRowFocusPercentChanged
'-------------------------------------------------------------------------------
sub onRowFocusPercentChanged()
    if m.coverPoster = invalid then return
    m.coverPoster.opacity = 0.55 + (m.top.rowFocusPercent * 0.45)
end sub
