$galleryFolder = Join-Path $PSScriptRoot "landing-gallery"
$manifestPath = Join-Path $PSScriptRoot "gallery-manifest.js"
$allowedExtensions = @(".png", ".jpg", ".jpeg", ".webp", ".gif")

if (-not (Test-Path -LiteralPath $galleryFolder)) {
  New-Item -ItemType Directory -Path $galleryFolder | Out-Null
}

$files = Get-ChildItem -LiteralPath $galleryFolder -File |
  Where-Object { $allowedExtensions -contains $_.Extension.ToLowerInvariant() } |
  Sort-Object Name

$entries = foreach ($file in $files) {
  $relativePath = "landing-gallery/$($file.Name)"
  "  `"$relativePath`""
}

$manifest = @(
  "window.ODYSSEY_GALLERY_IMAGES = ["
  ($entries -join ",`r`n")
  "];"
) -join "`r`n"

Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding UTF8
Write-Output "Gallery manifest updated: $($files.Count) image(s) found."
