$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "MZLFF: zagruzhayu relizy..." -ForegroundColor Cyan
python scripts/update_releases.py mzlff
if ($LASTEXITCODE -ne 0) { exit 1 }

git add mzlff/data mzlff/js
git diff --staged --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "MZLFF: izmeneniy net." -ForegroundColor Green
    exit 0
}

git commit -m "chore: update MZLFF releases from Yandex Music"
git push
Write-Host "MZLFF: gotovo!" -ForegroundColor Green
