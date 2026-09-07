# PHOENIX CV GOLF & RESORT - EXCEL STARTING SHEET PARSER v3.2
# 100% Pure ASCII for Windows PowerShell 5.1 compatibility

$ErrorActionPreference = "Stop"

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "   PHOENIX CV GOLF & RESORT - XU LY DONG BO EXCEL STARTING SHEET" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Cyan

$workspace = $PSScriptRoot
if (-not $workspace) { $workspace = Get-Location }
$parentDir = Split-Path -Path $workspace -Parent

# 1. Tim file Excel Starting Sheet
$excelCandidates = @(
    (Join-Path $parentDir "STARTING SHEET - PHOENIX CV Golf & Resort.xlsx"),
    (Join-Path $workspace "STARTING SHEET - PHOENIX CV Golf & Resort.xlsx"),
    (Join-Path $parentDir "starting_sheet.xlsx"),
    (Join-Path $workspace "starting_sheet.xlsx")
)

$excelPath = $null
foreach ($p in $excelCandidates) {
    if (Test-Path $p) {
        $excelPath = $p
        break
    }
}

if (-not $excelPath) {
    $found = Get-ChildItem -Path $parentDir -Filter "*starting*.xlsx" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $excelPath = $found.FullName }
}

if (-not $excelPath) {
    Write-Host "[LOI] Khong tim thay file Excel Starting Sheet trong d:\PHOENIX!" -ForegroundColor Red
    Read-Host "Bam Enter de thoat..."
    exit 1
}

Write-Host "[*] Phat hien file Excel: $excelPath" -ForegroundColor Yellow

# 2. Copy an toan tranh bi lock file
$tempCopy = Join-Path $workspace "temp_excel_copy.xlsx"
if (Test-Path $tempCopy) { Remove-Item -Path $tempCopy -Force -ErrorAction SilentlyContinue }

