# Roku ContentNode as a Property Bag

A Roku `ContentNode` is often used like a property bag: a named bundle of values
that can be passed into SceneGraph controls and item renderers.

For example:

```brightscript
node = CreateObject("roSGNode", "ContentNode")
node.title = "Dune"
node.HDPosterUrl = "pkg:/images/dune.png"

node.AddFields({
    author: "Frank Herbert"
    progressPercent: 0.42
    isSeriesItem: false
})
```

A component can then read those values from its content field:

```brightscript
item = m.top.itemContent
title = item.title
author = item.author
coverUrl = item.HDPosterUrl
```

So for everyday app code, thinking of a `ContentNode` as a property bag is a
useful mental model.

The Roku-specific nuance is that a `ContentNode` is not just a plain associative
array. It is still a SceneGraph node. That means it can:

- Use built-in fields like `title`, `HDPosterUrl`, and `SDPosterUrl`
- Receive custom fields through `AddFields`
- Be observed with `observeField`
- Be assigned as `content` for controls like `RowList`, `MarkupGrid`, and `LabelList`
- Contain child `ContentNode` nodes for rows, grids, and nested content

In short: a `ContentNode` is a property bag plus SceneGraph behavior.

This is why the app can build a `ContentNode` in a parent view, attach item data
such as title, author, poster URL, progress, and focus state, then pass that node
to a reusable renderer like `ItemPoster`.
