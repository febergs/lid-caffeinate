#!/bin/bash
#
# lid-caffeinate installer.
#
#   From a checkout:      ./install.sh [bin-dir]
#   One-liner:            curl -fsSL https://raw.githubusercontent.com/febergs/lid-caffeinate/main/install.sh | bash
#
# Installs to the first writable dir of /usr/local/bin, /opt/homebrew/bin,
# ~/.local/bin — or asks for sudo to use /usr/local/bin.
#
set -euo pipefail

NAME="lid-caffeinate"
REPO_RAW="${LID_CAFFEINATE_RAW_URL:-https://raw.githubusercontent.com/febergs/lid-caffeinate/main}"

say() { printf '%s\n' "$*"; }
die() { printf '❌ Error: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "macOS only (lid-caffeinate needs pmset)."
command -v pmset >/dev/null 2>&1 || die "pmset not found — are you sure this is a Mac?"

# --- locate the script to install -------------------------------------------
# Piped from curl (BASH_SOURCE is "bash") → download; run from a repo → local file.
if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${NAME}"
  [[ -f "$SCRIPT" ]] || die "can't find ./${NAME} next to install.sh — run me from the repo root"
else
  TMP="$(mktemp -t "${NAME}")"
  trap 'rm -f "$TMP"' EXIT
  say "⬇️  Downloading ${NAME}…"
  curl -fsSL "${REPO_RAW}/${NAME}" -o "$TMP" || die "download failed — check your connection"
  SCRIPT="$TMP"
fi

# --- pick a destination ------------------------------------------------------
try_dir() {  # prints the destination path on success, silent on failure
  local dest="${1%/}/${NAME}"
  if { [[ -d "$1" ]] || mkdir -p "$1" 2>/dev/null; } && cp "$SCRIPT" "$dest" 2>/dev/null && chmod 755 "$dest" 2>/dev/null; then
    printf '%s' "$dest"
    return 0
  fi
  return 1
}

DEST=""
if [[ -n "${1:-}" ]]; then
  DEST="$(try_dir "$1")" || DEST=""
  [[ -n "$DEST" ]] || die "can't install into '$1' (not writable?)"
else
  for dir in /usr/local/bin /opt/homebrew/bin "${HOME}/.local/bin"; do
    if DEST="$(try_dir "$dir")"; then break; fi
    DEST=""
  done
  # Nothing writable without sudo → offer /usr/local/bin the classic way
  if [[ -z "$DEST" ]]; then
    say "🔐 No writable bin dir on your PATH — asking for sudo (into /usr/local/bin)"
    sudo cp "$SCRIPT" "/usr/local/bin/${NAME}"
    sudo chmod 755 "/usr/local/bin/${NAME}"
    DEST="/usr/local/bin/${NAME}"
  fi
fi

# --- short alias: lid-caff ---------------------------------------------------
alias_path="${DEST%/*}/lid-caff"
ln -sf "$NAME" "$alias_path" 2>/dev/null || sudo ln -sf "$DEST" "$alias_path" 2>/dev/null || true

# --- smoke test + PATH hint --------------------------------------------------
bash "$DEST" --help >/dev/null 2>&1 || die "installed, but it doesn't run — please report an issue"

if ! command -v "$NAME" >/dev/null 2>&1; then
  bindir="$(dirname "$DEST")"
  say ""
  say "⚠️  ${bindir} isn't on your PATH. Add this line to ~/.zshrc (or equivalent):"
  say "      export PATH=\"${bindir}:\$PATH\""
fi

say ""
say "✅ Installed: ${DEST}   (alias: ${alias_path})"
say "Try it:  lid-caff 15   # keep the Mac awake (lid closed OK) for 15 min"
