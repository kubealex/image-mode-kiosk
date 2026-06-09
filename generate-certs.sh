#!/bin/sh
set -e

CONF="$(dirname "$0")/rhem-cert.conf"
[ -f "$CONF" ] || { echo "ERROR: config not found: $CONF"; exit 1; }
. "$CONF"

: "${RHEM_API_SERVER_URL:?not set}"
: "${RHEM_USER:?not set}"
: "${RHEM_PASSWORD:?not set}"

TLS_FLAG=""
[ "$SKIP_TLS" = "true" ] && TLS_FLAG="--insecure-skip-tls-verify"

export RHEM_API_SERVER_URL

flightctl login $TLS_FLAG \
  --username="$RHEM_USER" \
  --password="$RHEM_PASSWORD" \
  "https://$RHEM_API_SERVER_URL"

flightctl certificate request \
  --signer=enrollment \
  --expiration=365d \
  --output=embedded $TLS_FLAG > config.yaml

echo "Written to config.yaml"
