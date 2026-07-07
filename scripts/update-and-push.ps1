$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "Zagruzhayu relizy s Yandex Music..." -ForegroundColor Cyan
python scripts/update_releases.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "Oshibka pri zagruzke relizov." -ForegroundColor Red
    exit 1
}

git add data/releases.json
git diff --staged --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "Izmeneniy net, vse aktualno." -ForegroundColor Green
    exit 0
}

git commit -m "chore: update releases from Yandex Music"
git push

Write-Host "Gotovo! Sayt obnovitsya cherez minutu." -ForegroundColor Green
