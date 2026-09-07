# PowerShell File Watcher for Real-Time GitHub Auto-Push
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "   PHOENIX CV GOLF & RESORT - SMART STARTING OMS v3.0" -ForegroundColor Green
Write-Host "   CHẾ ĐỘ TỰ ĐỘNG THEO DÕI & ĐẨY LÊN GITHUB (LIVE AUTO-SYNC)" -ForegroundColor Yellow
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ""

$folder = $PSScriptRoot
if (-not $folder) { $folder = Get-Location }
Set-Location $folder

# 1. Kiểm tra Git
try {
    $gitVer = git --version
    Write-Host "[*] Đã phát hiện Git: $gitVer" -ForegroundColor Gray
} catch {
    Write-Host "[LỖI] Chưa tìm thấy Git trên máy tính! Vui lòng cài Git từ https://git-scm.com/" -ForegroundColor Red
    Read-Host "Bấm Enter để thoát..."
    exit
}

# 2. Khởi tạo kho Git nếu chưa có
if (-not (Test-Path "$folder\.git")) {
    Write-Host "[*] Đang khởi tạo kho Git mới..." -ForegroundColor Yellow
    git init
    git branch -M main
}

# 3. Kiểm tra Remote URL
$remotes = git remote
if (-not ($remotes -contains "origin")) {
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor DarkYellow
    Write-Host "[!] CHƯA CẤU HÌNH GITHUB REPOSITORY CỦA BẠN!" -ForegroundColor Yellow
    Write-Host "Vui lòng truy cập https://github.com/new để tạo repository (ví dụ: phoenix-oms)" -ForegroundColor White
    Write-Host "Sau đó copy đường link HTTPS và dán vào dưới đây:" -ForegroundColor White
    Write-Host "-------------------------------------------------------------------------" -ForegroundColor DarkYellow
    $repoUrl = Read-Host ">> Nhập link GitHub Repository (dạng: https://github.com/username/repo.git)"
    
    if ($repoUrl -and $repoUrl.Trim() -ne "") {
        git remote add origin $repoUrl.Trim()
        Write-Host "[*] Đã kết nối với GitHub: $repoUrl" -ForegroundColor Green
    } else {
        Write-Host "[CẢNH BÁO] Chưa nhập URL, hệ thống sẽ theo dõi nhưng chưa thể đẩy lên mạng." -ForegroundColor Yellow
    }
}

# 4. Thực hiện đẩy lần đầu nếu có thay đổi
Write-Host "[*] Đang kiểm tra và đẩy mã nguồn hiện tại lên GitHub..." -ForegroundColor Cyan
git add .
$status = git status --porcelain
if ($status) {
    git commit -m "feat: Initial commit Phoenix OMS Light Theme and Live Auto-Sync"
    git push -u origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ [THÀNH CÔNG] Đã đẩy mã nguồn lên GitHub!" -ForegroundColor Green
    }
} else {
    Write-Host "[*] Mã nguồn hiện tại đã đồng bộ với GitHub." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "   ĐANG THEO DÕI THỰC THỜI (REALTIME WATCHER ĐANG CHẠY)" -ForegroundColor Green
Write-Host "   Bất cứ khi nào có file mã nguồn được sửa hoặc lưu lại:" -ForegroundColor White
Write-Host "   -> Hệ thống sẽ TỰ ĐỘNG đẩy ngay lên GitHub trong vòng 3 giây!" -ForegroundColor Yellow
Write-Host "   -> Bạn chỉ cần mở 1 Link duy nhất và bấm F5 / Refresh để chạy ngay!" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "Nhấn phím Ctrl + C nếu muốn dừng chế độ tự động này." -ForegroundColor DarkGray
Write-Host ""

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $folder
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.Filters.Add("*.html")
$watcher.Filters.Add("*.js")
$watcher.Filters.Add("*.css")
$watcher.Filters.Add("*.md")

$lastRun = [DateTime]::MinValue

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType

    if ($path -match "\\\.git\\" -or $path -match "\\\.github\\") { return }

    $now = [DateTime]::Now
    if (($now - $script:lastRun).TotalSeconds -lt 3) { return }
    $script:lastRun = $now

    Write-Host ""
    Write-Host "[!] Phát hiện thay đổi tại: $name ($changeType) lúc $($now.ToString('HH:mm:ss'))" -ForegroundColor Yellow
    Write-Host "[*] Đang tự động gom tệp và đẩy lên GitHub..." -ForegroundColor Cyan

    Start-Sleep -Seconds 1
    git add .
    $commitMsg = "auto: update $name at $($now.ToString('yyyy-MM-dd HH:mm:ss'))"
    git commit -m $commitMsg
    git push origin main

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ [THÀNH CÔNG] Đã đẩy lên GitHub lúc $($now.ToString('HH:mm:ss'))! Link online đã có bản mới nhất." -ForegroundColor Green
    } else {
        Write-Host "⚠️ [LỖI PUSH] Không thể đẩy lên GitHub. Vui lòng kiểm tra kết nối mạng." -ForegroundColor Red
    }
}

Register-ObjectEvent $watcher 'Changed' -Action $action | Out-Null
Register-ObjectEvent $watcher 'Created' -Action $action | Out-Null

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Write-Host "Đã dừng trình theo dõi." -ForegroundColor Gray
}