try {
    $src = [System.IO.File]::Open($excelPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $dst = [System.IO.File]::Create($tempCopy)
    $src.CopyTo($dst)
    $src.Close()
    $dst.Close()
} catch {
    Copy-Item -Path $excelPath -Destination $tempCopy -Force
}

# 3. Giai nen ZIP
$tempExtract = Join-Path $workspace "temp_excel_extracted"
if (Test-Path $tempExtract) { Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($tempCopy, $tempExtract)
Remove-Item -Path $tempCopy -Force -ErrorAction SilentlyContinue

# 4. Doc Shared Strings
$sharedStrings = New-Object System.Collections.Generic.List[string]
$ssPath = Join-Path $tempExtract "xl\sharedStrings.xml"
if (Test-Path $ssPath) {
    [xml]$ssXml = Get-Content -Path $ssPath -Encoding UTF8
    foreach ($si in $ssXml.sst.si) {
        $val = ""
        if ($si.t) {
            $val = [string]$si.t
            if (-not $val -and $si.t.InnerText) { $val = [string]$si.t.InnerText }
        } elseif ($si.r) {
            $parts = @()
            foreach ($rItem in $si.r) {
                if ($rItem.t) { $parts += [string]$rItem.t }
            }
            $val = $parts -join ""
        }
        $sharedStrings.Add($val)
    }
}
Write-Host "[*] So luong chuoi ky tu (SharedStrings): $($sharedStrings.Count)" -ForegroundColor Gray

# Helper: Convert Excel float time to HH:mm string
function Convert-ExcelTime([string]$rawVal) {
    if (-not $rawVal) { return "06:30" }
    if ($rawVal -match '^\d{1,2}:\d{2}') { return $rawVal }
    $fNum = 0.0
    if ([double]::TryParse($rawVal, [ref]$fNum)) {
        if ($fNum -gt 0 -and $fNum -lt 1.0) {
            $totMin = [math]::Round($fNum * 1440)
            $h = [math]::Floor($totMin / 60)
            $m = $totMin % 60
            return ("{0:D2}:{1:D2}" -f [int]$h, [int]$m)
        }
    }
    return "06:30"
}

# 5. Doc workbook.xml de lay danh sach cac sheet
$wbPath = Join-Path $tempExtract "xl\workbook.xml"
$sheetInfoList = @()
if (Test-Path $wbPath) {
    [xml]$wbXml = Get-Content -Path $wbPath -Encoding UTF8
    $sNodes = $wbXml.workbook.sheets.sheet
    $idx = 1
    foreach ($sn in $sNodes) {
        $sheetInfoList += @{
            Name = [string]$sn.name
            SheetId = [string]$sn.sheetId
            File = ("sheet" + $idx + ".xml")
        }
        $idx++
    }
}

Write-Host "[*] Tim thay $($sheetInfoList.Count) Sheet trong file Excel:" -ForegroundColor Gray
foreach ($si in $sheetInfoList) {
    Write-Host "    - Sheet: $($si.Name) -> $($si.File)" -ForegroundColor DarkGray
}

# 6. Quet tat ca cac sheet de tim sheet chua bang Starting Sheet
$bestSheetPath = $null
$bestHeaderRow = 0
$bestColMap = @{}
$bestScore = -1

$allWorksheets = Get-ChildItem -Path (Join-Path $tempExtract "xl\worksheets") -Filter "*.xml"

foreach ($ws in $allWorksheets) {
    [xml]$wsXml = Get-Content -Path $ws.FullName -Encoding UTF8
    $rNodes = $wsXml.worksheet.sheetData.row
    if (-not $rNodes) { continue }

    # Kiem tra 30 hang dau de tim hang tieu de
    $rowCount = 0
    foreach ($r in $rNodes) {
        $rowCount++
        if ($rowCount -gt 35) { break }

        $rowMap = @{}
        foreach ($c in $r.c) {
            $colL = ($c.r -replace '\d+', '')
            $v = ""
            if ($c.v) {
                $rawV = [string]$c.v
                if ($c.t -eq "s") {
                    $sIdx = 0
                    if ([int]::TryParse($rawV, [ref]$sIdx) -and $sIdx -lt $sharedStrings.Count) {
                        $v = $sharedStrings[$sIdx]
                    }
                } else {
                    $v = $rawV
                }
            }
            $rowMap[$colL] = $v.Trim()
        }

        # Tinh diem khop tieu de
        $score = 0
        $curMap = @{}

        foreach ($colKey in $rowMap.Keys) {
            $cellText = $rowMap[$colKey].ToLower()
            if ($cellText -match 'ten|name|golfer|khach') {
                $curMap["name"] = $colKey
                $score += 5
            } elseif ($cellText -match 'gio|time|tee time') {
                $curMap["teeTime"] = $colKey
                $score += 4
            } elseif ($cellText -match 'tee|ho|box') {
                $curMap["teeBox"] = $colKey
                $score += 3
            } elseif ($cellText -match 'locker|tu') {
                $curMap["locker"] = $colKey
                $score += 3
            } elseif ($cellText -match 'caddie|cd') {
                $curMap["caddie"] = $colKey
                $score += 3
            } elseif ($cellText -match 'cart|xe') {
                $curMap["cart"] = $colKey
                $score += 3
            } elseif ($cellText -match 'stt|flight|no') {
                $curMap["flightNo"] = $colKey
                $score += 2
            } elseif ($cellText -match 'san|course') {
                $curMap["course"] = $colKey
                $score += 2
            } elseif ($cellText -match 'ghi chu|note') {
                $curMap["note"] = $colKey
                $score += 1
            } elseif ($cellText -match 'phi|fee') {
                $curMap["fee"] = $colKey
                $score += 1
            }
        }

        if ($score -gt $bestScore -and $curMap.ContainsKey("name")) {
            $bestScore = $score
            $bestSheetPath = $ws.FullName
            $bestHeaderRow = [int]$r.r
            $bestColMap = $curMap
        }
    }
}

if (-not $bestSheetPath) {
    # Fallback: chon sheet lon nhat
    $maxLen = 0
    foreach ($ws in $allWorksheets) {
        if ($ws.Length -gt $maxLen) {
            $maxLen = $ws.Length
            $bestSheetPath = $ws.FullName
        }
    }
    $bestColMap = @{
        flightNo = "A"
        teeTime  = "B"
        teeBox   = "C"
        name     = "D"
        locker   = "E"
        caddie   = "F"
        cart     = "G"
    }
    $bestHeaderRow = 1
}

Write-Host "[*] Da chon Sheet: $(Split-Path -Leaf $bestSheetPath) (Diem khop: $bestScore)" -ForegroundColor Green
Write-Host "[*] Hang tieu de: $bestHeaderRow" -ForegroundColor Gray
Write-Host "[*] Ban do cot: $(($bestColMap.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')" -ForegroundColor Cyan

# 7. Trich xuat du lieu cac Flights
[xml]$targetXml = Get-Content -Path $bestSheetPath -Encoding UTF8
$targetRows = $targetXml.worksheet.sheetData.row

$extractedFlights = New-Object System.Collections.Generic.List[object]
$currentFlight = $null

foreach ($r in $targetRows) {
    $rIdx = [int]$r.r
    if ($rIdx -le $bestHeaderRow) { continue }

    $rowCells = @{}
    foreach ($c in $r.c) {
        $colL = ($c.r -replace '\d+', '')
        $val = ""
        if ($c.v) {
            $rawV = [string]$c.v
            if ($c.t -eq "s") {
                $idx = 0
                if ([int]::TryParse($rawV, [ref]$idx) -and $idx -lt $sharedStrings.Count) {
                    $val = $sharedStrings[$idx]
                }
            } else {
                $val = $rawV
            }
        }
        $rowCells[$colL] = $val.Trim()
    }

    # Lay Ten Golfer tu cot da map hoac tim cot chua chu
    $nameVal = ""
    if ($bestColMap.ContainsKey("name") -and $rowCells.ContainsKey($bestColMap["name"])) {
        $nameVal = $rowCells[$bestColMap["name"]]
    }

    # Neu cot name rong, thu tim cot ben canh
    if (-not $nameVal -or $nameVal -match '^[\d.\s,]+$') {
        foreach ($k in @("C", "D", "E", "F", "B", "G")) {
            if ($rowCells.ContainsKey($k)) {
                $testVal = $rowCells[$k]
                # Phai chua it nhat 1 chu cai, khong phai chi toan so/thap phan
                if ($testVal.Length -ge 2 -and ($testVal -match '[a-zA-Z\p{L}]') -and ($testVal.ToLower() -notmatch 'tee|flight|time|gio|ten|name|locker|caddie|cart|tong|total')) {
                    $nameVal = $testVal
                    break
                }
            }
        }
    }

    # Neu van khong co ten hop le thi bo qua hang nay
    if (-not $nameVal -or ($nameVal -notmatch '[a-zA-Z\p{L}]')) { continue }

    # Lay gio TeeTime
    $teeTime = "06:30"
    if ($bestColMap.ContainsKey("teeTime") -and $rowCells.ContainsKey($bestColMap["teeTime"])) {
        $teeTime = Convert-ExcelTime $rowCells[$bestColMap["teeTime"]]
    } else {
        # Tim bat ky o nao co dang gio hoac float time
        foreach ($k in @("B", "C", "D", "A")) {
            if ($rowCells.ContainsKey($k) -and ($rowCells[$k] -match '^\d{1,2}:\d{2}')) {
                $teeTime = $rowCells[$k]
                break
            }
        }
    }

    # Lay TeeBox & Course
    $teeBox = "C1"
    if ($bestColMap.ContainsKey("teeBox") -and $rowCells.ContainsKey($bestColMap["teeBox"])) {
        $rawTb = $rowCells[$bestColMap["teeBox"]].ToUpper()
        if ($rawTb) { $teeBox = $rawTb }
    }

    $course = "CHAMPION"
    if ($teeBox -match "D" -or $teeBox -match "DRAGON") { $course = "DRAGON" }
    elseif ($teeBox -match "P" -or $teeBox -match "PHOENIX") { $course = "PHOENIX" }

    # Lay Locker
    $locker = "N/A"
    if ($bestColMap.ContainsKey("locker") -and $rowCells.ContainsKey($bestColMap["locker"])) {
        $rawL = $rowCells[$bestColMap["locker"]]
        if ($rawL -and ($rawL -notmatch '^0\.\d+')) { $locker = $rawL }
    }

    # Lay Caddie
    $caddie = "Chua gan"
    if ($bestColMap.ContainsKey("caddie") -and $rowCells.ContainsKey($bestColMap["caddie"])) {
        $rawC = $rowCells[$bestColMap["caddie"]]
        if ($rawC -and ($rawC -notmatch '^0\.\d+')) { $caddie = $rawC }
    }

    # Lay Cart
    $cart = "Di bo"
    if ($bestColMap.ContainsKey("cart") -and $rowCells.ContainsKey($bestColMap["cart"])) {
        $rawCart = $rowCells[$bestColMap["cart"]]
        if ($rawCart -and ($rawCart -notmatch '^0\.\d+')) { $cart = $rawCart }
    }

    # Lay Fee
    $fee = 140
    if ($bestColMap.ContainsKey("fee") -and $rowCells.ContainsKey($bestColMap["fee"])) {
        $cleanFee = ($rowCells[$bestColMap["fee"]] -replace '[^\d.]', '')
        $fVal = 0
        if ([double]::TryParse($cleanFee, [ref]$fVal)) {
            if ($fVal -gt 1000) { $fee = [math]::Round($fVal / 1000, 0) }
            elseif ($fVal -gt 0) { $fee = $fVal }
        }
    }

    # Kiem tra flight No
    $flightNoVal = ""
    if ($bestColMap.ContainsKey("flightNo") -and $rowCells.ContainsKey($bestColMap["flightNo"])) {
        $flightNoVal = $rowCells[$bestColMap["flightNo"]]
    }

    $player = @{
        name    = $nameVal
        locker  = $locker
        gender  = "Male"
        age     = "45 - 55"
        booking = if ($fee -ge 190) { "BOOKING" } else { "NON BOOKING" }
        caddie  = $caddie
        cart    = $cart
        fee     = $fee
    }

    # Quyết định Flight mới hay ghép vào Flight hiện tại
    $isNew = $false
    if ($flightNoVal -match '^\d+$') {
        $isNew = $true
    } elseif ($currentFlight -eq $null) {
        $isNew = $true
    } elseif ($currentFlight.players.Count -ge 4) {
        $isNew = $true
    } elseif ($teeTime -ne $currentFlight.teeTime -and $currentFlight.players.Count -ge 1) {
        $isNew = $true
    }

    if ($isNew) {
        $fIdx = $extractedFlights.Count + 1
        $currentFlight = @{
            id         = [int64](([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) + $fIdx)
            flightNo   = $fIdx
            course     = $course
            teeBox     = $teeBox
            teeTime    = $teeTime
            finishTime = ""
            status     = "WAITING"
            holes      = "18 HOLES"
            note       = "Starting Sheet tu Excel"
            players    = New-Object System.Collections.Generic.List[object]
        }
        $currentFlight.players.Add($player)
        $extractedFlights.Add($currentFlight)
    } else {
        $currentFlight.players.Add($player)
    }
}

# 8. Don thu muc tam
Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "   [THANH CONG] Da trich xuat $($extractedFlights.Count) Flights tu Excel!" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Green

# In mau 3 Flight dau tien de nguoi dung kiem tra
$sampleCount = [math]::Min(3, $extractedFlights.Count)
for ($i = 0; $i -lt $sampleCount; $i++) {
    $sf = $extractedFlights[$i]
    Write-Host "Flight #$($sf.flightNo) | $($sf.course) ($($sf.teeBox)) luc $($sf.teeTime):" -ForegroundColor Cyan
    foreach ($sp in $sf.players) {
        Write-Host "   -> Golfer: $($sp.name) | Locker: $($sp.locker) | Caddie: $($sp.caddie) | Cart: $($sp.cart)" -ForegroundColor White
    }
}

# 9. Chuyen sang JSON va ghi vao index.html & phoenix_smart_starting_oms.html
$jsonText = $extractedFlights | ConvertTo-Json -Depth 6

$targetFiles = @(
    (Join-Path $workspace "index.html"),
    (Join-Path $workspace "phoenix_smart_starting_oms.html")
)

$nowBuildId = (Get-Date).ToString("yyyyMMdd_HHmmss")

foreach ($tf in $targetFiles) {
    if (Test-Path $tf) {
        $content = [System.IO.File]::ReadAllText($tf, [System.Text.Encoding]::UTF8)
        $content = [regex]::Replace($content, 'const\s+DATA_BUILD_ID\s*=\s*"[^"]*";', "const DATA_BUILD_ID = ""$nowBuildId"";")
        $pattern = '(?s)(const\s+initialRawData\s*=\s*)\[.*?\];'
        $replacement = "`$1$jsonText;"
        $newContent = [regex]::Replace($content, $pattern, $replacement)
        [System.IO.File]::WriteAllText($tf, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "[*] Da cap nhat du lieu moi vao: $(Split-Path -Leaf $tf)" -ForegroundColor Cyan
    }
}

# 10. Tu dong Day len GitHub
Write-Host ""
Write-Host "[*] Dang tu dong day len GitHub..." -ForegroundColor Yellow
try {
    git add .
    $nowStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    git commit -m "feat: Auto sync clean Starting Sheet from Excel [$nowStr]"
    git push origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=========================================================================" -ForegroundColor Green
        Write-Host "   [HOAN TAT] DA DONG BO LEN GITHUB THANH CONG!" -ForegroundColor Green
        Write-Host "   Ban chi can mo link online va bam F5 (Refresh) de xem ngay!" -ForegroundColor White
        Write-Host "=========================================================================" -ForegroundColor Green
    } else {
        Write-Host "[!] Git push chua hoan tat. Vui long kiem tra quyen truy cap GitHub." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[!] Thong bao Git: $_" -ForegroundColor DarkGray
}

Write-Host ""
Read-Host "Bam phim Enter de hoan tat..."
