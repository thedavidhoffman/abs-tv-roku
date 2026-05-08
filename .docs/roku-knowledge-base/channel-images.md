# Roku Channel Images

Roku channel images are configured in the app `manifest`.

This app currently declares:

```text
mm_icon_focus_hd=pkg:/images/icon_focus_hd.png
mm_icon_focus_sd=pkg:/images/icon_focus_sd.png
mm_icon_side_hd=pkg:/images/icon_side_hd.png
mm_icon_side_sd=pkg:/images/icon_side_sd.png
```

Commonly cited current focused channel poster sizes:

- `mm_icon_focus_fhd`: `540x405`
- `mm_icon_focus_hd`: `290x218`
- `mm_icon_focus_sd`: `214x144`

Older `mm_icon_side_*` entries are legacy smaller non-focused side images. Roku
documentation around these is less consistently surfaced for modern SceneGraph
apps, but keeping files with the same poster aspect ratio is safest when they
are included.

Current app files:

```text
images/icon_focus_hd.png
images/icon_focus_sd.png
images/icon_side_hd.png
images/icon_side_sd.png
```

For sideloading and fallback display, the focused icon is the most important
home-screen channel graphic. Published channels may use the artwork supplied
through the Roku developer portal instead of these packaged manifest images.
