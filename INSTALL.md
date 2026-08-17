# Installing Vision Fork

You only need the **desktop app**. Matching, safety, and history run on the
shared production backend. Your license key is your account.

## 1. Install the desktop app

Download **v0.2.2** (or newer) for your OS from the [releases page](
https://github.com/ArbitrageHub/vision-cross-market-bot-releases/releases):

- **Windows** — the `.msi` or `.exe`
- **macOS** — the `.dmg`
- **Linux** — the `.deb` (Debian/Ubuntu) or `.AppImage`

Install it like any other app and open it. macOS Gatekeeper may say the
app is damaged because the build is unsigned — that is expected; support
will tell you how to open it.

In the desktop app, **Settings** shows this installer's version. If a
newer GitHub release exists, **Update** downloads the installer (progress
bar), opens it, then quits so you can finish installing and reopen.
The web UI at `/arbvision/` cannot replace itself with an `.exe` — use
the desktop app, or download from the releases page.

The in-app Update button does **not** update the shared server.

## 2. Log in

Server URL is already set to `https://vision-arb.com/arbvision/api`.
Leave it unless support tells you otherwise.

Enter your license key. After a successful login, a Chromium window can
open **on this computer** so PS3838 runs locally (scan and bets). Log
into PS3838 there if asked (password / 2FA / captcha). Leave that window
open while the scanner is running.

Polymarket credentials go in **Settings → Bookmakers**. They stay on
the shared backend, scoped to your license — not in a file on your PC.

## Troubleshooting

- **"key not found" / invalid license**: copy the whole key, no extra
  spaces. If it still fails, contact support.
- **Can't reach the server**: confirm Server URL is
  `https://vision-arb.com/arbvision/api` and that you are online.
- **No Chromium window / PS3838 stays offline**: you need desktop
  **0.2.2+**, and the app must stay open. Re-login if the license was
  entered in an older installer.
