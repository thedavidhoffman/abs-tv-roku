[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/thedavidhoffman)

# ABSTV

This is a Roku app that connects to an [Audiobookshelf](https://www.audiobookshelf.org/) server to play audiobooks on a Roku device, bringing your audiobook library to your television. As far as I'm aware, this is the only Roku app for ABS. _This project is not affiliated with Audiobookshelf._

NOTE: this app currently does not support: podcasts, collections, or playlists.

## Table of Contents

- [Sideloading on Roku](#sideloading-on-roku)
- [AI Usage Disclaimer](#ai-usage-disclaimer)
- [Requirements](#requirements)
- [Wishlist](#wishlist)
- [The Mumbo Jumbo](#the-mumbo-jumbo)
  - [Privacy Policy](#privacy-policy)
  - [Safety & Responsibility](#safety--responsibility)
  - [No Warranty](#no-warranty)
  - [Limitation of Liability](#limitation-of-liability)

## Sideloading on Roku

This app is not availabe in the official Roku channel store. It must be side-loaded onto a Roku device. I'm assuming that most people that run the ABS docker image have some technical ability, so they should be able to side-load this app.

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

This app was built with Codex, but it was not simply “vibe coded.” As a senior software engineer, I used AI to accelerate development while staying deeply involved in the implementation. The commit history on this repository reflects an active, hands-on process of guiding the work, refining generated code, making design decisions, and shaping the project toward a deliberate standard within the constraints of Roku’s BrightScript ecosystem.

## Requirements

- An [audiobookshelf](https://www.audiobookshelf.org/) server (self-hosted)
- A Roku device

## Wishlist

Things I hope to add support to this app for in the future.

- switching between multiple logins
- localization (Sweden, Norway, Finland, France, Germany, China, India)
- themes
- usage stat page
- collections
- playlists
- custom screensaver(s)

## The Mumbo Jumbo

### Privacy Policy

- No analytics or tracking services are used.
- No personal data is collected.
- The only information stored by this app on your Roku device are:
    - Your username, user id, and authentication token required to communicate with the ABS server.
    - Application settings.
- No data is shared with third parties.


### Safety & Responsibility

By installing or using this app, **you acknowledge and accept that you are using it at your own risk**. You are solely responsible for verifying that it is suitable for your device, your data, and your use case. You are also responsible for maintaining appropriate backups and safeguards for anything you care about.

### No Warranty

This software is provided **“as is”**, without warranty of any kind, express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, and non‑infringement.

### Limitation of Liability

To the maximum extent permitted by law, the authors and contributors will not be liable for any claim, damages, or other liability arising from, out of, or in connection with the software or its use, including (without limitation) loss of data, loss of profits, business interruption, device failure, or any other direct or indirect damages.

If you do not agree with these terms, do not install or use the app.
