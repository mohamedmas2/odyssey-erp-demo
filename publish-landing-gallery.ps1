$projectRoot = $PSScriptRoot
$refreshScript = Join-Path $projectRoot "refresh-landing-gallery.ps1"
$publishPaths = @(
  "index.html",
  "script.js",
  "style.css",
  "Odyssey_ERP_Logo.png",
  "Cover.png",
  "gallery-manifest.js",
  "update-gallery.ps1",
  "refresh-landing-gallery.ps1",
  "publish-landing-gallery.ps1",
  "landing-gallery"
)

if (-not (Test-Path -LiteralPath $refreshScript)) {
  Write-Error "refresh-landing-gallery.ps1 was not found."
  exit 1
}

Write-Output "Refreshing landing gallery..."
& $refreshScript

if (-not $?) {
  Write-Error "Gallery refresh failed."
  exit 1
}

Write-Output ""
Write-Output "Staging landing page files..."
git add -- @publishPaths
if (-not $?) {
  Write-Error "Could not stage landing page files."
  exit 1
}

$stagedFiles = git diff --cached --name-only -- @publishPaths
if (-not $?) {
  Write-Error "Could not inspect staged changes."
  exit 1
}

if (-not $stagedFiles) {
  Write-Output "No new landing gallery changes to publish."
  exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$commitMessage = "Update landing gallery $timestamp"

Write-Output "Saving landing page changes..."
git commit -m $commitMessage
if (-not $?) {
  Write-Error "Could not create the local save point."
  exit 1
}

$commitHash = (git rev-parse HEAD).Trim()
if (-not $?) {
  Write-Error "Could not read the new commit hash."
  exit 1
}

Write-Output "Getting latest GitHub updates..."
git fetch origin
if (-not $?) {
  Write-Error "Could not fetch the latest GitHub updates."
  exit 1
}

$tempWorktree = Join-Path $env:TEMP ("odyssey-landing-publish-" + [guid]::NewGuid().ToString("N"))
$safeTempWorktree = $tempWorktree.Replace("\", "/")

try {
  Write-Output "Preparing a clean publish copy..."
  git worktree add $tempWorktree origin/main | Out-Null
  if (-not $?) {
    throw "Could not prepare the clean publish copy."
  }

  Write-Output "Copying the latest landing page files..."
  foreach ($path in $publishPaths) {
    $sourcePath = Join-Path $projectRoot $path
    $targetPath = Join-Path $tempWorktree $path

    if (Test-Path -LiteralPath $targetPath) {
      Remove-Item -LiteralPath $targetPath -Recurse -Force
    }

    if (-not (Test-Path -LiteralPath $sourcePath)) {
      continue
    }

    $sourceItem = Get-Item -LiteralPath $sourcePath

    if ($sourceItem.PSIsContainer) {
      Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Recurse -Force
    }
    else {
      $targetDirectory = Split-Path -Path $targetPath -Parent
      if ($targetDirectory -and -not (Test-Path -LiteralPath $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
      }
      Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    }
  }

  git -C $tempWorktree -c "safe.directory=$safeTempWorktree" add --all
  if (-not $?) {
    throw "Could not stage the landing page files in the clean publish copy."
  }

  git -C $tempWorktree -c "safe.directory=$safeTempWorktree" diff --cached --quiet
  if ($LASTEXITCODE -eq 0) {
    Write-Output "GitHub already has the same landing page files."
    return
  }

  Write-Output "Saving the clean publish copy..."
  git -C $tempWorktree -c "safe.directory=$safeTempWorktree" commit -m $commitMessage | Out-Null
  if (-not $?) {
    throw "Could not save the clean publish copy."
  }

  Write-Output "Pushing to GitHub..."
  git -C $tempWorktree -c "safe.directory=$safeTempWorktree" push origin HEAD:main
  if (-not $?) {
    throw "Could not push the landing page update to GitHub."
  }
}
catch {
  Write-Error $_
  exit 1
}
finally {
  if (Test-Path -LiteralPath $tempWorktree) {
    git worktree remove $tempWorktree --force | Out-Null
  }
}

Write-Output ""
Write-Output "Landing gallery published successfully."
