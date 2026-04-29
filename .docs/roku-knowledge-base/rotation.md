# Roku - Rotation

SceneGraph nodes can be rotated with the `rotation` field.

`rotation` is measured in radians, not degrees.

```xml
<Poster
  id="cover"
  width="280"
  height="280"
  rotation="0.785398" />
```

The same field can be set from BrightScript:

```brightscript
m.cover.rotation = 1.5708
```

Common degree-to-radian values:

| Degrees | Radians |
| --- | --- |
| 45 | `0.785398` |
| 90 | `1.5708` |
| 180 | `3.14159` |
| 270 | `4.71239` |

Use `rotationCenter` to rotate around a specific point in the node's local
coordinate space. For a `280x280` node, the center is `[140,140]`.

```xml
<Poster
  id="cover"
  width="280"
  height="280"
  rotationCenter="[140,140]"
  rotation="1.5708" />
```

