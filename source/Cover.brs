'-------------------------------------------------------------------------------
' Cover_BuildUrl
'-------------------------------------------------------------------------------
function Cover_BuildUrl(server as dynamic, token as dynamic, itemId as dynamic, width as integer) as string

    log = CreateLogger("Cover_BuildUrl", false)

    placeholder = "pkg:/images/placeholder-cover.png"

    if server = invalid then
        log.error("server invalid, returning placeholder")
        return placeholder
    end if

    if token = invalid then
        log.error("token invalid, returning placeholder")
        return placeholder
    end if

    if itemId = invalid then
        log.error("itemId invalid, returning placeholder")
        return placeholder
    end if

    if width < 1 then
        log.write("width < 1, defaulting to 280")
        width = 280
    end if

    url = server + "/api/items/" + itemId.ToStr() + "/cover?width=" + width.ToStr() + "&token=" + token

    ' the next line gets real chatty in the log, uncomment if needed
    'log.write(server + "/api/items/" + itemId.ToStr() + "/cover?width=" + width.ToStr() + "&token=...")

    return url

end function
