# Roku RowList References

Use these references when creating or modifying Roku SceneGraph RowList components:

- Official RowList node docs: https://developer.roku.com/docs/references/scenegraph/list-and-grid-nodes/rowlist.md
- Roku RowList sample project: https://github.com/rokudev/samples/tree/master/ux%20components/lists%20and%20grids/RowListExample

Notes from the sample:

- A `RowList` displays rows of horizontally scrollable items.
- `itemComponentName` points to the component used for each row item.
- RowList content is nested: root content node -> row content nodes -> item content nodes.
- Row labels come from row content node titles when `showRowLabel` is enabled.
- Item components commonly use `itemContent`, `focusPercent`, and `rowFocusPercent` fields.
- `focusPercent` is useful for scale or highlight effects on the focused item.
- `rowFocusPercent` is useful for opacity/dimming effects between focused and unfocused rows.
