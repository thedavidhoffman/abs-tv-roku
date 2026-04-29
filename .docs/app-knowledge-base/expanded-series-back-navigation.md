# Expanded Series Back Navigation

The grid view supports drilling into a collapsed series item and returning to
the original collapsed grid position with the Roku Back button.

## Forward Navigation

`GridView` handles MarkupGrid selection in
`components/pages/Library/GridView/GridView.brs`.

When the selected item has `collapsedSeries.id`, `onPosterSelected` emits
`seriesSelected` instead of `playSelected`.

```brightscript
m.top.seriesSelected = {
    seriesId: seriesId
    title: getLibraryItemTitle(item)
    itemIndex: m.markupGrid.itemSelected
    counter: m.seriesSelectedCounter
}
```

`Library` observes `gridView.seriesSelected` and forwards it through its own
`seriesSelected` field.

`MainScene` observes `m.library.seriesSelected` in `onLibrarySeriesSelected` and
starts the app task with:

```brightscript
m.apiTask.request = {
    action: "loadSeries"
    server: m.session.server
    token: m.session.token
    bookLibraryId: m.session.bookLibraryId
    seriesId: selectedSeries.seriesId
    sourceItemIndex: selectedSeries.itemIndex
}
```

`Series_Load` echoes `sourceItemIndex` in its response so the async result can be
matched back to the selected grid position.

## Back Stack

`MainScene` owns the back stack:

```brightscript
m.libraryItemBackStack = []
```

Full library loads clear the stack in `storeLibraryItems`.

Series loads push the current list and selected grid index before replacing the
library items:

```brightscript
m.libraryItemBackStack.Push({
    items: m.library.libraryItems
    focusIndex: response.sourceItemIndex
})
m.library.libraryItems = response.libraryItems
```

## Back Button Restore

`MainScene.onKeyEvent` checks `restorePreviousLibraryItems()` before falling back
to the normal header-focus behavior.

`restorePreviousLibraryItems()` pops the previous state, restores the item list,
and asks `Library` to focus the saved index:

```brightscript
m.library.libraryItems = previousState.items
m.library.callFunc("focusItemAtIndex", previousState.focusIndex)
```

`Library.focusItemAtIndex` forwards the call to `GridView` when the active view
is grid.

`GridView.focusItemAtIndex` clamps the index, sets `jumpToItem`, and focuses the
MarkupGrid:

```brightscript
m.markupGrid.jumpToItem = itemIndex
m.markupGrid.setFocus(true)
```

The result is that Back from an expanded series returns to the full collapsed
series grid with focus restored to the series tile that opened it.
