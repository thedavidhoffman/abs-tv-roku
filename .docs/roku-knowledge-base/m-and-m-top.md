# Roku `m` And `m.top`

In Roku SceneGraph BrightScript, `m` and `m.top` are related, but they are not
the same thing.

The short version:

```text
m      = the script's private state object
m.top  = the SceneGraph node that owns the script
```

## What Is `m`?

`m` is an implicit associative array that Roku gives each script context.

Use `m` to store values that should be available across functions in the same
script file.

```brightscript
sub init()
    m.counter = 0
    m.username = "David"
end sub

sub incrementCounter()
    m.counter = m.counter + 1
end sub
```

Here, `m.counter` and `m.username` are script-level state. They are not XML
fields. They are not automatically visible to other components. They are just
values stored for this script instance.

In a component script like `MainScene.brs`, `m` is commonly used for:

```brightscript
m.homePage = m.top.findNode("homePage")
m.library = m.top.findNode("library")
m.session = AuthStore_Load()
m.playerReturnTarget = "home"
```

That lets other functions in the same file reuse those values without repeatedly
calling `findNode()` or passing everything around.

## What Is `m.top`?

`m.top` is the SceneGraph node that owns the current script.

If you are inside `MainScene.brs`, then:

```text
m.top = the MainScene node
```

If you are inside `HomePage.brs`, then:

```text
m.top = the HomePage node
```

If you are inside `Player.brs`, then:

```text
m.top = the Player node
```

So `m.top` changes depending on which component script you are in.

Given this component XML:

```xml
<component name="MainScene" extends="Scene">
  <children>
    <HomePage id="homePage" visible="false" />
    <Library id="library" />
  </children>
</component>
```

Inside `MainScene.brs`, this line:

```brightscript
m.homePage = m.top.findNode("homePage")
```

means:

"From the current `MainScene` node, find the child node with id `homePage`, and
store it in `m.homePage`."

## The Difference

Think of it like this:

```text
m      = my notebook for this script
m.top  = the actual SceneGraph component node
```

Use `m` to store your own state:

```brightscript
m.selectedIndex = 0
m.playerReturnTarget = "home"
m.libraryItems = []
```

Use `m.top` to interact with the component node itself:

```brightscript
m.top.visible = true
m.top.setFocus(true)
m.top.findNode("homePage")
m.top.observeField("focusedChild", "onFocusChanged")
```

## Concrete Example

Given this XML:

```xml
<component name="HomePage" extends="Group" focusable="true">
  <interface>
    <field id="server" type="string" />
  </interface>

  <children>
    <RowList id="homeRowList" />
  </children>
</component>
```

Inside `HomePage.brs`:

```brightscript
sub init()
    m.homeRowList = m.top.findNode("homeRowList")
    m.focusedItemNode = invalid
end sub
```

Here:

```brightscript
m.homeRowList
```

is a script variable you created.

```brightscript
m.focusedItemNode
```

is also a script variable you created.

```brightscript
m.top
```

is the `HomePage` component node.

```brightscript
m.top.findNode("homeRowList")
```

asks the `HomePage` node to find its child `RowList`.

```brightscript
m.top.server
```

accesses the `server` interface field declared in XML.

## Common Pattern

Most Roku components follow this pattern:

```brightscript
sub init()
    m.someChild = m.top.findNode("someChild")
    m.someState = invalid
end sub
```

Why store child nodes on `m`?

Because this:

```brightscript
m.homePage.visible = true
```

is cleaner than doing this every time:

```brightscript
m.top.findNode("homePage").visible = true
```

## Component Boundaries

`m` is not automatically shared between components.

In `MainScene.brs`:

```brightscript
m.top
```

is `MainScene`.

In `HomePage.brs`:

```brightscript
m.top
```

is `HomePage`.

Those scripts have different `m` objects.

So this in `MainScene.brs`:

```brightscript
m.session = AuthStore_Load()
```

does not mean `HomePage.brs` can automatically access `m.session`.

To send data to another component, set an interface field:

```brightscript
m.homePage.server = m.session.server
```

Then inside `HomePage.brs`, that value is available through:

```brightscript
m.top.server
```

## Rule Of Thumb

Use `m` when you mean:

```text
"Save this value for this script."
```

Use `m.top` when you mean:

```text
"Talk to the component node that owns this script."
```

A helpful mental model:

```brightscript
m.someValue = my private state
m.top.someField = this component's public/interface/node field
m.top.findNode("childId") = find a child declared in this component's XML
```
