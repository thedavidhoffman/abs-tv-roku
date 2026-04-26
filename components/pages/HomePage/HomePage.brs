sub init()
    m.homeTitle = m.top.findNode("homeTitle")
    m.homeSubtitle = m.top.findNode("homeSubtitle")
    m.contentStatus = m.top.findNode("contentStatus")
    m.booksView = m.top.findNode("booksView")
    m.seriesView = m.top.findNode("seriesView")

    if m.top.pageTitle = invalid or m.top.pageTitle = "" then m.top.pageTitle = "Books"
    if m.top.pageSubtitle = invalid or m.top.pageSubtitle = "" then m.top.pageSubtitle = "Pick up right where you left off and see what arrived most recently."
    if m.top.currentTab = invalid or m.top.currentTab = "" then m.top.currentTab = "books"

    onPageTitleChanged()
    onPageSubtitleChanged()
    onStatusMessageChanged()
    onCurrentTabChanged()
end sub

sub onPageTitleChanged()
    if m.homeTitle <> invalid then m.homeTitle.text = m.top.pageTitle
end sub

sub onPageSubtitleChanged()
    if m.homeSubtitle <> invalid then m.homeSubtitle.text = m.top.pageSubtitle
end sub

sub onStatusMessageChanged()
    if m.contentStatus <> invalid then m.contentStatus.text = m.top.statusMessage
end sub

sub onCurrentTabChanged()
    if m.booksView <> invalid then m.booksView.visible = (m.top.currentTab <> "series")
    if m.seriesView <> invalid then m.seriesView.visible = (m.top.currentTab = "series")
end sub
