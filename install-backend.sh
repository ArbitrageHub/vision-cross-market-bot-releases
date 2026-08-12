#!/usr/bin/env bash
# ArbVision backend installer — run this on your own Linux VDS.
#
#   curl -fsSL https://raw.githubusercontent.com/ArbitrageHub/vision-cross-market-bot-releases/main/install-backend.sh \
#     | bash -s -- --license-key=YOUR-LICENSE-KEY
#
# What this does:
#   1. Installs Docker if it's not already present (get.docker.com).
#   2. Asks the operator's central service for a short-lived GHCR pull
#      token + image ref, authenticated with YOUR license key, and logs
#      into ghcr.io with it. The token is never written to disk and never
#      appears in this script or in git — it's fetched fresh on every
#      install/reinstall (see CENTRAL_SERVICE_URL/v1/registry/pull-credentials).
#   3. Downloads docker-compose.customer.yml from the same public repo.
#   4. Writes your license key + a freshly generated Redis password into
#      ./arbvision/.env and ./arbvision/data/license.json.
#   5. Starts the backend with `docker compose up -d`.
#
# Nothing here ever touches the operator's own infrastructure — this is
# YOUR install, on YOUR VDS, with YOUR license key.
set -euo pipefail

# --- Fixed, non-secret config -----------------------------------------------
RELEASES_REPO="ArbitrageHub/vision-cross-market-bot-releases"                # ArbitrageHub/vision-cross-market-bot-releases — filled in before publishing
CENTRAL_SERVICE_URL="https://vision-arb.com/arbvision/central"     # the operator's central service — not secret, same for every customer

INSTALL_DIR="${INSTALL_DIR:-$HOME/arbvision}"

# --- Args --------------------------------------------------------------------
LICENSE_KEY=""
for arg in "$@"; do
  case "$arg" in
    --license-key=*) LICENSE_KEY="${arg#--license-key=}" ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

if [[ -z "$LICENSE_KEY" ]]; then
  echo "Usage: install-backend.sh --license-key=YOUR-LICENSE-KEY" >&2
  exit 1
fi

# Deliberately NOT a literal "== ArbitrageHub/vision-cross-market-bot-releases" comparison: CI's sed
# substitutes every occurrence of that exact literal text in this file,
# including inside this guard itself — an equality check against the
# literal token gets rewritten right along with the real placeholder use
# above and then always compares the (now-substituted) value to itself,
# permanently self-defeating the guard. Matching on "still contains __"
# instead survives the substitution: real values never contain a double
# underscore, an un-rendered placeholder always does.
if [[ "$RELEASES_REPO" == *"__"* || "$CENTRAL_SERVICE_URL" == *"__"* ]]; then
  echo "This script's placeholders were never filled in before publishing — refusing to run." >&2
  echo "(This means the operator hasn't finished the release setup yet.)" >&2
  exit 1
fi

section() { echo; echo "=== $* ==="; }

# Extracts a top-level string field from a small flat JSON object. Prefers
# python3 (present on nearly every Linux distro's base image); falls back
# to a grep/sed one-liner good enough for the flat {"a":"b"} shape this
# script's own endpoint returns, so a minimal/stripped VDS without python3
# still works.
json_field() {
  local json="$1" field="$2"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; print(json.loads(sys.argv[1])[sys.argv[2]])" "$json" "$field"
  else
    echo "$json" | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
  fi
}

# --- 1. Docker ---------------------------------------------------------------
section "Checking Docker"
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found — installing via get.docker.com..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker 2>/dev/null || service docker start 2>/dev/null || true
else
  echo "Docker already installed: $(docker --version)"
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose plugin not found. Install Docker Compose v2 and re-run." >&2
  exit 1
fi

# --- 2. Fetch pull credentials + GHCR login -----------------------------------
section "Fetching GHCR pull credentials from central"
PULL_CREDS_JSON="$(curl -fsSL -H "Authorization: Bearer ${LICENSE_KEY}" "${CENTRAL_SERVICE_URL}/v1/registry/pull-credentials")" || {
  echo "Could not fetch pull credentials — check your license key and CENTRAL_SERVICE_URL." >&2
  exit 1
}
GHCR_PULL_TOKEN="$(json_field "$PULL_CREDS_JSON" token)"
GHCR_PULL_USER="$(json_field "$PULL_CREDS_JSON" username)"
ARBVISION_IMAGE="$(json_field "$PULL_CREDS_JSON" image)"

section "Logging into ghcr.io (read-only pull token)"
echo "$GHCR_PULL_TOKEN" | docker login ghcr.io -u "$GHCR_PULL_USER" --password-stdin
unset GHCR_PULL_TOKEN PULL_CREDS_JSON

# --- 3. Fetch compose file ----------------------------------------------------
section "Fetching docker-compose.customer.yml"
mkdir -p "$INSTALL_DIR/data"
curl -fsSL "https://raw.githubusercontent.com/${RELEASES_REPO}/main/docker-compose.customer.yml" \
  -o "$INSTALL_DIR/docker-compose.yml"

# --- 4. Write config -----------------------------------------------------------
section "Writing configuration"
if [[ -f "$INSTALL_DIR/.env" ]]; then
  echo ".env already exists — leaving it as-is (delete it to regenerate secrets)."
else
  REDIS_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)"
  cat > "$INSTALL_DIR/.env" <<EOF
ARBVISION_IMAGE=${ARBVISION_IMAGE}
CENTRAL_SERVICE_URL=${CENTRAL_SERVICE_URL}
REDIS_PASSWORD=${REDIS_PASSWORD}
EOF
fi

# Pre-activates the backend non-interactively — same file/shape
# LicenseService (backend/app/services/license_service.py) reads on its
# own, so no separate manual activation step is needed on first boot.
cat > "$INSTALL_DIR/data/license.json" <<EOF
{
  "license_key": "${LICENSE_KEY}"
}
EOF

# --- 5. Start ------------------------------------------------------------------
section "Starting ArbVision backend"
cd "$INSTALL_DIR"
docker compose up -d

section "Waiting for health"
READY=0
for _ in $(seq 1 60); do
  if docker exec arbvision_api curl -sf http://127.0.0.1:8000/health/liveness >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 5
done

PUBLIC_IP="$(curl -fsSL https://api.ipify.org 2>/dev/null || echo "<your-vds-ip>")"
if [[ "$READY" == "1" ]]; then
  section "Done"
  echo "Backend is up. In the ArbVision desktop app, set Settings > Backend URL to:"
  echo
  echo "    http://${PUBLIC_IP}:8000"
  echo
  echo "Then log in with your license key on the app's login screen."
  echo "(Consider firewalling port 8000 to your own IP, or putting TLS in"
  echo "front of it — see docs/CUSTOMER_INSTALL.md.)"
else
  echo "Backend did not become healthy within 5 minutes — check logs with:" >&2
  echo "  docker compose -f $INSTALL_DIR/docker-compose.yml logs arbvision-api" >&2
  exit 1
fi
