$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "Ilyukha Rep: zagruzhayu relizy..." -ForegroundColor Cyan
python scripts/update_releases.py ilyukha-rep
if ($LASTEXITCODE -ne 0) { exit 1 }

git add ilyukha-rep/data ilyukha-rep/js
git diff --staged --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "Ilyukha Rep: izmeneniy net." -ForegroundColor Green
    exit 0
}

git commit -m "chore: update Ilyukha Rep releases from Yandex Music"
git push
Write-Host "Ilyukha Rep: gotovo!" -ForegroundColor Green
