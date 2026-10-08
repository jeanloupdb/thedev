#!/usr/bin/env bash
# sync-from-config.sh: syncs the SHARED app files from config-setup
# (the source of truth: private, live, a superset) to THIS thedev repo (the
# public extract). ONE-WAY: you edit config, you run this, thedev gets updated.
#
# Only touches files that thedev ALREADY tracks under bin/ bash/ claude/ zellij/
# lib/. The thedev-specific docs (README, VISION, ENGINE-*, NAMING, MANIFEST)
# stay untouched. A new @thedev script is added by hand (git add) once, then
# it syncs.
#   --dry-run | -n   show what would change, copy nothing.
#   [path]           alternate source (default: ~/jlal_perso/config).
set -u

DRY=0; SRC="$HOME/jlal_perso/config"
for a in "$@"; do
  case "$a" in
    -n|--dry-run) DRY=1 ;;
    *)            SRC="$a" ;;
  esac
done
DST="$(cd "$(dirname "$(readlink -f -- "$0")")" && pwd)"
[ -d "$SRC" ] || { echo "config not found: $SRC" >&2; exit 1; }

changed=0 same=0 missing=0
for f in $(git -C "$DST" ls-files bin bash claude zellij lib 2>/dev/null); do
  if [ ! -e "$SRC/$f" ]; then
    missing=$((missing+1)); continue   # thedev-specific file, leave it alone
  fi
  if diff -q "$SRC/$f" "$DST/$f" >/dev/null 2>&1; then
    same=$((same+1))
  else
    n=$(diff "$SRC/$f" "$DST/$f" 2>/dev/null | grep -c '^[<>]')
    printf '  \033[33m≠\033[0m %-42s %4s lines\n' "$f" "$n"
    [ "$DRY" = 1 ] || cp "$SRC/$f" "$DST/$f"
    changed=$((changed+1))
  fi
done

echo
if [ "$DRY" = 1 ]; then
  printf 'DRY-RUN: %d to update, %d already up to date, %d thedev-specific.\n' "$changed" "$same" "$missing"
  echo 'Run again without --dry-run to apply.'
else
  printf '\033[32m✓\033[0m %d synced, %d already up to date, %d thedev-specific.\n' "$changed" "$same" "$missing"
fi
