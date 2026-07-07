# Site health check: links (HTTP + local files) and PowerShell scripts.
# Called from check-site.bat in project root.

param(
    [switch]$Push
)

$ErrorActionPreference = "Continue"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

$failCount = 0

# === SKRIPTY DLYA PROVERKI (mozhno dobavit svoi .ps1) ===
$PowerShellScripts = @(
    "scripts\update-and-push-mzlff.ps1",
    "scripts\update-and-push-ilyukha-rep.ps1"
)

function Write-Ok($message) {
    Write-Host "$message - OK" -ForegroundColor Green
}

function Write-Bad($message, $detail) {
    Write-Host "$message - ERROR" -ForegroundColor Red
    if ($detail) {
        Write-Host "  $detail" -ForegroundColor DarkRed
    }
    $script:failCount++
}

function Resolve-LocalLink {
    param(
        [string]$HtmlRelativePath,
        [string]$Link
    )

    $htmlDir = Split-Path -Parent $HtmlRelativePath
    if (-not $htmlDir) {
        $htmlDir = "."
    }

    $baseDir = Join-Path $Root $htmlDir
    $target = Join-Path $baseDir $Link
    return [System.IO.Path]::GetFullPath($target)
}

function Get-LinksPageEntries {
    $linksHtml = Join-Path $Root "links.html"
    if (-not (Test-Path -LiteralPath $linksHtml)) {
        return @()
    }

    $content = Get-Content -LiteralPath $linksHtml -Raw -Encoding UTF8
    $pattern = '<a\s+href="(https?://[^"]+)"[^>]*>([^<]+)</a>'
    $entries = @()

    foreach ($match in [regex]::Matches($content, $pattern)) {
        $entries += [pscustomobject]@{
            Label = $match.Groups[2].Value.Trim()
            Url   = $match.Groups[1].Value.Trim()
        }
    }

    return $entries
}

function Get-EnglishLabel {
    param(
        [string]$Url,
        [string]$RuLabel
    )

    $map = @{
        "https://music.yandex.ru/artist/6236891"      = "MZLFF - Yandex Music"
        "https://vk.com/artist/mzlff"                 = "VK Music"
        "https://www.youtube.com/@MZLFF"              = "YouTube"
        "https://www.twitch.tv/mazellovvv"            = "Twitch"
        "https://t.me/mazellovvv"                     = "Telegram"
        "https://t.me/tribute/app?startapp=s4Pl"       = "Private Telegram"
        "https://vk.com/mzlff"                        = "VK Group"
        "https://vk.com/mazilaweek"                   = "VK Page"
        "https://mzlff.tours/"                        = "Tour"
        "https://vsrap.shop/brands/mzlff/"            = "Merch"
        "https://music.yandex.ru/artist/25098870"     = "Ilyukha Rep - Yandex Music"
    }

    if ($map.ContainsKey($Url)) {
        return $map[$Url]
    }

    return ($RuLabel -replace '[^\x00-\x7F]', '?')
}

