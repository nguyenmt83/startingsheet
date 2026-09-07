@echo off
chcp 65001 >nul
title PHOENIX GOLF OMS - TỰ ĐỘNG THEO DÕI VÀ ĐẨY LÊN GITHUB
color 0B

echo =========================================================================
echo    PHOENIX CV GOLF & RESORT - SMART STARTING OMS v3.0
echo    CHẾ ĐỘ TỰ ĐỘNG THEO DÕI & ĐẨY LÊN GITHUB (LIVE AUTO-SYNC)
echo =========================================================================
echo.
echo Đang kích hoạt chế độ tự động theo dõi file...
echo Bất cứ khi nào bạn hoặc trợ lý sửa file, hệ thống sẽ TỰ ĐỘNG đẩy lên GitHub!
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0watch_auto_push.ps1"
pause
