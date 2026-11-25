# Builds the unofficial 1.21.11 Fabric port of YUNG's mods from the official sources + our patches.
# Needs: git and JDK 21 on PATH, internet. Output jars go to .\dist
# Usage: .\build.ps1 [-Mods YUNGs-Menu-Tweaks,YUNGs-Extras]   (YUNGs-API is always built first)
param([string[]]$Mods = @())
# 'Continue' on purpose: Windows PowerShell 5.1 turns harmless stderr output from git/gradle into fatal errors under 'Stop'.
# Every native command below is checked explicitly via $LASTEXITCODE.
$ErrorActionPreference = 'Continue'
$Root = $PSScriptRoot; $Work = Join-Path $Root 'work'; $Dist = Join-Path $Root 'dist'
New-Item -ItemType Directory -Force $Work, $Dist | Out-Null
if (-not (Get-Command java -ErrorAction SilentlyContinue)) { throw 'JDK 21 not found on PATH' }
$init = Join-Path $Root 'tools/no-signing.init.gradle'
Get-Content (Join-Path $Root 'mods.txt') | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
  $name, $repo, $commit = $_.Split('|')
  if ($Mods.Count -gt 0 -and $name -ne 'YUNGs-API' -and $Mods -notcontains $name) { return }
  $patch = Join-Path $Root "patches/$name-1.21.11.patch"
  if (-not (Test-Path $patch)) { Write-Host "skip $name (no patch yet)"; return }
  Write-Host "=== $name"
  $dir = Join-Path $Work $name
  if (Test-Path $dir) { Remove-Item -Recurse -Force $dir -ErrorAction Stop }
  git clone --quiet "https://github.com/$repo.git" $dir; if ($LASTEXITCODE) { throw "clone failed: $name" }
  git -C $dir checkout --quiet $commit; if ($LASTEXITCODE) { throw "checkout failed: $name" }
  git -C $dir apply --whitespace=nowarn $patch; if ($LASTEXITCODE) { throw "patch failed: $name" }
  Push-Location $dir
  try {
    if ($name -eq 'YUNGs-API') {
      .\gradlew.bat ':Common:publishToMavenLocal' ':Fabric:publishToMavenLocal' -q --no-daemon -I $init -x ':Common:javadoc' -x ':Fabric:javadoc'
      if ($LASTEXITCODE) { throw "API publish failed" }
    }
    .\gradlew.bat ':Fabric:build' -q --no-daemon -I $init; if ($LASTEXITCODE) { throw "build failed: $name" }
    Get-ChildItem 'Fabric/build/libs/*-Fabric-*.jar' | Where-Object { $_.Name -notmatch '(sources|javadoc)' } | Copy-Item -Destination $Dist
  } finally { Pop-Location }
}
Write-Host "Done. Jars in $Dist"
