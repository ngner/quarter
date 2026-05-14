#!/usr/bin/env bash
# Clone validatedpatterns/multicloud-gitops at deps/mcg-ref.txt and overlay Quarter
# pattern-metadata + values files. Output: ./build/mcg-overlay (MCG clone with Quarter
# overlay commit; push that commit to branch pattern-install on the Quarter GitHub repo).
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REF_FILE="${ROOT}/deps/mcg-ref.txt"
OUT="${ROOT}/build/mcg-overlay"
REF=$(grep -v '^[[:space:]]*#' "$REF_FILE" | head -n1 | tr -d '[:space:]')
if [[ -z "${REF}" ]]; then
  echo "deps/mcg-ref.txt must contain a git ref (branch or tag)" >&2
  exit 1
fi
rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
if git clone --depth 1 --branch "${REF}" https://github.com/validatedpatterns/multicloud-gitops.git "$OUT" 2>/dev/null; then
  :
else
  git clone https://github.com/validatedpatterns/multicloud-gitops.git "$OUT"
  (cd "$OUT" && git fetch --depth 1 origin "${REF}" && git checkout -q FETCH_HEAD)
fi
# Shallow clones cannot be pushed to GitHub reliably (remote unpack / missing objects).
# Resolve to a full history before we add the overlay commit.
(
  cd "$OUT"
  if [[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" == "true" ]]; then
    echo "Unshallowing MCG clone so pattern-install push includes complete object graph..."
    git fetch --unshallow
  fi
)
cp "${ROOT}/pattern-metadata.yaml" "${ROOT}/values-global.yaml" "${ROOT}/values-hub.yaml" "$OUT/"
(
  cd "$OUT"
  git add pattern-metadata.yaml values-global.yaml values-hub.yaml
  if git diff --staged --quiet; then
    echo "No overlay changes to commit."
  else
    git -c core.hooksPath=/dev/null -c user.email=quarter-bot@users.noreply.github.com -c user.name=quarter-bot commit -m "Quarter overlay (MCG ref ${REF})"
  fi
)
QUARTER_GIT_URL=$(cd "$ROOT" && git remote get-url origin 2>/dev/null || true)
echo "Rendered overlay at ${OUT}."
echo ""
echo "Branch \"pattern-install\" is the install branch on your Quarter repo (see examples/pattern.yaml targetRevision)."
echo "It does not exist until you push there. This clone's origin is still upstream multicloud-gitops — do not push origin."
echo "Add your Quarter remote and create or update pattern-install, for example:"
echo "  cd \"${OUT}\""
if [[ -n "${QUARTER_GIT_URL}" ]]; then
  echo "  git remote add quarter \"${QUARTER_GIT_URL}\"   # omit if remote \"quarter\" already exists"
  echo "  git push -f quarter HEAD:pattern-install"
else
  echo "  git remote add quarter <URL-of-your-quarter-repository>"
  echo "  git push -f quarter HEAD:pattern-install"
fi
if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
  echo "In GitHub Actions this repo is ${GITHUB_REPOSITORY}; the workflow pushes to branch pattern-install there."
fi
