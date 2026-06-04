'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    initValues()
    initStyle()
    renderGraph()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.titleLabel = m.top.findNode("titleLabel")
    m.gridLayer = m.top.findNode("gridLayer")
    m.lineLayer = m.top.findNode("lineLayer")
    m.markerLayer = m.top.findNode("markerLayer")
    m.labelLayer = m.top.findNode("labelLayer")
end sub

'-------------------------------------------------------------------------------
' initValues
'-------------------------------------------------------------------------------
sub initValues()
    m.layoutState = {
        left: 86
        top: 76
        right: 28
        bottom: 58
        plotWidth: 782
        plotHeight: 360
    }
    m.palette = Color()
end sub

'-------------------------------------------------------------------------------
' initStyle
'-------------------------------------------------------------------------------
sub initStyle()
    if m.titleLabel <> invalid then m.titleLabel.color = m.palette.text.heading
end sub

'-------------------------------------------------------------------------------
' onStatsChanged
'-------------------------------------------------------------------------------
sub onStatsChanged()
    renderGraph()
end sub

'-------------------------------------------------------------------------------
' onDimensionsChanged
'-------------------------------------------------------------------------------
sub onDimensionsChanged()
    renderGraph()
end sub

'-------------------------------------------------------------------------------
' renderGraph
'-------------------------------------------------------------------------------
sub renderGraph()
    updateLayout()
    clearLayer(m.gridLayer)
    clearLayer(m.lineLayer)
    clearLayer(m.markerLayer)
    clearLayer(m.labelLayer)

    points = buildSevenDayPoints(m.top.stats)
    maxMinutes = getMaxMinutes(points)
    axisMax = getAxisMax(maxMinutes)
    renderGrid(axisMax)
    renderDayLabels(points)
    renderSeries(points, axisMax)
end sub

'-------------------------------------------------------------------------------
' updateLayout
'-------------------------------------------------------------------------------
sub updateLayout()
    graphWidth = int(m.top.graphWidth)
    graphHeight = int(m.top.graphHeight)
    if graphWidth <= 0 then graphWidth = 896
    if graphHeight <= 0 then graphHeight = 560

    if m.titleLabel <> invalid then m.titleLabel.width = graphWidth

    m.layoutState.plotWidth = graphWidth - m.layoutState.left - m.layoutState.right
    m.layoutState.plotHeight = graphHeight - m.layoutState.top - m.layoutState.bottom
end sub

'-------------------------------------------------------------------------------
' renderGrid
'-------------------------------------------------------------------------------
sub renderGrid(axisMax as integer)
    tickCount = 6
    for i = 0 to tickCount
        y = getYForValue((axisMax / tickCount) * i, axisMax)
        line = CreateObject("roSGNode", "Rectangle")
        line.translation = [m.layoutState.left, y]
        line.width = m.layoutState.plotWidth
        line.height = 1
        line.color = &hF3F7FB22
        m.gridLayer.appendChild(line)

        label = CreateObject("roSGNode", "Label")
        label.translation = [-10, y - 16]
        label.width = m.layoutState.left - 8
        label.height = 32
        label.horizAlign = "right"
        label.vertAlign = "center"
        label.color = m.palette.text.heading
        label.font = "font:TinyBoldSystemFont"
        label.text = int((axisMax / tickCount) * i).ToStr()
        m.labelLayer.appendChild(label)
    end for
end sub

'-------------------------------------------------------------------------------
' renderDayLabels
'-------------------------------------------------------------------------------
sub renderDayLabels(points as object)
    for i = 0 to points.Count() - 1
        x = getXForIndex(i, points.Count())
        label = CreateObject("roSGNode", "Label")
        label.translation = [x - 34, m.layoutState.top + m.layoutState.plotHeight + 16]
        label.width = 68
        label.height = 32
        label.horizAlign = "center"
        label.vertAlign = "center"
        label.color = m.palette.text.heading
        label.font = "font:SmallestBoldSystemFont"
        label.text = points[i].label
        m.labelLayer.appendChild(label)
    end for
end sub

'-------------------------------------------------------------------------------
' renderSeries
'-------------------------------------------------------------------------------
sub renderSeries(points as object, axisMax as integer)
    if points = invalid or points.Count() = 0 then return

    previousPoint = invalid
    for i = 0 to points.Count() - 1
        x = getXForIndex(i, points.Count())
        y = getYForValue(points[i].minutes, axisMax)

        if previousPoint <> invalid then
            renderSegment(previousPoint.x, previousPoint.y, x, y)
        end if

        renderMarker(x, y)
        previousPoint = { x: x, y: y }
    end for
end sub

'-------------------------------------------------------------------------------
' renderSegment
'-------------------------------------------------------------------------------
sub renderSegment(x1 as float, y1 as float, x2 as float, y2 as float)
    dx = x2 - x1
    dy = y2 - y1
    length = Sqr((dx * dx) + (dy * dy))
    if length <= 0 then return

    segment = CreateObject("roSGNode", "Rectangle")
    segment.translation = [x1, y1 - 2]
    segment.scaleRotateCenter = [0, 2]
    segment.rotation = -Atn(dy / dx)
    segment.width = length
    segment.height = 4
    segment.color = m.palette.accent.primary
    m.lineLayer.appendChild(segment)
end sub

'-------------------------------------------------------------------------------
' renderMarker
'-------------------------------------------------------------------------------
sub renderMarker(x as float, y as float)
    marker = CreateObject("roSGNode", "Rectangle")
    marker.translation = [x - 7, y - 7]
    marker.width = 14
    marker.height = 14
    marker.color = m.palette.accent.primary
    m.markerLayer.appendChild(marker)
