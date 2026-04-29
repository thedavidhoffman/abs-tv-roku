---
name: create-roku-rowlist
description: Build or modify Roku SceneGraph RowList components. Use when a task asks to create a RowList, add rows of poster/content items, wire RowList content nodes, create RowList item components, or follow Roku RowList examples in a BrightScript/Roku project.
---

# Create Roku RowList

Use this skill when implementing a Roku SceneGraph `RowList` or debugging a RowList data/rendering issue.

## References

Before implementing RowList behavior, review `references/rowlist-references.md` for the official Roku RowList node docs and the Roku sample project link.

## Workflow

1. Inspect existing list/grid components in the repo first, especially local `MarkupGrid`, `MarkupList`, or prior `RowList` patterns.
2. Create or update the page/component XML with a `RowList` node.
3. Create a row item component with at least these interface fields:
   - `itemContent` with `onChange` handler
   - `focusPercent` with `onChange` handler when focus styling is needed
   - `rowFocusPercent` with `onChange` handler when row dimming/row focus styling is needed
4. Build RowList content as nested `ContentNode`s:
   - root `ContentNode`
   - one child `ContentNode` per row, with `row.title` for row labels
   - one child `ContentNode` per item inside each row, with fields such as `title`, `HDPosterUrl`, and `SDPosterUrl`
5. Prefer `HDPosterUrl`/`SDPosterUrl` for poster-based rows; derive authenticated cover URLs from existing project helper patterns.
6. Keep the RowList page/component responsible for mapping API/app data into `ContentNode`s; keep row item components responsible only for rendering a single item.
7. Validate with the project's normal BrightScript validation command.

## Common XML Shape

```xml
<RowList
  id="rowList"
  translation="[64,144]"
  itemComponentName="MyRowItem"
  numRows="1"
  itemSize="[1792,300]"
  rowItemSize="[[200,300]]"
  itemSpacing="[0,36]"
  rowItemSpacing="[[28,0]]"
  showRowLabel="[true]"
  drawFocusFeedback="false"
  vertFocusAnimationStyle="fixedFocus"
  rowFocusAnimationStyle="fixedFocus" />
```

## Common Item Component Shape

```xml
<component name="MyRowItem" extends="Group">
  <interface>
    <field id="itemContent" type="node" onChange="onItemContentChanged" />
    <field id="focusPercent" type="float" onChange="onFocusPercentChanged" />
    <field id="rowFocusPercent" type="float" onChange="onRowFocusPercentChanged" />
  </interface>
</component>
```
