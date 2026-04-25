'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.cover = m.top.findNode("cover")
    m.titleLabel = m.top.findNode("titleLabel")
    m.authorLabel = m.top.findNode("authorLabel")
    m.narratorLabel = m.top.findNode("narratorLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.publisherLabel = m.top.findNode("publisherLabel")
    m.publishDateLabel = m.top.findNode("publishDateLabel")
    m.durationLabel = m.top.findNode("durationLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.audioPlayer = m.top.findNode("audioPlayer")
    m.playbackApiTask = m.top.findNode("playbackApiTask")
    m.closeRequestedCounter = 0
    m.tracks = []
    m.currentTrackIndex = 0

    m.playbackApiTask.observeField("response", "onPlaybackApiResponse")
    if m.audioPlayer <> invalid then m.audioPlayer.observeField("state", "onAudioStateChanged")
end sub

'-------------------------------------------------------------------------------
' onPlayRequestChanged
'-------------------------------------------------------------------------------
sub onPlayRequestChanged()
    request = m.top.playRequest
    if request = invalid then return

    if m.cover <> invalid then m.cover.uri = SafeString(request.coverUrl, "pkg:/images/placeholder_cover.png")
    if m.titleLabel <> invalid then m.titleLabel.text = SafeString(request.title, "Audiobook")
    updateDetails(request.details)
    setStatus("Starting playback...")

    m.playbackApiTask.request = {
        action: "startPlayback"
        server: request.server
        token: request.token
        itemId: request.itemId
        title: request.title
    }
    m.playbackApiTask.control = "run"
end sub

'-------------------------------------------------------------------------------
' onPlaybackApiResponse
'-------------------------------------------------------------------------------
sub onPlaybackApiResponse()
    response = m.playbackApiTask.response
    if response = invalid then return

    if response.ok <> true then
        m.top.errorResponse = response
        setStatus(SafeString(response.errorMessage, "Unable to start playback."))
        return
    end if

    playTracks(response.tracks)
end sub

'-------------------------------------------------------------------------------
' updateDetails
'-------------------------------------------------------------------------------
sub updateDetails(details as dynamic)
    if details = invalid then details = {}

    setLabelText(m.authorLabel, getSingularPluralText("Author", details.authorCount) + ": " + FirstNonEmpty([details.authors], "Unknown"))
    setLabelText(m.narratorLabel, getSingularPluralText("Narrator", details.narratorCount) + ": " + FirstNonEmpty([details.narrators], "Unknown"))
    setLabelText(m.descriptionLabel, FirstNonEmpty([details.description], "No description available."))
    setLabelText(m.publisherLabel, "Publisher: " + FirstNonEmpty([details.publisher], "Unknown"))
    setLabelText(m.publishDateLabel, "Published: " + FirstNonEmpty([details.publishDate], "Unknown"))
    setLabelText(m.durationLabel, "Duration: " + FirstNonEmpty([details.duration], "Unknown"))
end sub

'-------------------------------------------------------------------------------
' getSingularPluralText
'-------------------------------------------------------------------------------
function getSingularPluralText(singularLabel as string, count as dynamic) as string
    if count <> invalid and int(val(count.ToStr())) > 1 then return singularLabel + "s"
    return singularLabel
end function

'-------------------------------------------------------------------------------
' setLabelText
'-------------------------------------------------------------------------------
sub setLabelText(label as dynamic, text as string)
    if label <> invalid then label.text = text
end sub

'-------------------------------------------------------------------------------
' playTracks
'-------------------------------------------------------------------------------
sub playTracks(tracks as dynamic)
    if m.audioPlayer = invalid then return
    if tracks = invalid or tracks.Count() = 0 then
        setStatus("No playable audio tracks were returned.")
        return
    end if

    m.tracks = tracks
    m.currentTrackIndex = 0
    playCurrentTrack()
end sub

'-------------------------------------------------------------------------------
' playCurrentTrack
'-------------------------------------------------------------------------------
sub playCurrentTrack()
    if m.audioPlayer = invalid then return
    if m.tracks = invalid or m.currentTrackIndex < 0 or m.currentTrackIndex >= m.tracks.Count() then return

    track = m.tracks[m.currentTrackIndex]
    node = CreateObject("roSGNode", "ContentNode")
    node.url = track.url
    node.title = SafeString(track.title, "Audiobook")
    node.streamFormat = getStreamFormat(track.mimeType, track.url)
    node.contentType = "audio"

    ? "player track"; " index="; m.currentTrackIndex; " format="; node.streamFormat; " url="; node.url

    m.audioPlayer.content = node
    m.audioPlayer.control = "play"
    setStatus("Playing")
end sub

'-------------------------------------------------------------------------------
' getStreamFormat
'-------------------------------------------------------------------------------
function getStreamFormat(mimeType as dynamic, url as dynamic) as string
    streamUrl = LCase(SafeString(url, ""))
    if Instr(1, streamUrl, ".m3u8") > 0 or Instr(1, streamUrl, "/hls/") > 0 then return "hls"

    mime = LCase(SafeString(mimeType, "audio/mpeg"))
    if Instr(1, mime, "mp4") > 0 or Instr(1, mime, "m4a") > 0 or Instr(1, mime, "m4b") > 0 then return "mp4"
    if Instr(1, mime, "aac") > 0 then return "aac"
    return "mp3"
end function

'-------------------------------------------------------------------------------
' onAudioStateChanged
'-------------------------------------------------------------------------------
sub onAudioStateChanged()
    if m.audioPlayer = invalid then return

    state = SafeString(m.audioPlayer.state, "")
    if state = "playing" then
        setStatus("Playing")
    else if state = "buffering" then
        setStatus("Buffering...")
    else if state = "finished" then
        if playNextTrack() then
            return
        end if
        setStatus("Finished")
    else if state = "error" then
        setStatus("Playback error.")
    end if
end sub

'-------------------------------------------------------------------------------
' playNextTrack
'-------------------------------------------------------------------------------
function playNextTrack() as boolean
    if m.tracks = invalid then return false
    nextIndex = m.currentTrackIndex + 1
    if nextIndex >= m.tracks.Count() then return false

    m.currentTrackIndex = nextIndex
    playCurrentTrack()
    return true
end function

'-------------------------------------------------------------------------------
' setStatus
'-------------------------------------------------------------------------------
sub setStatus(message as string)
    if m.statusLabel <> invalid then m.statusLabel.text = message
end sub

'-------------------------------------------------------------------------------
' closePlayer
'-------------------------------------------------------------------------------
sub closePlayer()
    if m.audioPlayer <> invalid then m.audioPlayer.control = "stop"
    m.closeRequestedCounter = m.closeRequestedCounter + 1
    m.top.closeRequested = m.closeRequestedCounter
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "back" then
        closePlayer()
        return true
    end if

    if key = "play" or key = "OK" or key = "select" then
        if m.audioPlayer <> invalid then
            if m.audioPlayer.state = "playing" then
                m.audioPlayer.control = "pause"
                setStatus("Paused")
            else
                m.audioPlayer.control = "resume"
                setStatus("Playing")
            end if
        end if
        return true
    end if

    return false
end function
