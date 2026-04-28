'-------------------------------------------------------------------------------
' init
'-------------------------------------------------------------------------------
sub init()
    m.seriesOptions = m.top.findNode("seriesOptions")
    m.displayOptions = m.top.findNode("displayOptions")
    m.activeGroupIndex = 0
    m.top.observeField("focusedChild", "onFocusChanged")
    initSeriesOptions()
    initDisplayOptions()
    loadSettingsValues()
end sub

'-------------------------------------------------------------------------------
' initSeriesOptions
'-------------------------------------------------------------------------------
sub initSeriesOptions()
    if m.seriesOptions = invalid then return

    content = CreateObject("roSGNode", "ContentNode")
    collapseOption = content.createChild("ContentNode")
    collapseOption.title = "Collapse Series"
    expandOption = content.createChild("ContentNode")
    expandOption.title = "Expand Series"

    m.seriesOptions.content = content
end sub

'-------------------------------------------------------------------------------
' initDisplayOptions
'-------------------------------------------------------------------------------
sub initDisplayOptions()
    if m.displayOptions = invalid then return

    content = CreateObject("roSGNode", "ContentNode")
    listOption = content.createChild("ContentNode")
    listOption.title = "List"
    gridOption = content.createChild("ContentNode")
    gridOption.title = "Grid"

    m.displayOptions.content = content
end sub

'-------------------------------------------------------------------------------
' loadSettingsValues
'-------------------------------------------------------------------------------
sub loadSettingsValues()
    settings = SettingsStore_Load()
    if settings = invalid then return

    if m.seriesOptions <> invalid then
        if settings["series-display"] = "expand" then
            m.seriesOptions.checkedItem = 1
        else
            m.seriesOptions.checkedItem = 0
        end if
    end if

    if m.displayOptions <> invalid then
        if settings["item-display"] = "grid" then
            m.displayOptions.checkedItem = 1
        else
            m.displayOptions.checkedItem = 0
        end if
    end if
end sub

'-------------------------------------------------------------------------------
' onFocusChanged
'-------------------------------------------------------------------------------
sub onFocusChanged()
    if m.top.isInFocusChain() = false then return
    if isOptionsFocused(m.seriesOptions) or isOptionsFocused(m.displayOptions) then return

    focusActiveGroup()
end sub

'-------------------------------------------------------------------------------
' onKeyEvent
'-------------------------------------------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    if press = false then return false

    if key = "down" and isFocusedAtLastItem(m.seriesOptions) then
        if m.displayOptions <> invalid then
            m.activeGroupIndex = 1
            m.displayOptions.jumpToItem = 0
            m.displayOptions.setFocus(true)
            return true
        end if
    end if

    if key = "up" and isFocusedAtFirstItem(m.displayOptions) then
        if m.seriesOptions <> invalid then
            m.activeGroupIndex = 0
            m.seriesOptions.jumpToItem = getLastItemIndex(m.seriesOptions)
            m.seriesOptions.setFocus(true)
            return true
        end if
    end if

    return false
end function

'-------------------------------------------------------------------------------
' focusActiveGroup
'-------------------------------------------------------------------------------
sub focusActiveGroup()
    if m.activeGroupIndex = 1 and m.displayOptions <> invalid then
        m.displayOptions.setFocus(true)
    else if m.seriesOptions <> invalid then
        m.seriesOptions.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' focusFirstField
'-------------------------------------------------------------------------------
sub focusFirstField()
    m.activeGroupIndex = 0
    if m.seriesOptions <> invalid then
        m.seriesOptions.jumpToItem = 0
        m.seriesOptions.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' focusLastField
'-------------------------------------------------------------------------------
sub focusLastField()
    m.activeGroupIndex = 1
    if m.displayOptions <> invalid then
        m.displayOptions.jumpToItem = getLastItemIndex(m.displayOptions)
        m.displayOptions.setFocus(true)
    end if
end sub

'-------------------------------------------------------------------------------
' getSettingsValues
'-------------------------------------------------------------------------------
function getSettingsValues() as object
    if getCheckedItemIndex(m.seriesOptions) = 0 then
        seriesDisplay = "collapse"
    else
        seriesDisplay = "expand"
    end if

    if getCheckedItemIndex(m.displayOptions) = 0 then
        itemDisplay = "list"
    else
        itemDisplay = "grid"
    end if

    return {
        seriesDisplay: seriesDisplay
        itemDisplay: itemDisplay
    }
end function

'-------------------------------------------------------------------------------
' isOptionsFocused
'-------------------------------------------------------------------------------
function isOptionsFocused(list as dynamic) as boolean
    return list <> invalid and list.isInFocusChain()
end function

'-------------------------------------------------------------------------------
' isFocusedAtFirstItem
'-------------------------------------------------------------------------------
function isFocusedAtFirstItem(list as dynamic) as boolean
    return list <> invalid and list.isInFocusChain() and getFocusedItemIndex(list) <= 0
end function

'-------------------------------------------------------------------------------
' isFocusedAtLastItem
'-------------------------------------------------------------------------------
function isFocusedAtLastItem(list as dynamic) as boolean
    if list = invalid or list.isInFocusChain() = false then return false
    return getFocusedItemIndex(list) >= getLastItemIndex(list)
end function

'-------------------------------------------------------------------------------
' getFocusedItemIndex
'-------------------------------------------------------------------------------
function getFocusedItemIndex(list as dynamic) as integer
    focusedIndex = list.itemFocused
    if focusedIndex = invalid or focusedIndex < 0 then focusedIndex = 0
    return focusedIndex
end function

'-------------------------------------------------------------------------------
' getCheckedItemIndex
'-------------------------------------------------------------------------------
function getCheckedItemIndex(list as dynamic) as integer
    if list = invalid then return 0
    checkedIndex = list.checkedItem
    if checkedIndex = invalid or checkedIndex < 0 then return 0
    return checkedIndex
end function

'-------------------------------------------------------------------------------
' getLastItemIndex
'-------------------------------------------------------------------------------
function getLastItemIndex(list as dynamic) as integer
    if list = invalid or list.content = invalid then return 0

    lastIndex = list.content.getChildCount() - 1
    if lastIndex < 0 then return 0
    return lastIndex
end function
