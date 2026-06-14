@echo off
REM Compilar NexusOS Installer a .exe
REM Requiere: PyInstaller

echo ╔════════════════════════════════════════╗
echo ║  NexusOS Installer Builder             ║
echo ╚════════════════════════════════════════╝
echo.

REM Instalar dependencias
echo [1/4] Instalando dependencias...
pip install PySimpleGUI psutil -q
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: No se pudieron instalar dependencias
    pause
    exit /b 1
)

REM Instalar PyInstaller
echo [2/4] Instalando PyInstaller...
pip install pyinstaller -q
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PyInstaller no se instalo
    pause
    exit /b 1
)

REM Compilar
echo [3/4] Compilando nexusos_installer.py...
pyinstaller nexusos_installer.py ^
    --onefile ^
    --windowed ^
    --name "NexusOS_Installer" ^
    --icon=nexusos.ico ^
    --add-data "nexusos.ico;." ^
    --distpath "../../dist" ^
    --buildpath "./build" ^
    --specpath "./specs"

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Compilacion fallida
    pause
    exit /b 1
)

REM Verificar
echo [4/4] Verificando...
if exist "..\..\dist\NexusOS_Installer.exe" (
    echo.
    echo ✓ SUCCESS! NexusOS_Installer.exe creado
    echo Ubicacion: ..\..\dist\NexusOS_Installer.exe
    echo Tamaño: ~50MB
    echo.
) else (
    echo ERROR: El .exe no se creo
    pause
    exit /b 1
)

echo.
echo ═══════════════════════════════════════════
echo Instalador listo para distribuir
echo ═══════════════════════════════════════════
echo.
pause
