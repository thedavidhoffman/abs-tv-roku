# Roku Components

A Roku SceneGraph component is usually split across two files:

```text
ComponentName.xml
ComponentName.brs
```

The XML file declares the component: its name, base type, public interface,
scripts, and child nodes.

The BrightScript file implements the component behavior: initialization, event
handlers, focus movement, field observers, and helper functions.

## XML And BrightScript Relationship

The XML file connects to BrightScript through `<script>` tags:

```xml
<component name="Header" extends="Group">
  <script type="text/brightscript" uri="pkg:/components/pages/Header/Header.brs" />
</component>
```

When Roku creates a `Header` node, it loads the script file and calls its
`init()` function if one exists.

Inside that BrightScript file:

```brightscript
m.top
```

is the `Header` node declared by the XML component.

That means BrightScript can read and write interface fields:

```brightscript
m.top.username = "David"
m.top.backSelected = m.backSelectedCounter
```

It can also find children declared in the XML:

```brightscript
m.settingsButton = m.top.findNode("settingsButton")
```

The XML describes the component's shape. The `.brs` file gives that shape
behavior.

## Component Tag

Every component starts with a `<component>` tag:

```xml
<component name="Player" extends="Group" focusable="true">
```

Important attributes:

- `name`: The component type name used by XML or `CreateObject("roSGNode", ...)`
- `extends`: The base SceneGraph node type or component this component builds on
- `focusable`: Whether the component itself can receive focus

Examples:

```xml
<Player id="player" />
```

```brightscript
dialog = CreateObject("roSGNode", "SettingsDialog")
```

## Script Section

The `<script>` section loads BrightScript files used by the component.

```xml
<script type="text/brightscript" uri="pkg:/source/Color.brs" />
<script type="text/brightscript" uri="pkg:/components/pages/Header/Header.brs" />
```

Shared helper files usually come first. The component's own `.brs` file usually
comes last.

Functions from included scripts are available to the component script.

## Interface Section

The `<interface>` section defines the public contract of the component.

```xml
<interface>
  <field id="username" type="string" onChange="onUsernameChanged" />
  <field id="backSelected" type="integer" />
  <function name="focusHeader" />
</interface>
```

Fields are used to pass data and events across component boundaries.

Common field patterns:

- Data input: `server`, `token`, `libraryItems`
- State output: `playSelected`, `closeRequested`, `errorResponse`
- Event counters: `backSelected`, `settingsSaved`, `overlayRequested`

The optional `onChange` attribute calls a BrightScript function when that field
changes:

```xml
<field id="libraryItems" type="array" onChange="onLibraryItemsChanged" />
```

Functions expose callable behavior to parent components:

```xml
<function name="focusLibraryList" />
```

The parent can call it with:

```brightscript
m.library.callFunc("focusLibraryList")
```

## Function Nodes

An XML `<function>` entry declares a BrightScript function that other components
can call.

It belongs inside the `<interface>` section:

```xml
<interface>
  <function name="openDialog" />
  <function name="closeDialog" />
  <function name="focusLibraryList" />
</interface>
```

The named function must exist in one of the component's loaded BrightScript
files:

```brightscript
sub openDialog()
    m.top.visible = true
    m.top.setFocus(true)
end sub
```

A parent component calls it with `callFunc`:

```brightscript
m.dialog.callFunc("openDialog")
```

If the function accepts one argument, pass it as the second `callFunc` value:

```brightscript
m.gridView.callFunc("focusItemAtIndex", 12)
```

The matching BrightScript function might look like this:

```brightscript
sub focusItemAtIndex(index as dynamic)
    m.markupGrid.jumpToItem = index
    m.markupGrid.setFocus(true)
end sub
```

Use XML functions for imperative commands:

- Open or close a dialog
- Move focus
- Reset component state
- Jump to a specific item
- Start a component-owned action

Use fields for data, state, and events:

```xml
<field id="libraryItems" type="array" onChange="onLibraryItemsChanged" />
<field id="playSelected" type="assocarray" />
```

A good rule:

```text
field    = "here is data" or "an event happened"
function = "do this now"
```

For example, this is a field/event:

```brightscript
m.top.playSelected = {
    id: item.id
    title: item.title
}
```

And this is a command:

```brightscript
m.player.callFunc("focusTransport")
```

## Children Section

The `<children>` section declares the component's child nodes.

```xml
<children>
  <Rectangle id="bg" width="1920" height="1080" />
  <HeaderButton id="settingsButton" text="Settings" />
</children>
```

Children can be built-in SceneGraph nodes, like `Rectangle`, `Label`, `Poster`,
or app components, like `HeaderButton`, `Library`, and `Player`.

The `id` attribute lets BrightScript find the child:

```brightscript
m.settingsButton = m.top.findNode("settingsButton")
```

Child attributes set initial field values:

```xml
<Label id="titleLabel" width="800" numLines="2" />
```

Those fields can later be changed in BrightScript:

```brightscript
m.titleLabel.text = "Now Playing"
```

## Field Types

Interface fields need a Roku type:

```xml
<field id="visible" type="boolean" />
<field id="title" type="string" />
<field id="items" type="array" />
<field id="request" type="assocarray" />
<field id="selectedIndex" type="integer" />
```

Use `assocarray` when passing a structured request or event payload:

```brightscript
m.top.overlayRequested = {
    id: "settings"
    componentName: "SettingsDialog"
    closeField: "closeRequested"
}
```

## Common Pattern

A typical component pairs XML and BrightScript like this:

```xml
<component name="Example" extends="Group" focusable="true">
  <script type="text/brightscript" uri="pkg:/components/Example/Example.brs" />
  <interface>
    <field id="title" type="string" onChange="onTitleChanged" />
    <field id="selected" type="integer" />
    <function name="focusExample" />
  </interface>
  <children>
    <Label id="titleLabel" />
  </children>
</component>
```

```brightscript
sub init()
    m.titleLabel = m.top.findNode("titleLabel")
end sub

sub onTitleChanged()
    m.titleLabel.text = m.top.title
end sub

sub focusExample()
    m.top.setFocus(true)
end sub
```

The parent sets `m.example.title`. Roku calls `onTitleChanged()`. The component
updates its internal label. That is the normal XML-to-BrightScript loop.

## Rule Of Thumb

Use XML for:

- Component structure
- Public fields and functions
- Initial child node layout
- Static styles and dimensions

Use BrightScript for:

- Runtime behavior
- Focus movement
- Observing and reacting to field changes
- Building dynamic content
- Emitting events to parent components