function Write-ManualCheckHtml {
    param([array]$Entries)

    $items = ""
    $index = 1
    foreach ($entry in $Entries) {
        $label = Get-EnglishLabel -Url $entry.Url -RuLabel $entry.Label
        $safeUrl = [System.Net.WebUtility]::HtmlEncode($entry.Url)
        $safeLabel = [System.Net.WebUtility]::HtmlEncode($label)
        $items += "    <li><a href=""$safeUrl"" target=""_blank"" rel=""noopener noreferrer"">$index. $safeLabel</a></li>`n"
        $index++
    }

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manual Check - MZLFF links</title>
    <style>
        body { font-family: Segoe UI, sans-serif; background: #0b1a22; color: #e8f4f8; margin: 40px; }
        h1 { color: #4ecdc4; }
        a { color: #6eb5d9; font-size: 1.1rem; line-height: 2; }
        a:hover { color: #a8e6cf; }
        ul { list-style: none; padding: 0; }
        li { margin: 8px 0; }
        p { color: #94b8c4; }
    </style>
</head>
<body>
    <h1>MANUAL CHECK</h1>
    <p>Links from the site «Links» page. Click to open.</p>
    <ul>
$items
    </ul>
</body>
</html>
"@
}

function Show-ManualLinksSection {
    param([array]$Entries)

    if (-not $Entries -or $Entries.Count -eq 0) {
        return
    }

    Write-Host ""
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host "= MANUAL CHECK =" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""

    $numbered = @()
    $index = 1
    foreach ($entry in $Entries) {
        $label = Get-EnglishLabel -Url $entry.Url -RuLabel $entry.Label
        $numbered += [pscustomobject]@{
            Index = $index
            Label = $label
            Url   = $entry.Url
        }
        Write-Host ("  {0,2}. {1}" -f $index, $label) -ForegroundColor White
        Write-Host ("      {0}" -f $entry.Url) -ForegroundColor DarkGray
        $index++
    }

    $htmlPath = Join-Path $Root "manual-check.html"
    Write-ManualCheckHtml -Entries $Entries | Set-Content -LiteralPath $htmlPath -Encoding UTF8

    Write-Host ""
    Write-Host "Opening manual-check.html in browser..." -ForegroundColor Green
    Write-Host "Or type a number below and press Enter to open a link." -ForegroundColor DarkGray
    Write-Host ""

    try {
        Start-Process -FilePath $htmlPath
    }
    catch {
        Write-Host "Could not open browser: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Open file manually: $htmlPath" -ForegroundColor Yellow
    }

    while ($true) {
        $input = Read-Host "Link number (Enter = finish)"
        if ([string]::IsNullOrWhiteSpace($input)) {
            break
        }
        if ($input -notmatch '^\d+$') {
            Write-Host "Enter a number from the list." -ForegroundColor Yellow
            continue
        }

        $num = [int]$input
        $picked = $numbered | Where-Object { $_.Index -eq $num } | Select-Object -First 1
        if (-not $picked) {
            Write-Host "No link with number $num." -ForegroundColor Yellow
            continue
        }

        Write-Host "Opening: $($picked.Label)" -ForegroundColor Cyan
        try {
            Start-Process -FilePath $picked.Url
        }
        catch {
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Test-ExternalLink {
    param([string]$Url)

    $headers = @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) MZLFF-Site-Check/1.0"
    }

    try {
        $params = @{
            Uri             = $Url
            Method          = "Head"
            TimeoutSec      = 20
            UseBasicParsing = $true
            Headers         = $headers
        }
        $response = Invoke-WebRequest @params
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            return @{ Ok = $true; Detail = "HTTP $($response.StatusCode)" }
        }
        return @{ Ok = $false; Detail = "HTTP $($response.StatusCode)" }
    }
    catch {
        $headError = $_.Exception.Message
    }

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 20 -UseBasicParsing -Headers $headers
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            return @{ Ok = $true; Detail = "HTTP $($response.StatusCode) (GET)" }
        }
        return @{ Ok = $false; Detail = "HTTP $($response.StatusCode)" }
    }
    catch {
        $getError = $_.Exception.Message
        if ($getError) {
            return @{ Ok = $false; Detail = $getError }
        }
        return @{ Ok = $false; Detail = $headError }
    }
}

function Get-HtmlLinks {
    param([string]$HtmlPath)

    $content = Get-Content -LiteralPath $HtmlPath -Raw -Encoding UTF8
    $matches = [regex]::Matches($content, '(?:href|src)\s*=\s*"([^"]+)"')
    $links = @()

    foreach ($match in $matches) {
        $links += $match.Groups[1].Value
    }

    return $links
}

Write-Host ""
Write-Host "=== PROVERKA SSYLOK ===" -ForegroundColor Cyan
Write-Host "Koren proekta: $Root"
Write-Host ""

$manualLinkEntries = Get-LinksPageEntries
$manualLinkUrls = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $manualLinkEntries) {
    [void]$manualLinkUrls.Add($entry.Url)
}

$externalLinks = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$localLinksMap = @{}

$htmlFiles = Get-ChildItem -Path $Root -Recurse -Filter "*.html" -File |
    Where-Object { $_.FullName -notmatch '\\\.git\\' }

foreach ($html in $htmlFiles) {
    $relativeHtml = $html.FullName.Substring($Root.Length).TrimStart('\', '/')
    foreach ($link in (Get-HtmlLinks -HtmlPath $html.FullName)) {
        if (-not $link -or $link.StartsWith("#")) { continue }
        if ($link -match '^(mailto:|javascript:|data:)') { continue }

        if ($link -match '^https?://') {
            if ($manualLinkUrls.Contains($link)) { continue }
            if ($link -match '^https?://(t\.me|telegram\.me)/') { continue }
            [void]$externalLinks.Add($link)
        }
        else {
            $resolved = Resolve-LocalLink -HtmlRelativePath $relativeHtml -Link $link
            if (-not $localLinksMap.ContainsKey($link)) {
                $localLinksMap[$link] = @{
                    Resolved = $resolved
                    From     = @($relativeHtml)
                }
            }
            elseif ($localLinksMap[$link].From -notcontains $relativeHtml) {
                $localLinksMap[$link].From += $relativeHtml
            }
        }
    }
}

$deployUrl = "https://kzenof.github.io/mzlff-site/"
[void]$externalLinks.Add($deployUrl)

Write-Host "--- Vneshnie ssylki (HTTP-zapros, bez brauzera) ---" -ForegroundColor Yellow

foreach ($url in ($externalLinks | Sort-Object)) {
    $result = Test-ExternalLink -Url $url
    if ($result.Ok) {
        Write-Ok $url
        if ($result.Detail) {
            Write-Host "  $($result.Detail)" -ForegroundColor DarkGray
        }
    }
    else {
        Write-Bad $url $result.Detail
    }
}

Write-Host ""
Write-Host "--- Local links and files ---" -ForegroundColor Yellow

foreach ($link in ($localLinksMap.Keys | Sort-Object)) {
    $info = $localLinksMap[$link]
    $resolved = $info.Resolved
    $fromList = ($info.From | Sort-Object) -join ", "

    if (Test-Path -LiteralPath $resolved) {
        Write-Ok $link
        Write-Host "  fajl: $resolved" -ForegroundColor DarkGray
        Write-Host "  gde: $fromList" -ForegroundColor DarkGray
    }
    else {
        Write-Bad $link "Ne najden: $resolved (iz $fromList)"
    }
}

Write-Host ""
Write-Host "=== PROVERKA POWERSHELL-SKRIPTOV ===" -ForegroundColor Cyan

if ($Push) {
    Write-Host "Rezhim: polnyj zapusk PS1 (python + git push)" -ForegroundColor Yellow
}
else {
    Write-Host "Rezhim: tolko python-chast (bez git push). Dlya push: check-site.bat push" -ForegroundColor Yellow
}

Write-Host ""

foreach ($scriptRel in $PowerShellScripts) {
    $scriptPath = Join-Path $Root $scriptRel
    $scriptName = Split-Path $scriptRel -Leaf

    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Bad $scriptName "Fajl ne najden: $scriptPath"
        continue
    }

    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptPath,
        [ref]$null,
        [ref]$parseErrors
    )

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $errorText = ($parseErrors | ForEach-Object { $_.ToString() }) -join "; "
        Write-Bad $scriptName "Sintaksis: $errorText"
        continue
    }

    if ($Push) {
        Write-Host "Zapusk: $scriptName ..." -ForegroundColor DarkCyan
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Ok $scriptName
        }
        else {
            $detail = ($output | Out-String).Trim()
            if (-not $detail) {
                $detail = "Exit code $exitCode"
            }
            Write-Bad $scriptName $detail
        }
    }
    else {
        $artist = if ($scriptName -match "mzlff") { "mzlff" } else { "ilyukha-rep" }
        Write-Host "Zapusk python: update_releases.py $artist ..." -ForegroundColor DarkCyan

        $output = & python (Join-Path $Root "scripts\update_releases.py") $artist 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Ok "$scriptName (python)"
        }
        else {
            $detail = ($output | Out-String).Trim()
            if (-not $detail) {
                $detail = "Exit code $exitCode"
            }
            Write-Bad "$scriptName (python)" $detail
        }
    }
}

Write-Host ""
Write-Host "Total errors: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })

Show-ManualLinksSection -Entries $manualLinkEntries

exit $failCount
