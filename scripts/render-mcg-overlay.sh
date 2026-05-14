#!/usr/bin/env bash
# Clone validatedpatterns/multicloud-gitops at deps/mcg-ref.txt and overlay Quarter
# pattern-metadata + values files. Output: ./build/mcg-overlay (git repo ready to push
# to branch pattern-install on this repository for the Validated Patterns Operator).
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
echo "Rendered overlay at ${OUT}. Push HEAD to branch pattern-install on ${GITHUB_REPOSITORY:-your remote} for operator installs."
