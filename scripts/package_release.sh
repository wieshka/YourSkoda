#!/bin/zsh
# Back-compat wrapper: release packaging now produces a signed .dmg.
# See scripts/make_dmg.sh for the actual implementation.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT_DIR/scripts/make_dmg.sh" "$@"
