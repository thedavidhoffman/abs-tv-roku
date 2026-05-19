# Developer Commands

This project uses npm scripts for local build, package, deploy, and log-viewer
workflows.

## VS Code Extensions

Install the **RokuCommunity BrightScript Language** extension:

```
rokucommunity.brightscript
```

This extension is required for VS Code debug mode. The workspace debug config uses
`"type": "brightscript"`, which is provided by the RokuCommunity extension.

Optional helper extensions:

- `alicebeckett.brightscriptcomment`: comment-formatting helper only; not required
  for launch/debug.
- `redhat.vscode-xml`: XML formatting for SceneGraph files; useful but not
  required for launch/debug.

## Setup

Install dependencies before running the scripts:

```
npm install
```

For Roku deploys, copy `rokudeploy.example.json` to `rokudeploy.json` and fill in
your Roku device host and developer password. `rokudeploy.json` is ignored by git.

## Scripts

```
npm run clean
```

Deletes generated build output. This removes `build/` and `out/` using `rimraf`, a cross-platform delete tool that
works reliably on Windows.

```
npm run validate
```

Runs the BrightScript compiler validation step. This checks the Roku app from the repo root and stages compiler output under `build/staging`.

```
npm run build
```

Cleans generated output and runs validation. Use this when you want a fresh local validation pass without creating the final `ABSTV.zip` package.

```
npm run package
```

Cleans, validates, and creates a Roku package:

The package script uses `scripts/package.mjs` and writes the packaged channel to `out/ABSTV.zip`.

```
npm run deploy
```

Validates and deploys the app to the Roku device configured in `rokudeploy.json`. Use this when you want to push the current app to a physical Roku device.

```
npm run logviewer
```

Starts the local browser-based Roku log viewer. This was created to give a better view into the Roku output logs than what is presented in VS Code. The entirety of the log viewer is in the `/scripts/logviewer.mjs` file and uses node.js to serve the log viewer app run a web server.

The viewer serves a local web UI, watches `logs/rokuDevice.log`, and displays Roku
log output in real time. Start the VS Code `ABSTV` debug configuration to make the
RokuCommunity extension write device output to that log file.

For direct Roku socket mode, run:

```
node ./scripts/logs.mjs --socket
```

Socket mode connects directly to the Roku debug console on port `8085`, so it
cannot run at the same time as the VS Code Roku debugger.

## Roku Logs And The Browser Log Viewer

When the RokuCommunity extension starts the VS Code `ABSTV` debug configuration,
it connects to the Roku debug console/log stream on telnet port `8085`. VS Code
then displays that device output in the **BrightScript Log** output window.

Roku only allows one active console/debug connection on port `8085`. Because VS
Code already owns that connection during debugging, the browser log viewer cannot
also connect directly to the Roku telnet log stream at the same time.

To support debugging and the browser log viewer together, `.vscode/launch.json`
enables RokuCommunity file logging. VS Code writes the device log to:

```text
logs/rokuDevice.log
```

The browser log viewer watches that file instead of connecting directly to port
`8085`. This lets VS Code keep the debugger connection while the browser UI
renders the same log output in a custom view.
