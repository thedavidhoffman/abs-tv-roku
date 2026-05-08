# ABSTV

This is a Roku app that connects to an [Audiobookshelf](https://www.audiobookshelf.org/) server to play audiobooks on a Roku device, bringing your audiobook library to your television. As far as I'm aware, this is the only Roku app for ABS. *This project is not affiliated with Audiobookshelf.*

NOTE: this app currently does not support: podcasts, collections, or playlists.

## Sideloading on Roku

This app is not availabe in the official Roku channel store. It must be side-loaded onto a Roku device. I'm assuming that most people that run the ABS docker image have some technical ability, so they should be able to side-load this app. Once this app gets to a point that it has several releases under it's belt and it has reached some point of maturity, I may look to get it in the official Roku channel store.

To install this app on a Roku device, first enable Developer Mode on the Roku:

1. On the Roku remote, press `Home` three times, `Up` two times, then `Right`, `Left`, `Right`, `Left`, `Right`.
2. Follow the on-screen prompts to enable the Developer Application Installer.
3. Set and save the developer web server password.
4. Restart the Roku device when prompted.

After the Roku device restarts, upload the ABSTV app:

1. Find the Roku IP address under `Settings > Network > About`.
2. Download the ABSTV app zip file from the latest GitHub release.
3. In a browser, open `http://ROKU_IP_ADDRESS`.
4. Sign in with username `rokudev` and the developer password you set.
5. Use the upload form to select `abs-tv-roku.zip`, then click `Install`.

After installation, ABSTV will be available from the Roku home screen.

## AI Usage Disclaimer

This app was built with the help of Codex. It wasn't simply "vibe coded." As a senior software engineer, I used AI as a tool to help accelerate development, but the process was highly hands-on. The commit history in this repository shows my active role in guiding and refining the output. I spent a significant amount of time refactoring the AI generated code, making design decisions, and shaping the project to meet a specific standard (as much as you can within the constraints of Roku's BrightScript ecosystem).

## Wishlist

Things I hope to add support to this app for in the future.

- search
- easy switching between multiple logins
- localization
- themes
- usage stat page
- collections
- playlists
- podcasts
