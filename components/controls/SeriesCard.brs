sub init()
    m.panel = m.top.findNode("panel")
    m.cover = m.top.findNode("cover")
    m.title = m.top.findNode("title")
    m.subtitle = m.top.findNode("subtitle")
    m.focusRing = m.top.findNode("focusRing")
    m.focusRing.color = "E09B4200"
end sub

sub showContent()
    item = m.top.itemContent
    if item = invalid then return
    m.title.text = FirstNonEmpty([item.title], "")
    m.subtitle.text = FirstNonEmpty([item.subtitle], "")
    poster = FirstNonEmpty([item.hdPosterUrl, item.sdPosterUrl], "pkg:/images/placeholder_cover.png")
    m.cover.uri = poster
end sub

sub showFocus()
    if m.top.itemHasFocus = true then
        m.panel.color = "1D3046FF"
        m.focusRing.color = "E09B42FF"
    else
        m.panel.color = "142336FF"
        m.focusRing.color = "E09B4200"
    end if
end sub
