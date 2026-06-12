# git-functions.sh — dashboard git "non-technicien".
# Réponses simples aux questions :
#   1. Où je suis ?           → branche actuelle
#   2. Suis-je à jour ?       → état vs distant
#   3. Quelles autres branches ?  → liste avec local/distant
#   4. Qu'est-ce que j'ai modifié ? → fichiers
#   5. Qu'est-ce qui s'est passé récemment ? → 3 derniers commits
# Tout en max 25 lignes.

git_status() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '\033[2mPas dans un repo git.\033[0m\n'
    return 1
  fi

  local branch up behind ahead dirty
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch="$(git rev-parse --short HEAD 2>/dev/null) (état détaché)"

  echo
  printf '  Tu es sur : \033[1;36m%s\033[0m\n' "$branch"

  # --- Synchro distante ---
  up=$(git rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null) || up=""
  if [ -z "$up" ]; then
    printf '  Synchro :   \033[2mpas de remote configuré\033[0m\n'
  else
    behind=$(echo "$up" | awk '{print $1}')
    ahead=$(echo "$up"  | awk '{print $2}')
    if [ "$ahead" = 0 ] && [ "$behind" = 0 ]; then
      printf '  Synchro :   \033[32mà jour avec le distant\033[0m\n'
    elif [ "$ahead" -gt 0 ] && [ "$behind" = 0 ]; then
      printf '  Synchro :   \033[33m%d commit(s) à pousser\033[0m (git push)\n' "$ahead"
    elif [ "$ahead" = 0 ] && [ "$behind" -gt 0 ]; then
      printf '  Synchro :   \033[33m%d commit(s) à récupérer\033[0m (git pull)\n' "$behind"
    else
      printf '  Synchro :   \033[31m%d à pousser, %d à récupérer\033[0m (divergence, merge à faire)\n' "$ahead" "$behind"
    fi
  fi

  # --- Autres branches ---
  local locals remotes all
  locals=$(git for-each-ref refs/heads/ --format='%(refname:short)' 2>/dev/null)
  remotes=$(git for-each-ref refs/remotes/ --format='%(refname:short)' 2>/dev/null \
            | grep -v 'HEAD$' | sed 's|^[^/]*/||' | sort -u)
  all=$(printf '%s\n%s\n' "$locals" "$remotes" | grep -v '^$' | sort -u)

  local n_others
  n_others=$(echo "$all" | grep -v "^${branch}$" | wc -l)
  if [ "$n_others" -gt 0 ]; then
    printf '\n  Autres branches :\n'
    local shown=0
    while IFS= read -r b; do
      [ -z "$b" ] && continue
      [ "$b" = "$branch" ] && continue
      local in_l=0 in_r=0 label color
      echo "$locals"  | grep -qFx "$b" && in_l=1
      echo "$remotes" | grep -qFx "$b" && in_r=1
      if [ "$in_l" = 1 ] && [ "$in_r" = 1 ]; then
        label="local + distant"; color="32"
      elif [ "$in_l" = 1 ]; then
        label="local seulement (pas encore poussée)"; color="33"
      else
        label="distante uniquement (jamais checkout)"; color="36"
      fi
      printf '    \033[2m·\033[0m %-20s \033[2m\033[%sm%s\033[0m\n' "$b" "$color" "$label"
      shown=$((shown+1))
      [ "$shown" -ge 4 ] && break
    done <<< "$all"
    local remaining=$((n_others - shown))
    [ "$remaining" -gt 0 ] && printf '    \033[2m· + %d autre(s)…\033[0m\n' "$remaining"
  fi

  # --- Modifs en cours (compteur seul) ---
  dirty=$(git status --porcelain | wc -l)
  if [ "$dirty" -eq 0 ]; then
    printf '\n  Modifs :    \033[32maucune (rien à committer)\033[0m\n'
  else
    printf '\n  Modifs :    \033[33m%d fichier(s) pas encore committé(s)\033[0m\n' "$dirty"
  fi

  # --- 3 derniers commits ---
  printf '\n  Récents :\n'
  git log -3 --pretty=format:'    %C(auto,yellow)%h%C(reset)  %s%C(auto,dim) — %cr%C(reset)' 2>/dev/null
  echo

  # --- Rappel commande de refresh ---
  printf '\n  \033[2m→ tape \033[0m\033[1mgs\033[0m\033[2m pour rafraîchir\033[0m\n\n'
}

alias g='clear; git_status'
alias gs='clear; git_status'
alias lg='lazygit'
