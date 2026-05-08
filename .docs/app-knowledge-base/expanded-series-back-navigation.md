# Expanded Series Back Navigation

Library series navigation has two different paths depending on the active
library view.

## List View

`ListView` expands collapsed series inline inside its `MarkupList`. It does not
replace `libraryItems`, and it does not use the library drilldown back stack.

Series expansion state is local to
`components/pages/Library/ListView/ListView.brs`:

```brightscript
m.expandedSeriesIds = {}
m.seriesItemsById = {}
m.loadingSeriesId = invalid
```

When the focused row is selected, `toggleSeriesAtCurrentIndex()` calls
`toggleSeriesAtIndex()`. If the row is a series:

- expanded series are collapsed by removing the series id from
  `m.expandedSeriesIds`
- cached series items are expanded immediately
- uncached series items are loaded by the local `seriesApiTask`

The series load request stays inside `ListView`:

```brightscript
m.seriesApiTask.request = {
    action: "loadSeries"
    server: m.server
    token: m.token
    bookLibraryId: m.bookLibraryId
    seriesId: seriesId
    sourceItemIndex: sourceIndex
}
```

When the response returns, `onSeriesApiResponse()` stores the children in
`m.seriesItemsById`, marks the series expanded, and rebuilds the MarkupList at
the original row index.

```brightscript
m.seriesItemsById[seriesIdText] = getResponseLibraryItems(response)
setSeriesExpanded(response.seriesId, true)
rebuildLibraryList(sourceIndex)
```

`rebuildLibraryList()` renders each root item, then inserts child rows directly
after any expanded series header:

```brightscript
appendLibraryRow(root, createLibraryRow(item, false, invalid))

seriesId = getCollapsedSeriesId(item)
if isSeriesExpanded(seriesId) then
    appendExpandedSeriesRows(root, seriesId, item)
end if
```

## List View Back Button

`ListView.onKeyEvent()` handles Back locally before allowing parent navigation:

```brightscript
if key = "back" then
    if isOverviewFocused() then
        return focusSelectedLibraryItem()
    end if

    if collapseCurrentSeries() then return true
    if focusFirstLibraryItem() then return true
    if requestHeaderFocusFromFirstItem() then return true
end if
```

The Back behavior is:

1. If the overview has focus, Back returns focus to the currently selected list
   row.
2. If the list has focus and the current row belongs to an expanded series,
   `collapseCurrentSeries()` collapses that series and focuses the series header.
3. If focus is below the first row, Back jumps to the first list row.
4. If focus is already on the first row, `ListView` emits
   `upFromFirstItemSelected`, which the parent uses to move focus toward the
   header.

`collapseCurrentSeries()` works from either the series header or one of its child
rows. It walks upward from the current row until it finds the matching series
header, collapses the series, then rebuilds the list with focus on that header.

## Grid View

`GridView` still uses a drilldown model for collapsed series. Selecting a series
tile emits `seriesSelected` instead of `playSelected`:

```brightscript
m.top.seriesSelected = {
    seriesId: seriesId
    title: getLibraryItemTitle(item)
    itemIndex: m.markupGrid.itemSelected
    counter: m.seriesSelectedCounter
}
```

`Library` observes `gridView.seriesSelected` in `onGridViewSeriesSelected()` and
runs its `libraryApiTask` with `action: "loadSeries"`.

## Grid View Back Stack

The grid drilldown back stack is owned by
`components/pages/Library/Library.brs`, not `MainScene`:

```brightscript
m.itemBackStack = []
```

Full library loads clear the stack in `storeRootItems()`.

Series loads push the current item list and selected grid index before replacing
the library items:

```brightscript
m.itemBackStack.Push({
    items: m.top.libraryItems
    focusIndex: response.sourceItemIndex
})
m.top.libraryItems = getResponseLibraryItems(response)
```

## Grid View Back Button Restore

`MainScene.onKeyEvent()` delegates Back to `Library.handleBackNavigation()` when
the user is authenticated and not in the player.

For grid drilldown, `Library.handleBackNavigation()` first tries to move focus to
the first grid item. If the grid is already at the first item, it restores the
previous library item list:

```brightscript
m.top.libraryItems = previousState.items
focusItemAtIndex(previousState.focusIndex)
```

`Library.focusItemAtIndex()` forwards to `GridView.focusItemAtIndex()` when the
active view is grid. `GridView` clamps the index, sets `jumpToItem`, and focuses
the `MarkupGrid`.

The result is that Back from a grid series drilldown returns to the previous
grid item list with focus restored to the series tile that opened it.
