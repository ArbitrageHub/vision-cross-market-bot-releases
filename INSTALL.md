# Installing Vision Fork

You only need the **desktop app**. Scanning and execution run on the
shared production backend. Your license key is your account.

## 1. Install the desktop app

Download the installer for your OS from the [releases page](
https://github.com/ArbitrageHub/vision-cross-market-bot-releases/releases):

- **Windows** — the `.msi` or `.exe`
- **macOS** — the `.dmg`
- **Linux** — the `.deb` (Debian/Ubuntu) or `.AppImage`

Install it like any other app and open it.

## 2. Log in

Server URL is already set to `https://vision-arb.com/arbvision/api`.
Leave it unless support tells you otherwise.

Enter your license key. On success, a Chromium window opens so you can
log into PS3838 with your own account (password / 2FA / captcha). Close
it when done — the dashboard is ready.

Polymarket credentials go in **Settings → Bookmakers**. They stay on
the shared backend, scoped to your license — not in a file on your PC.

## Troubleshooting

- **"key not found" / invalid license**: copy the whole key, no extra
  spaces. If it still fails, contact support.
- **Can't reach the server**: confirm Server URL is
  `https://vision-arb.com/arbvision/api` and that you are online.
