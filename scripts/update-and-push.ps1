# Обновить релизы с Яндекс Музыки и залить на GitHub
# Запуск: правый клик -> "Выполнить с PowerShell" или из терминала:
#   cd C:\Users\akalinsky\Documents\mzlff-site
#   .\scripts\update-and-push.ps1

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "Загружаю релизы с Яндекс Музыки..." -ForegroundColor Cyan
python scripts/update_releases.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка при загрузке релизов." -ForegroundColor Red
    exit 1
}

git add data/releases.json

$diff = git diff --staged --name-only
if (-not $diff) {
    Write-Host "Изменений нет — всё актуально." -ForegroundColor Green
    exit 0
}

git commit -m "chore: update releases from Yandex Music"
git push

Write-Host "Готово! Сайт обновится через минуту." -ForegroundColor Green
