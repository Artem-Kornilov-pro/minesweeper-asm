@echo off
cd /d "D:\Projects\minesweeper-asm"

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1

echo Компиляция minesweeper.asm...

ml64.exe /c minesweeper.asm

if %errorlevel% neq 0 (
    echo [ОШИБКА] Ошибка компиляции
    pause
    exit /b
)


link.exe minesweeper.obj /SUBSYSTEM:WINDOWS /ENTRY:main kernel32.lib user32.lib gdi32.lib ucrt.lib

if %errorlevel% equ 0 (
    echo [OK] Сапёр готов! Запускаю...
    minesweeper.exe
) else (
    echo [ОШИБКА] Ошибка линковки
)

pause