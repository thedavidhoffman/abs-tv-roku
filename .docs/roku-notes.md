# Roku Notes

## Links

- https://developer.roku.com/docs/references

## Controls

### BusySpinner
https://developer.roku.com/docs/references/scenegraph/widget-nodes/busyspinner.md

### MarkupList
https://developer.roku.com/docs/references/scenegraph/list-and-grid-nodes/markuplist.md

### Scrolling label
https://developer.roku.com/docs/references/scenegraph/typographic-nodes/scrollinglabel.md

### Scrollable text
https://developer.roku.com/docs/references/scenegraph/typographic-nodes/scrollabletext.md


## Remote key events

- https://developer.roku.com/docs/developer-program/core-concepts/handling-application-events.md#handling-remote-control-key-presses

## Font sizes
- font:SmallestSystemFont
- font:SmallSystemFont
- font:MediumSystemFont
- font:LargeSystemFont
- font:SmallBoldSystemFont
- font:MediumBoldSystemFont
- font:LargeBoldSystemFont

Example
```
font="font:LargeBoldSystemFont"
```

## Type inspection debug statement
```? "bg type="; type(m.bg); " subtype="; m.bg.subtype()```

## colors
When assigning color in BrightScript do not assign string values, assign integer values.
```
m.backdrop.color = &h000000FF
```

# Newline
Chr(10)