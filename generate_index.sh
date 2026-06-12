#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
index="$root/index.html"

file_icon() {
  local name="$1" ext="${1##*.}"
  ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  case "$ext" in
    png|jpg|jpeg|gif|svg|ico|webp) echo "&#x1F5BC;&#xFE0F; " ;;
    mp4|webm|mov|avi)              echo "&#x1F3AC; " ;;
    *)                             echo "" ;;
  esac
}

gen_tree() {
  local dir="$1" base="$2" rel
  rel="$(realpath --relative-to="$base" "$dir" | sed 's|\\|/|g')"
  local items=()
  while IFS= read -r -d '' f; do items+=("$f"); done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 | sort -z)
  local files=() subdirs=()
  for f in "${items[@]}"; do
    if [[ -d "$f" ]]; then subdirs+=("$f"); else files+=("$f"); fi
  done

  if [[ ${#files[@]} -gt 0 ]]; then
    echo '<ul class="file-list">'
    for f in "${files[@]}"; do
      local name="$(basename "$f")"
      local href
      href="$(realpath --relative-to="$base" "$f" | sed 's|\\|/|g')"
      echo "<li>$(file_icon "$name")<a href=\"$href\">$name</a></li>"
    done
    echo '</ul>'
  fi

  for d in "${subdirs[@]}"; do
    local name="$(basename "$d")"
    local content
    content="$(gen_tree "$d" "$base")"
    if [[ -n "$content" ]]; then
      echo "<details>"
      echo "<summary><strong>$name/</strong></summary>"
      echo "$content"
      echo "</details>"
    else
      echo "<details><summary><strong>$name/</strong> (empty)</summary></details>"
    fi
  done
}

# Root-level files (exclude .git*, generate_index.*, index.html)
root_files_html="<ul class=\"file-list\">"
while IFS= read -r -d '' f; do
  name="$(basename "$f")"
  root_files_html+="<li>$(file_icon "$name")<a href=\"$name\">$name</a></li>"
done < <(find "$root" -maxdepth 1 -type f ! -name '.git*' ! -name 'generate_index.*' ! -name 'index.html' -print0 | sort -z)
root_files_html+="</ul>"

# Subdirectory tree
tree_html=""
while IFS= read -r -d '' d; do
  name="$(basename "$d")"
  content="$(gen_tree "$d" "$root")"
  if [[ -n "$content" ]]; then
    tree_html+="<details>"
    tree_html+="<summary><strong>$name/</strong></summary>"
    tree_html+="$content"
    tree_html+="</details>"
  else
    tree_html+="<details><summary><strong>$name/</strong> (empty)</summary></details>"
  fi
done < <(find "$root" -mindepth 1 -maxdepth 1 -type d ! -name '.git*' -print0 | sort -z)

cat > "$index" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Resources</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #0d1117; color: #c9d1d9; padding: 2rem; max-width: 960px; margin: 0 auto;
    line-height: 1.6;
  }
  h1 { color: #f0f6fc; margin-bottom: 0.5rem; font-size: 1.8rem; border-bottom: 1px solid #30363d; padding-bottom: 0.5rem; }
  .subtitle { color: #8b949e; margin-bottom: 2rem; font-size: 0.9rem; }
  a { color: #58a6ff; text-decoration: none; }
  a:hover { text-decoration: underline; }
  ul { list-style: none; padding-left: 1.2rem; }
  li { padding: 0.15rem 0; }
  details { margin: 0.5rem 0 0.5rem 1rem; }
  summary { cursor: pointer; padding: 0.3rem 0; color: #e6edf3; }
  summary:hover { color: #58a6ff; }
  summary strong { font-weight: 600; }
  .file-list { margin: 0.3rem 0 0.3rem 1.2rem; border-left: 1px solid #21262d; padding-left: 1rem; }
  .file-list li { padding: 0.12rem 0; }
  .stats { color: #8b949e; font-size: 0.85rem; margin-top: 2rem; border-top: 1px solid #30363d; padding-top: 0.8rem; }
</style>
</head>
<body>
<h1>&#x1F4C1; Resources</h1>
<p class="subtitle">Browse files and media in this repository.</p>

$root_files_html

$tree_html

</body>
</html>
EOF

echo "Generated index.html"
