#!/bin/bash
set -e

echo "=== AI Rebels boot starting ==="

if [ -n "$SETUP_SCRIPT_URL" ]; then
  echo "Downloading setup script from $SETUP_SCRIPT_URL"
  curl -L "$SETUP_SCRIPT_URL" -o /tmp/setup.sh
  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
else
  echo "No SETUP_SCRIPT_URL provided"
fi

echo "Handing back to official RunPod startup..."
exec /start.sh