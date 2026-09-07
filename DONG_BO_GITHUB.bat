@echo off
chcp 65001 >nul
title PHOENIX GOLF OMS - ĐỒNG BỘ LÊN GITHUB 1-CHẠM
color 0A

echo =========================================================================
echo    PHOENIX CV GOLF & RESORT - SMART STARTING OMS v3.0
echo    CÔNG CỤ ĐỒNG BỘ TRỰC TIẾP LÊN GITHUB VÀ CHẠY ONLINE
echo =========================================================================
echo.

:: 1. Kiểm tra Git đã cài đặt chưa
where git >nul 2>nul
if %errorlevel% neq 0 (
    color 0C
    echo [LỖI] Máy tính chưa cài đặt Git!
    echo Vui lòng tải và cài đặt Git từ: https://git-scm.com/downloads
    echo Sau khi cài xong, hãy chạy lại file này.
    pause
    exit /b
)

:: 2. Khởi tạo kho Git nếu chưa có
if not exist ".git" (
    echo [*] Khởi tạo kho Git mới...
    git init
    git branch -M main
)

:: 3. Kiểm tra Remote URL
git remote get-url origin >nul 2>nul
if %errorlevel% neq 0 (
    echo -------------------------------------------------------------------------
    echo [!] CHƯA CẤU HÌNH ĐƯỜNG DẪN GITHUB REPOSITORY!
    echo.
    echo Vui lòng vào https://github.com/new tạo 1 repository mới (ví dụ: phoenix-oms)
    echo Sau đó sao chép link HTTPS (dạng: https://github.com/username/phoenix-oms.git)
    echo và dán vào bên dưới:
    echo -------------------------------------------------------------------------
    set /p REPO_URL=">> Nhập đường dẫn GitHub Repository của bạn: "
    if "%REPO_URL%"=="" (
        echo [LỖI] Bạn chưa nhập link GitHub!
        pause
        exit /b
    )
    git remote add origin %REPO_URL%
    echo [*] Đã liên kết với GitHub: %REPO_URL%
)

:: 4. Lấy mốc thời gian hiện tại
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (set MYDATE=%%a-%%b-%%c)
for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set MYTIME=%%a:%%b)

echo.
echo [*] Đang chuẩn bị tệp và cập nhật thay đổi mới nhất...
git add .

echo [*] Đang đóng gói commit với thời gian: %MYDATE% %MYTIME%...
git commit -m "feat: Auto update Phoenix OMS [%MYDATE% %MYTIME%]"

echo [*] Đang đẩy trực tiếp lên GitHub (git push)...
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo =========================================================================
    echo    [THÀNH CÔNG] ĐÃ ĐẨY MÃ NGUỒN MỚI LÊN GITHUB THÀNH CÔNG!
    echo.
    echo    Trang web Online trên GitHub Pages sẽ tự động cập nhật ngay lập tức.
    echo    Bạn chỉ cần mở link online và bấm F5 (hoặc vuốt xuống trên điện thoại)
    echo    là hệ thống sẽ chạy bản mới nhất 100%%!
    echo =========================================================================
) else (
    color 0E
    echo.
    echo [CẢNH BÁO] Chưa thể đẩy lên GitHub. Có thể bạn cần đăng nhập tài khoản
    echo GitHub khi cửa sổ đăng nhập hiện lên, hoặc kiểm tra lại quyền của Repository.
)

echo.
echo Bấm phím bất kỳ để thoát...
pause >nul
