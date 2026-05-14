# ABSTV

This is a Roku app that connects to an [Audiobookshelf](https://www.audiobookshelf.org/) server to play audiobooks on a Roku device, bringing your audiobook library to your television. As far as I'm aware, this is the only Roku app for ABS. _This project is not affiliated with Audiobookshelf._

NOTE: this app currently does not support: podcasts, collections, or playlists.

## Table of Contents

- [Privacy Policy](#privacy-policy)
- [Safety & Responsibility](#safety--responsibility)
- [Sideloading on Roku](#sideloading-on-roku)
- [AI Usage Disclaimer](#ai-usage-disclaimer)
- [Wishlist](#wishlist)

## Privacy Policy

Your privacy is a core design principle of this application.

This app **does not collect, harvest, or track any user data or telemetry in any form**. It operates locally and only communicates with your Audiobookshelf server as required for normal playback functionality.

The app also **does not modify, manage, or alter your Audiobookshelf library** in any way. It does not create, delete, or edit your media or metadata.

The **only data transmitted** by this app is your playback progress (such as position within an audiobook), which is sent directly to your Audiobookshelf server. This ensures your listening progress stays synchronized across devices.

### What This Means for You

- No analytics or tracking services are used.
- No personal data is collected.
- The only information stored by the app on your Roku device are:
    - Your username, user id, and authentication token required to communicate with the ABS server.
    - The application settings.
- No data is shared with third parties.
- All interactions are limited strictly to essential playback functionality.

### Important Note

While this app is intentionally designed to be minimal and privacy-respecting, no software can guarantee absolute security in every environment. You are responsible for reviewing your server configuration, network security, and usage practices to ensure they meet your privacy expectations.

If you have concerns, you are encouraged to inspect the source code (if available) or monitor network activity to verify the app’s behavior.

## Safety & Responsibility

This application is built with safety in mind. The goal is to be transparent, predictable, and minimal in what it touches—doing only what it needs to do to function and nothing more. That said, **no software can be guaranteed to be perfectly safe or error‑free in every environment**. Bugs happen, dependencies change, operating systems behave differently, and unexpected interactions can occur.

By installing or using this app, **you acknowledge and accept that you are using it at your own risk**. You are solely responsible for verifying that it is suitable for your device, your data, and your use case. You are also responsible for maintaining appropriate backups and safeguards for anything you care about.

### No Warranty

This software is provided **“as is”**, without warranty of any kind—express or implied—including but not limited to warranties of merchantability, fitness for a particular purpose, and non‑infringement.

### Limitation of Liability

To the maximum extent permitted by law, the authors and contributors will not be liable for any claim, damages, or other liability arising from, out of, or in connection with the software or its use, including (without limitation) loss of data, loss of profits, business interruption, device failure, or any other direct or indirect damages.

If you do not agree with these terms, do not install or use the app.

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

This app was built with the help of Codex. It wasn't simply "vibe coded." As a senior software engineer, I used AI as a tool to help accelerate development, but the process was highly hands-on. The commit history in this repository shows my active role in guiding and refining the output. I spent a significant amount of time refactoring the AI generated code, making design decisions, and shaping the project to meet a specific standard (as much as you can within the constraints of Roku's BrightScript ecosystem).

## Wishlist

Things I hope to add support to this app for in the future.

- switching between multiple logins
- localization
- themes
- usage stat page
- collections
- playlists
- custom screensaver(s)
