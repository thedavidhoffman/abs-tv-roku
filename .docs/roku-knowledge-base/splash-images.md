# Roku Splash Images

Roku splash screen images are configured in the app `manifest`.

Standard full-screen splash image sizes:

- `splash_screen_fhd`: `1920x1080`
- `splash_screen_hd`: `1280x720`
- `splash_screen_sd`: `720x480`

For modern SceneGraph apps, a single FHD splash image is usually enough:

```text
splash_screen_fhd=pkg:/images/splash_fhd.jpg
```

Roku can scale the FHD image down for HD displays. Keep the design readable when
scaled from `1920x1080` to `1280x720`.

This app currently includes splash assets under `images/`:

```text
images/splash_fhd.jpg
images/splash_hd.jpg
images/splash_sd.jpg
```
