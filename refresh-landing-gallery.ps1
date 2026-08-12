$projectRoot = $PSScriptRoot
$updateScript = Join-Path $projectRoot "update-gallery.ps1"

if (-not (Test-Path -LiteralPath $updateScript)) {
  Write-Error "update-gallery.ps1 was not found."
  exit 1
}

Write-Output "Refreshing landing gallery..."
& $updateScript

if (-not $?) {
  Write-Error "Gallery refresh failed."
  exit 1
}

Write-Output ""
Write-Output "Gallery is ready."
Write-Output "Next step: commit and push the updated files to GitHub so the landing page shows the new images online."
