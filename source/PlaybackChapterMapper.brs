'-------------------------------------------------------------------------------
' PlaybackChapterMapper_MapSessionChapters
'-------------------------------------------------------------------------------
function PlaybackChapterMapper_MapSessionChapters(session as dynamic) as object
    chapters = []
    if session = invalid or session.chapters = invalid or session.chapters.Count() = 0 then return chapters

    for i = 0 to session.chapters.Count() - 1
        chapter = session.chapters[i]
        if chapter <> invalid then
            startTime = __GetSessionChapterStart(chapter)
            endTime = __GetSessionChapterEnd(chapter, session, i)
            duration = endTime - startTime
            if duration < 0 then duration = 0
            chapters.Push({
                index: i
                title: __GetSessionChapterTitle(chapter, i)
                startOffset: startTime
                durationSeconds: duration
                isChapter: true
            })
        end if
    end for

    return chapters
end function

'-------------------------------------------------------------------------------
' PlaybackChapterMapper_ShouldUseTracks
'-------------------------------------------------------------------------------
function PlaybackChapterMapper_ShouldUseTracks(chapters as dynamic, tracks as dynamic, session as dynamic) as boolean
    if chapters = invalid or tracks = invalid then return false
    if chapters.Count() = 0 or tracks.Count() = 0 then return false
    if chapters.Count() >= tracks.Count() then return false

    chapterCoverage = __GetChapterCoverageSeconds(chapters)
    mediaDuration = __GetMediaDurationSeconds(session, tracks)
    if mediaDuration <= 0 then return false

    return chapterCoverage < (mediaDuration * 0.9)
end function

'-------------------------------------------------------------------------------
' PlaybackChapterMapper_MapTracks
'-------------------------------------------------------------------------------
function PlaybackChapterMapper_MapTracks(tracks as dynamic) as object
    chapters = []
    if tracks = invalid then return chapters

    for i = 0 to tracks.Count() - 1
        track = tracks[i]
        if track <> invalid then
            chapters.Push({
                index: i
                title: SafeString(track.title, "Track " + (i + 1).ToStr())
                startOffset: Number_ToFloat(track.startOffset)
                durationSeconds: Number_ToFloat(track.durationSeconds)
                isChapter: true
                source: "track"
            })
        end if
    end for

    return chapters
end function

'-------------------------------------------------------------------------------
' __GetSessionChapterStart
'-------------------------------------------------------------------------------
function __GetSessionChapterStart(chapter as dynamic) as float
    if chapter.start <> invalid then return Number_ToFloat(chapter.start)
    if chapter.startTime <> invalid then return Number_ToFloat(chapter.startTime)
    if chapter.startOffset <> invalid then return Number_ToFloat(chapter.startOffset)
    return 0
end function

'-------------------------------------------------------------------------------
' __GetSessionChapterEnd
'-------------------------------------------------------------------------------
function __GetSessionChapterEnd(chapter as dynamic, session as dynamic, index as integer) as float
    if chapter.end <> invalid then return Number_ToFloat(chapter.end)
    if chapter.endTime <> invalid then return Number_ToFloat(chapter.endTime)
    if chapter.duration <> invalid then return __GetSessionChapterStart(chapter) + Number_ToFloat(chapter.duration)
    if session <> invalid and session.chapters <> invalid and index + 1 < session.chapters.Count() then return __GetSessionChapterStart(session.chapters[index + 1])
    if session <> invalid and session.duration <> invalid then return Number_ToFloat(session.duration)
    return __GetSessionChapterStart(chapter)
end function

'-------------------------------------------------------------------------------
' __GetSessionChapterTitle
'-------------------------------------------------------------------------------
function __GetSessionChapterTitle(chapter as dynamic, index as integer) as string
    return FirstNonEmpty([chapter.title, chapter.name], "Chapter " + (index + 1).ToStr())
end function

'-------------------------------------------------------------------------------
' __GetChapterCoverageSeconds
'-------------------------------------------------------------------------------
function __GetChapterCoverageSeconds(chapters as dynamic) as float
    if chapters = invalid or chapters.Count() = 0 then return 0

    lastChapter = chapters[chapters.Count() - 1]
    if lastChapter = invalid then return 0

    return Number_ToFloat(lastChapter.startOffset) + Number_ToFloat(lastChapter.durationSeconds)
end function

'-------------------------------------------------------------------------------
' __GetMediaDurationSeconds
'-------------------------------------------------------------------------------
function __GetMediaDurationSeconds(session as dynamic, tracks as dynamic) as float
    if session <> invalid and session.duration <> invalid then return Number_ToFloat(session.duration)
    if tracks = invalid then return 0

    duration = 0.0
    for each track in tracks
        if track <> invalid then duration = duration + Number_ToFloat(track.durationSeconds)
    end for

    return duration
end function
