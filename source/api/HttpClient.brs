'-------------------------------------------------------------------------------
' HttpClient_Request
'-------------------------------------------------------------------------------
function HttpClient_Request(url as String, method as String, token as Dynamic, body as Dynamic) as Object

    ? "request"; " method="; method; " url="; url

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")

    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.EnableEncodings(true)
    transfer.SetMessagePort(port)
    transfer.SetUrl(url)
    transfer.AddHeader("Accept", "application/json")

    if token <> invalid and token <> "" then
        transfer.AddHeader("Authorization", "Bearer " + token)
    end if

    responseText = ""
    status = 0
    if method = "POST" then
        transfer.AddHeader("Content-Type", "application/json")
        requestStarted = transfer.AsyncPostFromString(InvalidToEmpty(body))
    else
        requestStarted = transfer.AsyncGetToString()
    end if

    if requestStarted <> true then
        return { ok: false, status: 0, errorMessage: "Unable to start the request to the Audiobookshelf server." }
    end if

    msg = wait(30000, port)
    if msg = invalid then
        transfer.AsyncCancel()
        return { ok: false, status: 0, errorMessage: "The Audiobookshelf server request timed out." }
    end if

    if type(msg) <> "roUrlEvent" then
        return { ok: false, status: 0, errorMessage: "Unexpected response from the Audiobookshelf server." }
    end if

    status = msg.GetResponseCode()
    responseText = msg.GetString()
    ? "response"; " status="; status
    ? "response body="; responseText

    if status = 0 then
        return { ok: false, status: status, errorMessage: "Unable to reach the Audiobookshelf server." }
    end if

    if status = 401 and token <> invalid and token <> "" then
        return { ok: false, status: status, authExpired: true, errorMessage: "Your session has expired. Please sign in again." }
    end if

    data = invalid
    if responseText <> invalid and responseText <> "" then
        data = ParseJson(responseText)
    end if

    if status < 200 or status >= 300 then
        message = "Request failed."
        if data <> invalid then
            if data.error <> invalid then message = SafeString(data.error, message)
            if data.message <> invalid then message = SafeString(data.message, message)
        else if responseText <> invalid and TrimString(responseText) <> "" then
            message = TrimString(responseText)
        else if msg.GetFailureReason() <> invalid and TrimString(msg.GetFailureReason()) <> "" then
            message = TrimString(msg.GetFailureReason())
        end if
        return { ok: false, status: status, errorMessage: message }
    end if

    return { ok: true, status: status, data: data }
end function

'-------------------------------------------------------------------------------
' InvalidToEmpty
'-------------------------------------------------------------------------------
function InvalidToEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function
