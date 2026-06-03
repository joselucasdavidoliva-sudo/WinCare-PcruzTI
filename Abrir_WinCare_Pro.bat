@echo off
title WinCare Pro — Iniciando...
color 0B

echo.
echo  ================================
echo   WinCare Pro v1.0 - Iniciando
echo  ================================
echo.

:: Verifica se PowerShell está disponível
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] PowerShell não encontrado!
    pause
    exit /b 1
)

:: Obtém o diretório do .bat
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%WinCare.ps1"

:: Verifica se o script existe
if not exist "%PS_SCRIPT%" (
    echo [ERRO] WinCare.ps1 não encontrado em: %SCRIPT_DIR%
    pause
    exit /b 1
)

echo  Iniciando com privilegios de Administrador...
echo.

:: Lança PowerShell com elevação
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PS_SCRIPT%""' -Verb RunAs"

exit /b 0
