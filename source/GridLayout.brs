'-------------------------------------------------------------------------------
' GridLayout_GetColumnCount
'-------------------------------------------------------------------------------
function GridLayout_GetColumnCount(settings as dynamic) as integer
    columns = 6

    if settings <> invalid then
        value = invalid
        if settings["grid-columns"] <> invalid then value = settings["grid-columns"]

        if value <> invalid then columns = int(val(value.ToStr()))
    end if

    if columns = 4 or columns = 5 or columns = 6 then return columns
    return 6
end function

'-------------------------------------------------------------------------------
' GridLayout_GetPosterWidth
'-------------------------------------------------------------------------------
function GridLayout_GetPosterWidth(columnCount as integer) as integer
    if columnCount < 1 then columnCount = 6

    contentWidth = 1792
    gutter = GridLayout_GetHorizontalGutter()
    posterWidth = int((contentWidth - ((columnCount - 1) * gutter)) / columnCount)

    if posterWidth < 1 then return 280
    return posterWidth
end function

'-------------------------------------------------------------------------------
' GridLayout_GetItemHeight
'-------------------------------------------------------------------------------
function GridLayout_GetItemHeight(posterWidth as integer) as integer
    if posterWidth < 1 then posterWidth = 280
    scale = posterWidth / 280
    return posterWidth + int((80 * scale) + 0.5)
end function

'-------------------------------------------------------------------------------
' GridLayout_GetRowHeight
'-------------------------------------------------------------------------------
function GridLayout_GetRowHeight(itemHeight as integer) as integer
    if itemHeight < 1 then itemHeight = 360
    return itemHeight + 45
end function

'-------------------------------------------------------------------------------
' GridLayout_GetHorizontalGutter
'-------------------------------------------------------------------------------
function GridLayout_GetHorizontalGutter() as integer
    return 22
end function
