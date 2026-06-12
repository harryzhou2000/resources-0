function Get-RelativePath {
    param($Path, $Base)
    $fullPath = Resolve-Path $Path -Relative
    return $fullPath.TrimStart('.\').Replace('\', '/')
}

function Get-FileIcon {
    param($Name)
    $ext = [System.IO.Path]::GetExtension($Name).ToLower()
    if (@('.png','.jpg','.jpeg','.gif','.svg','.ico','.webp') -contains $ext) { return "🖼️ " }
    if (@('.mp4','.webm','.mov','.avi') -contains $ext) { return "🎬 " }
    return ""
}

function Get-DirTree {
    param($Dir, $BaseDir)
    $items = Get-ChildItem $Dir | Sort-Object { $_.PSIsContainer -eq $false }, Name
    $html = ""
    $subdirs = $items | Where-Object { $_.PSIsContainer }
    $files = $items | Where-Object { -not $_.PSIsContainer }
    if ($files.Count -gt 0) {
        $html += '<ul class="file-list">'
        foreach ($f in $files) {
            $rel = Get-RelativePath $f.FullName $BaseDir
            $html += "<li>$(Get-FileIcon $f.Name)<a href=`"$rel`">$($f.Name)</a></li>`n"
        }
        $html += '</ul>'
    }
    foreach ($d in $subdirs) {
        $rel = Get-RelativePath $d.FullName $BaseDir
        $content = Get-DirTree $d.FullName $BaseDir
        $empty = if ($content -eq "") { " (empty)" } else { "" }
        if ($content -ne "") {
            $html += "<details>`n<summary><strong>$rel/</strong></summary>`n$content</details>`n"
        } else {
            $html += "<details>`n<summary><strong>$rel/</strong> (empty)</summary>`n</details>`n"
        }
    }
    return $html
}

$root = Resolve-Path (Split-Path $PSCommandPath -Parent)

# Subdirectory tree only (not root itself)
$tree = ""
$subdirs = Get-ChildItem $root | Where-Object { $_.PSIsContainer -and $_.Name -notlike '.git*' } | Sort-Object Name
foreach ($d in $subdirs) {
    $content = Get-DirTree $d.FullName $root
    if ($content -ne "") {
        $tree += "<details>`n<summary><strong>$($d.Name)/</strong></summary>`n$content</details>`n"
    } else {
        $tree += "<details>`n<summary><strong>$($d.Name)/</strong> (empty)</summary>`n</details>`n"
    }
}

# Root-level files (excluding .git and scripts)
$scriptNames = @('generate_index.ps1', 'generate_index.sh', 'generate_index.bat')
$rootFiles = Get-ChildItem $root | Where-Object {
    -not $_.PSIsContainer -and $_.Name -notlike '.git*' -and $_.Name -notin $scriptNames -and $_.Name -ne 'index.html'
} | Sort-Object Name
$rootHtml = '<ul class="file-list">'
foreach ($f in $rootFiles) {
    $name = $f.Name
    $ext = [System.IO.Path]::GetExtension($name).ToLower()
    $icon = ""
    if (@('.png','.jpg','.jpeg','.gif','.svg','.ico','.webp') -contains $ext) { $icon = "🖼️ " }
    elseif (@('.mp4','.webm','.mov','.avi') -contains $ext) { $icon = "🎬 " }
    $rootHtml += "<li>$icon<a href=`"$name`">$name</a></li>`n"
}
$rootHtml += '</ul>'

$html = @"
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
<h1>📁 Resources</h1>
<p class="subtitle">Browse files and media in this repository.</p>

$rootHtml

$tree

</body>
</html>
"@

Set-Content -Path (Join-Path $root 'index.html') -Value $html -Encoding UTF8
Write-Host "Generated index.html" -ForegroundColor Green
