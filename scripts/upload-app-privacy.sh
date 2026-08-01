#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "${FASTLANE_SESSION:-}" ]]; then
  echo "error: FASTLANE_SESSION is required for Apple's App Privacy questionnaire" >&2
  echo "       create one with: fastlane spaceauth -u jackwallner@gmail.com" >&2
  exit 2
fi

exec "$ROOT/scripts/fastlane-bin.sh" run upload_app_privacy_details_to_app_store \
  app_identifier:com.jackwallner.skat \
  json_path:"$ROOT/fastlane/app_privacy_details.json"
