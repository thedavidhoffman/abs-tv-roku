'-------------------------------------------------------------------------------
' Cover_BuildUrl
'-------------------------------------------------------------------------------
function Cover_BuildUrl(server as dynamic, token as dynamic, itemId as dynamic, width as integer) as string

    log = CreateLogger("Cover_BuildUrl", false)

    placeholder = "pkg:/images/placeholder_cover.png"

    if server = invalid then
        log.write("server invalid, returning placeholder")
        log.flush()
        return placeholder
    end if

    if token = invalid then
        log.write("token invalid, returning placeholder")
        log.flush()
        return placeholder
    end if

    if itemId = invalid then
        log.write("itemId invalid, returning placeholder")
        log.flush()
        return placeholder
    end if

    if width < 1 then
        log.write("width < 1, defaulting to 280")
        width = 280
    end if

    url = server + "/api/items/" + itemId.ToStr() + "/cover?width=" + width.ToStr() + "&token=" + token

    log.write(server + "/api/items/" + itemId.ToStr() + "/cover?width=" + width.ToStr() + "&token=...")

    return url

end function
