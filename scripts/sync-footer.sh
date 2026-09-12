#!/usr/bin/env bash
# ==============================================================================
# sync-footer.sh — Modular Markdown Footer Hydrator
# ==============================================================================
# GitHub's native Markdown renderer does not support client-side transclusion
# (e.g., {% include %}) for security reasons. This utility maintains a strict
# Single Source of Truth in Docs/_includes/footer.md and deterministically
# synchronizes the footer block across all Markdown files using invisible
# HTML comment boundary markers: <!-- BEGIN_FOOTER --> ... <!-- END_FOOTER -->
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FOOTER_FILE="${REPO_ROOT}/Docs/_includes/footer.md"

if [[ ! -f "${FOOTER_FILE}" ]]; then
  echo "Error: Canonical footer file not found at ${FOOTER_FILE}" >&2
  exit 1
fi

FOOTER_CONTENT="$(cat "${FOOTER_FILE}")"

# Find all markdown files excluding Docs/_includes/footer.md
mapfile -t MD_FILES < <(find "${REPO_ROOT}" -type f -name "*.md" ! -path "*/_includes/*" ! -path "*/.git/*")

for file in "${MD_FILES[@]}"; do
  if grep -q "<!-- BEGIN_FOOTER -->" "${file}"; then
    # Replace existing block between BEGIN_FOOTER and END_FOOTER
    python3 -c '
import sys, re
file_path, footer_path = sys.argv[1], sys.argv[2]
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()
with open(footer_path, "r", encoding="utf-8") as f:
    footer = f.read().strip()
updated = re.sub(r"<!-- BEGIN_FOOTER -->.*?<!-- END_FOOTER -->", footer, content, flags=re.DOTALL)
with open(file_path, "w", encoding="utf-8") as f:
    f.write(updated)
' "${file}" "${FOOTER_FILE}"
    echo "[SYNCED] ${file#${REPO_ROOT}/}"
  else
    # Append footer block to the end of the file
    printf "\n%s\n" "${FOOTER_CONTENT}" >> "${file}"
    echo "[APPENDED] ${file#${REPO_ROOT}/}"
  fi
done

echo "✅ All Markdown footers synchronized from Docs/_includes/footer.md"
