# Roku Fonts

Roku SceneGraph font reference:
https://developer.roku.com/docs/references/scenegraph/typographic-nodes/font.md

## Built-In Fonts

Built-in fonts are referenced with the `font:` prefix.

```xml
<Label
  text="Title"
  font="font:LargeBoldSystemFont" />
```

Available built-in system fonts:

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

## Setting Fonts

In XML, assign the font directly to a typographic node such as `Label`,
`ScrollingLabel`, or `ScrollableText`.

```xml
<Label
  id="seriesTitleLabel"
  width="280"
  height="240"
  font="font:TinySystemFont"
  horizAlign="center"
  vertAlign="center" />
```

From BrightScript, assign the font string to the node's `font` field.

```brightscript
m.titleLabel.font = "font:LargeSystemFont"
```

## Sizing Notes

Roku font names are relative size presets. They are not numeric point sizes.
Prefer the closest built-in size before introducing custom fonts.

Use bold variants for emphasis and focus states, not as a substitute for larger
text. Large font jumps can make TV layouts feel unstable.

For small overlay text, `TinySystemFont` and `TinyBoldSystemFont` are useful.
Give labels a fixed `width` and `height`, then use `horizAlign` and `vertAlign`
to center the text inside that box.

## Wrapping And Truncation

Roku `Label` text is clipped to the label's `width` and `height`. It will not
draw beyond the label boundaries; text that does not fit is truncated.

Use `maxLines` to control how many lines can be displayed before truncation.
Use `wrap="true"` when multi-line wrapping is desired.

```xml
<Label
  width="280"
  height="72"
  maxLines="3"
  wrap="true"
  font="font:TinySystemFont" />
```

For single-line labels, set `maxLines="1"`. If the text is wider than the label,
Roku truncates it inside the label bounds.

## Custom Fonts

Custom font files can be packaged with the app and referenced from `pkg:/`.
Use them sparingly; built-in fonts are usually safer for Roku performance,
readability, and consistency with platform UI.

When using custom fonts, test on device. Font metrics can affect line height,
vertical centering, truncation, and focus-state layout.