end sub

'-------------------------------------------------------------------------------
' buildSevenDayPoints
'-------------------------------------------------------------------------------
function buildSevenDayPoints(stats as dynamic) as object
    days = invalid
    if stats <> invalid then days = stats.days

    dates = getSortedDateKeys(days)
    if dates.Count() = 0 then return buildEmptyPoints()

    latestSerial = dateToSerial(dates[dates.Count() - 1])
    points = []
    for offset = 6 to 0 step -1
        serial = latestSerial - offset
        dateText = serialToDate(serial)
        seconds = 0
        if days <> invalid and days[dateText] <> invalid then seconds = int(days[dateText])
        points.Push({
            date: dateText
            label: getDayLabel(serial)
            minutes: int(seconds / 60)
        })
    end for

    return points
end function

'-------------------------------------------------------------------------------
' buildEmptyPoints
'-------------------------------------------------------------------------------
function buildEmptyPoints() as object
    labels = ["", "", "", "", "", "", ""]
    points = []
    for i = 0 to labels.Count() - 1
        points.Push({ date: "", label: labels[i], minutes: 0 })
    end for

    return points
end function

'-------------------------------------------------------------------------------
' getSortedDateKeys
'-------------------------------------------------------------------------------
function getSortedDateKeys(days as dynamic) as object
    dates = []
    if days = invalid then return dates

    for each key in days
        keyText = SafeString(key, "")
        if Len(keyText) = 10 then dates.Push(keyText)
    end for

    dates.Sort()
    return dates
end function

'-------------------------------------------------------------------------------
' getMaxMinutes
'-------------------------------------------------------------------------------
function getMaxMinutes(points as object) as integer
    maxMinutes = 0
    for each point in points
        if point <> invalid and point.minutes > maxMinutes then maxMinutes = point.minutes
    end for

    return maxMinutes
end function

'-------------------------------------------------------------------------------
' getAxisMax
'-------------------------------------------------------------------------------
function getAxisMax(maxMinutes as integer) as integer
    if maxMinutes <= 0 then return 60

    candidates = [60, 120, 240, 480, 720, 960, 1200, 1440, 1800, 2160]
    for each candidate in candidates
        if maxMinutes <= candidate then return candidate
    end for

    return int(((maxMinutes + 239) / 240)) * 240
end function

'-------------------------------------------------------------------------------
' getXForIndex
'-------------------------------------------------------------------------------
function getXForIndex(index as integer, count as integer) as float
    if count <= 1 then return m.layoutState.left

    return m.layoutState.left + ((m.layoutState.plotWidth / (count - 1)) * index)
end function

'-------------------------------------------------------------------------------
' getYForValue
'-------------------------------------------------------------------------------
function getYForValue(value as float, axisMax as integer) as float
    if axisMax <= 0 then return m.layoutState.top + m.layoutState.plotHeight

    ratio = value / axisMax
    if ratio < 0 then ratio = 0
    if ratio > 1 then ratio = 1

    return m.layoutState.top + m.layoutState.plotHeight - (m.layoutState.plotHeight * ratio)
end function

'-------------------------------------------------------------------------------
' dateToSerial
'-------------------------------------------------------------------------------
function dateToSerial(dateText as string) as integer
    year = Val(Mid(dateText, 1, 4))
    month = Val(Mid(dateText, 6, 2))
    day = Val(Mid(dateText, 9, 2))

    if month <= 2 then year = year - 1
    era = int(year / 400)
    yearOfEra = year - (era * 400)
    monthPrime = month
    if monthPrime > 2 then
        monthPrime = monthPrime - 3
    else
        monthPrime = monthPrime + 9
    end if

    dayOfYear = int(((153 * monthPrime) + 2) / 5) + day - 1
    dayOfEra = (yearOfEra * 365) + int(yearOfEra / 4) - int(yearOfEra / 100) + dayOfYear

    return (era * 146097) + dayOfEra - 719468
end function

'-------------------------------------------------------------------------------
' serialToDate
'-------------------------------------------------------------------------------
function serialToDate(serial as integer) as string
    z = serial + 719468
    era = int(z / 146097)
    dayOfEra = z - (era * 146097)
    yearOfEra = int((dayOfEra - int(dayOfEra / 1460) + int(dayOfEra / 36524) - int(dayOfEra / 146096)) / 365)
    year = yearOfEra + (era * 400)
    dayOfYear = dayOfEra - ((365 * yearOfEra) + int(yearOfEra / 4) - int(yearOfEra / 100))
    monthPrime = int(((5 * dayOfYear) + 2) / 153)
    day = dayOfYear - int(((153 * monthPrime) + 2) / 5) + 1
    month = monthPrime + 3
    if month > 12 then month = month - 12
    if month <= 2 then year = year + 1

    return pad2(year, 4) + "-" + pad2(month, 2) + "-" + pad2(day, 2)
end function

'-------------------------------------------------------------------------------
' getDayLabel
'-------------------------------------------------------------------------------
function getDayLabel(serial as integer) as string
    labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    index = (serial + 4) mod 7
    if index < 0 then index = index + 7

    return labels[index]
end function

'-------------------------------------------------------------------------------
' pad2
'-------------------------------------------------------------------------------
function pad2(value as integer, width as integer) as string
    text = value.ToStr()
    while Len(text) < width
        text = "0" + text
    end while

    return text
end function

'-------------------------------------------------------------------------------
' clearLayer
'-------------------------------------------------------------------------------
sub clearLayer(layer as dynamic)
    if layer = invalid then return

    childCount = layer.getChildCount()
    if childCount > 0 then layer.removeChildrenIndex(childCount, 0)
end sub
