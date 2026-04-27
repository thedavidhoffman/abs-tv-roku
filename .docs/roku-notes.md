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
https://developer.roku.com/docs/developer-program/core-concepts/handling-application-events.md#handling-remote-control-key-presses

## Font sizes
https://developer.roku.com/docs/references/scenegraph/typographic-nodes/font.md

- TinySystemFont
- TinyBoldSystemFont
- SmallerSystemFont
- SmallerBoldSystemFont
- SmallestSystemFont
- SmallestBoldSystemFont
- SmallSystemFont
- SmallBoldSystemFont
- MediumSystemFont
- MediumBoldSystemFont
- LargeSystemFont
- LargeBoldSystemFont
- LargestSystemFont
- ExtraLargeSystemFont
- ExtraLargeBoldSystemFont
- BadgeSystemFont

Example
```
font="font:LargeBoldSystemFont"
```

## Colors

Roku uses an 8-character hex color code that allows for specifying both the RGB color values and an alpha channel for transparency, with the last two characters representing the transparency level. This is similar to the rgba() function in CSS, where the alpha channel determines the opacity of the color.

Transparency Levels
The alpha channel values range from 00 to FF:
- 00: Fully transparent
- FF: Fully opaque

When assigning color in BrightScript do not assign string values, assign integer values.
```
m.backdrop.color = &h000000FF
```

## Newline
Chr(10)

## Type inspection debug statement
```? "bg type="; type(m.bg); " subtype="; m.bg.subtype()```