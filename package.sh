#!/usr/bin/env bash
# Package a World of Warcraft addon as <name>.zip containing a <name>/ folder.
#
# Environment (all optional):
#   ADDON_PATH          addon root (default: .)
#   ADDON_NAME          addon folder/zip name (default: basename of the single *.toc in ADDON_PATH)
#   ADDON_EXCLUDE_FILE  file with zip exclude patterns, relative to ADDON_PATH (default: exclude.lst, skipped if missing)
#   ADDON_EXCLUDE       extra exclude patterns, one per line
#   ADDON_OUTPUT_DIR    where the zip is written (default: current directory)
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

output_dir=$(cd "${ADDON_OUTPUT_DIR:-.}" && pwd)
cd "${ADDON_PATH:-.}" || die "addon path not found: ${ADDON_PATH}"

name=${ADDON_NAME:-}
if [[ -z $name ]]; then
    shopt -s nullglob
    tocs=(*.toc)
    shopt -u nullglob
    (( ${#tocs[@]} == 1 )) || die "expected exactly one .toc in $(pwd), found ${#tocs[@]}; set ADDON_NAME"
    name=${tocs[0]%.toc}
fi

exclude_file=${ADDON_EXCLUDE_FILE:-exclude.lst}
patterns=('.git*' '*/.git*')

add_patterns() {
    local line
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ -z ${line//[[:space:]]/} || $line == \#* ]] && continue
        patterns+=("$line")
    done
}

if [[ -f $exclude_file ]]; then
    patterns+=("$exclude_file")
    add_patterns < "$exclude_file"
fi
add_patterns <<< "${ADDON_EXCLUDE:-}"

file="$output_dir/$name.zip"
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

rm -f "$file"
# Zip in place first so patterns match paths relative to the addon root, then re-zip under <name>/.
zip -qr "$staging/flat.zip" . -x "${patterns[@]}" "$name.zip"
unzip -q "$staging/flat.zip" -d "$staging/$name"
(cd "$staging" && zip -qr "$file" "$name")

echo "Created $file ($(unzip -Z1 "$file" | grep -cv '/$') files)"

if [[ -n ${GITHUB_OUTPUT:-} ]]; then
    {
        echo "name=$name"
        echo "file=$file"
    } >> "$GITHUB_OUTPUT"
fi
