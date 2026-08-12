# Installing ArbVision

You need two things: the **backend** (runs headless on your own Linux VDS
— this is what actually scans markets and places your PS3838 bets, using
your own PS3838 login) and the **desktop app** (runs on your own Mac/
Windows/Linux computer — the dashboard you actually look at). Both are
tied to your license key.

## 1. Install the backend on your VDS

SSH into your VDS and run:

```bash
curl -fsSL https://raw.githubusercontent.com/ArbitrageHub/vision-cross-market-bot-releases/main/install-backend.sh \
  | bash -s -- --license-key=YOUR-LICENSE-KEY
```

This installs Docker if it's missing, pulls the backend image, and starts
it. It takes a few minutes on first run. At the end it prints your
backend's URL, e.g.:

```
http://203.0.113.10:8000
```

Keep that — you'll enter it once in the desktop app's settings.

**Security note:** this exposes port 8000 directly on your VDS. For a
first install that's fine to get going, but consider either firewalling
it to your own IP (`ufw allow from <your-ip> to any port 8000`) or putting
a reverse proxy with TLS in front of it before leaving it running
long-term — nothing in the installer does this for you automatically.

## 2. Install the desktop app on your own computer

Download the installer for your OS from the [releases page](
https://github.com/ArbitrageHub/vision-cross-market-bot-releases/releases):

- **macOS** — the `.dmg`
- **Windows** — the `.msi` or `.exe`
- **Linux** — the `.deb` (Debian/Ubuntu) or `.AppImage` (anything else)

Install it like any other app, then open it — it'll show a login screen
with a single field.

## 3. Log in

Enter your license key. On success, a Chromium window opens for you to
log into PS3838 with your own account (same as always — password/2FA/
captcha, nothing new). Once that's done, close it and the dashboard is
ready.

If this is your first time and the app doesn't already know where your
backend is, open **Settings → Backend URL** and enter the address the
install script printed in step 1.

## What's shared, what's yours

- Your PS3838 login and your Polymarket trading happen on **your own VDS**,
  using **your own credentials** — never touches anyone else's
  infrastructure.
- Your execution history, filters, and settings live only in your own
  backend's local database — nobody else can see them, there's no shared
  history between accounts.
- Market scanning/matching logic is identical for everyone (it's just
  reading public odds/order-book data), but every decision and every bet
  placed is yours alone.

## Troubleshooting

- **Backend won't come up**: `docker compose -f ~/arbvision/docker-compose.yml logs arbvision-api`
  on your VDS.
- **Desktop app says "key not found"**: double-check you copied the whole
  key, no extra spaces. If you're sure it's right, contact support — keys
  are provisioned manually right now.
- **Desktop app can't reach the backend**: confirm the backend URL in
  Settings matches what the installer printed, and that port 8000 isn't
  blocked by your VDS provider's firewall.
