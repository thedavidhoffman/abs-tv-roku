'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    initReferences()
    renderSummary()
end sub

'-------------------------------------------------------------------------------
' initReferences
'-------------------------------------------------------------------------------
sub initReferences()
    m.streakCard = m.top.findNode("streakCard")
    m.daysCard = m.top.findNode("daysCard")
    m.minutesCard = m.top.findNode("minutesCard")
end sub

'-------------------------------------------------------------------------------
' onStatsChanged
'-------------------------------------------------------------------------------
sub onStatsChanged()
    renderSummary()
end sub

'-------------------------------------------------------------------------------
' renderSummary
'-------------------------------------------------------------------------------
sub renderSummary()
    summary = buildOverallSummary(m.top.stats)
    m.streakCard.valueText = formatNumber(summary.daysInARow)
    m.daysCard.valueText = formatNumber(summary.daysListened)
    m.minutesCard.valueText = formatNumber(summary.totalMinutes)
end sub

'-------------------------------------------------------------------------------
' buildOverallSummary
'-------------------------------------------------------------------------------
function buildOverallSummary(stats as dynamic) as object
    days = invalid
    if stats <> invalid then days = stats.days

    dates = getSortedDateKeys(days)
    totalSeconds = getTotalSeconds(stats, days, dates)
    daysListened = 0

    for each dateText in dates
        if getSecondsForDate(days, dateText) > 0 then daysListened = daysListened + 1
    end for

    return {
        daysInARow: getDaysInARow(days, dates)
        daysListened: daysListened
        totalMinutes: int(totalSeconds / 60)
    }
end function

'-------------------------------------------------------------------------------
' getTotalSeconds
'-------------------------------------------------------------------------------
function getTotalSeconds(stats as dynamic, days as dynamic, dates as object) as integer
    if stats <> invalid and stats.totalTime <> invalid then return int(stats.totalTime)

    totalSeconds = 0
    for each dateText in dates
        totalSeconds = totalSeconds + getSecondsForDate(days, dateText)
    end for

    return totalSeconds
end function

'-------------------------------------------------------------------------------
' getDaysInARow
'-------------------------------------------------------------------------------
function getDaysInARow(days as dynamic, dates as object) as integer
    if dates.Count() = 0 then return 0

    latestListeningDate = ""
    for i = dates.Count() - 1 to 0 step -1
        if getSecondsForDate(days, dates[i]) > 0 then
            latestListeningDate = dates[i]
            exit for
        end if
    end for

    if latestListeningDate = "" then return 0

    streak = 0
    serial = dateToSerial(latestListeningDate)
    while getSecondsForDate(days, serialToDate(serial)) > 0
        streak = streak + 1
        serial = serial - 1
    end while

    return streak
end function

'-------------------------------------------------------------------------------
' getSecondsForDate
'-------------------------------------------------------------------------------
function getSecondsForDate(days as dynamic, dateText as string) as integer
    if days = invalid or days[dateText] = invalid then return 0

    return int(days[dateText])
end function

'-------------------------------------------------------------------------------
' formatNumber
'-------------------------------------------------------------------------------
function formatNumber(value as integer) as string
    text = value.ToStr()
    formatted = ""

    while Len(text) > 3
        formatted = "," + Right(text, 3) + formatted
        text = Left(text, Len(text) - 3)
    end while

    return text + formatted
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
' pad2
'-------------------------------------------------------------------------------
function pad2(value as integer, width as integer) as string
    text = value.ToStr()
    while Len(text) < width
        text = "0" + text
    end while

    return text
end function
