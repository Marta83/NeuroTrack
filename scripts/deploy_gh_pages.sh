#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter no esta disponible en PATH."
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync no esta disponible en PATH."
  exit 1
fi

echo "==> Building web app..."
flutter build web --base-href /NeuroTrack/ --no-wasm-dry-run

TMP_DIR="$(mktemp -d)"
cleanup() {
  git worktree remove "$TMP_DIR" --force >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if git show-ref --verify --quiet refs/heads/gh-pages; then
  git worktree add --force "$TMP_DIR" gh-pages
elif git ls-remote --exit-code --heads origin gh-pages >/dev/null 2>&1; then
  git worktree add --force -B gh-pages "$TMP_DIR" origin/gh-pages
else
  git worktree add --force -b gh-pages "$TMP_DIR"
fi

if [[ ! -f "$TMP_DIR/.git" && ! -d "$TMP_DIR/.git" ]]; then
  echo "No se pudo preparar el worktree de gh-pages."
  exit 1
fi

echo "==> Syncing build/web -> gh-pages..."
rsync -a --delete --exclude='.git' build/web/ "$TMP_DIR"/

cd "$TMP_DIR"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "El directorio temporal no es un repositorio git valido."
  exit 1
fi

STATUS="$(git status --porcelain)"
if [[ -z "$STATUS" ]]; then
  echo "No hay cambios para publicar."
  exit 0
fi

git add -A
git commit -m "Deploy web $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null
git push origin gh-pages
echo "Deploy completado en branch gh-pages."
