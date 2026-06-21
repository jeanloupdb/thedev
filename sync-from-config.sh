#!/usr/bin/env bash
# sync-from-config.sh — synchronise les fichiers d'app PARTAGÉS depuis config-setup
# (la source de vérité : privée, live, superset) vers CE repo thedev (l'extrait
# public). À SENS UNIQUE : tu édites config, tu lances ceci, thedev se met à jour.
#
# Ne touche QUE les fichiers que thedev suit DÉJÀ sous bin/ bash/ claude/ zellij/
# lib/ — les docs propres à thedev (README, VISION, ENGINE-*, NAMING, MANIFEST)
# restent intactes. Un nouveau script @thedev se rajoute à la main (git add) une
# fois, puis se synchronise.
#   --dry-run | -n   montre ce qui changerait, ne copie rien.
#   [chemin]         source alternative (défaut : ~/jlal_perso/config).
set -u

DRY=0; SRC="$HOME/jlal_perso/config"
for a in "$@"; do
  case "$a" in
    -n|--dry-run) DRY=1 ;;
    *)            SRC="$a" ;;
  esac
done
DST="$(cd "$(dirname "$(readlink -f -- "$0")")" && pwd)"
[ -d "$SRC" ] || { echo "config introuvable : $SRC" >&2; exit 1; }

changed=0 same=0 missing=0
for f in $(git -C "$DST" ls-files bin bash claude zellij lib 2>/dev/null); do
  if [ ! -e "$SRC/$f" ]; then
    missing=$((missing+1)); continue   # fichier propre à thedev → on n'y touche pas
  fi
  if diff -q "$SRC/$f" "$DST/$f" >/dev/null 2>&1; then
    same=$((same+1))
  else
    n=$(diff "$SRC/$f" "$DST/$f" 2>/dev/null | grep -c '^[<>]')
    printf '  \033[33m≠\033[0m %-42s %4s lignes\n' "$f" "$n"
    [ "$DRY" = 1 ] || cp "$SRC/$f" "$DST/$f"
    changed=$((changed+1))
  fi
done

echo
if [ "$DRY" = 1 ]; then
  printf 'DRY-RUN : %d à mettre à jour · %d déjà à jour · %d propres à thedev.\n' "$changed" "$same" "$missing"
  echo 'Relance sans --dry-run pour appliquer.'
else
  printf '\033[32m✓\033[0m %d synchronisé(s) · %d déjà à jour · %d propres à thedev.\n' "$changed" "$same" "$missing"
fi
