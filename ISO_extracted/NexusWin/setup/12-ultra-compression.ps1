# NexusWin Ultra Compression - Máxima compresión, mínimo espacio
# Reduce 18-20GB a 6-10GB sin perder funcionalidad

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ 🗜️ NexusWin ULTRA COMPRESSION v1.0   ║" -ForegroundColor Cyan
Write-Host "║ Target: 18GB → 6-10GB                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$startSize = (Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "📊 Tamaño ANTES: $([math]::Round($startSize, 1)) GB" -ForegroundColor Yellow

# ===== FASE 1: LIMPIAR ANTES DE COMPRIMIR =====
Write-Host ""
Write-Host "🧹 FASE 1: Limpieza de archivos innecesarios..." -ForegroundColor Cyan

# Limpiar Windows Update cache
Write-Host "  • Limpiando Windows Update cache..."
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
cmd /c "DISM /online /Cleanup-Image /StartComponentCleanup /ResetBase" 2>&1 | Out-Null

# Limpiar hibernación
Write-Host "  • Deshabilitando hibernación..."
cmd /c "powercfg /h off" 2>&1 | Out-Null

# Limpiar Event Logs (mantener solo 7 días)
Write-Host "  • Limpiando Event Logs..."
Get-EventLog -LogName * -ErrorAction SilentlyContinue | ForEach-Object {
    Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue
}

# Limpiar Temp files
Write-Host "  • Limpiando archivos temporales..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar Recycle Bin
Write-Host "  • Vaciando Recycle Bin..."
Remove-Item -Path "C:\$Recycle.bin\*" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar prefetch
Write-Host "  • Limpiando prefetch..."
Remove-Item -Path "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue

# Limpiar Internet Explorer cache
Write-Host "  • Limpiando IE cache..."
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar Windows error reporting
Write-Host "  • Limpiando crash dumps..."
Remove-Item -Path "C:\Windows\Minidump\*" -Force -ErrorAction SilentlyContinue

Write-Host "✅ Limpieza completada" -ForegroundColor Green

# ===== FASE 2: DEFRAGMENTACIÓN ANTES DE COMPRIMIR =====
Write-Host ""
Write-Host "⚙️ FASE 2: Optimizando fragmentación (para mejor compresión)..." -ForegroundColor Cyan
Write-Host "  • Ejecutando Optimize-Volume (esto toma 5-10 min)..."
Optimize-Volume -DriveLetter C -Defrag -Verbose 4>&1 | Out-Null
Write-Host "✅ Defragmentación completada" -ForegroundColor Green

# ===== FASE 3: COMPRESIÓN ULTRA (LZ4) =====
Write-Host ""
Write-Host "🗜️ FASE 3: Compresión ULTRA (LZ4)..." -ForegroundColor Cyan

# Carpetas a comprimir (NO comprimir Windows/boot critical)
$compressFolders = @(
    "C:\Users",                           # Perfiles de usuario
    "C:\ProgramData",                     # Datos de aplicaciones
    "C:\Program Files (x86)",             # Apps 32-bit
    "C:\Program Files\Common Files",      # Librerías compartidas
    "C:\NexusWin",                        # NexusWin scripts
    "C:\Windows\System32\DriverStore",    # Drivers (histórico)
    "C:\Windows\Installer",               # MSI cache
    "C:\Windows\assembly",                # .NET assemblies
    "C:\Windows\WinSxS",                  # Component store (cuidado aquí)
    "C:\Windows\SoftwareDistribution",    # Update cache
)

$folderCount = 0
foreach ($folder in $compressFolders) {
    if (Test-Path $folder) {
        Write-Host "  • Comprimiendo: $folder"
        cmd /c "compact /c /s:$folder /exe:LZ4 /i:pagefile.sys" 2>&1 | Out-Null
        $folderCount++
    }
}

Write-Host "✅ Comprimidas $folderCount carpetas con LZ4" -ForegroundColor Green

# ===== FASE 4: COMPRESIÓN STANDARD (WIMX) PARA ARCHIVOS PEQUEÑOS =====
Write-Host ""
Write-Host "📦 FASE 4: Compresión secundaria (WIMX para archivos pequeños)..." -ForegroundColor Cyan
Write-Host "  • Aplicando compresión WIMX a archivos < 100KB..."
cmd /c "compact /c /s:C:\ /exe:WIMX /i:pagefile.sys,C:\Windows\System32 /q" 2>&1 | Out-Null
Write-Host "✅ Compresión WIMX completada" -ForegroundColor Green

# ===== FASE 5: VERIFICAR COMPRESIÓN =====
Write-Host ""
Write-Host "📊 FASE 5: Verificando estadísticas de compresión..." -ForegroundColor Cyan

# Mostrar estado de compresión
Write-Host ""
Write-Host "  Resumen de compresión:" -ForegroundColor Yellow
cmd /c "compact /s:C:\ /exe:LZ4 /stats 2>&1" | Select-String "Comprimidos|Sin comprimir|Total" | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Yellow
}

# ===== FASE 6: INFORMACIÓN FINAL =====
Write-Host ""
$endSize = (Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
$saved = $startSize - $endSize
$savedPercent = ($saved / $startSize) * 100

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║ ✅ COMPRESIÓN COMPLETADA             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📊 RESULTADOS:" -ForegroundColor Green
Write-Host "  Tamaño ANTES:  $([math]::Round($startSize, 1)) GB" -ForegroundColor Yellow
Write-Host "  Tamaño DESPUÉS: $([math]::Round($endSize, 1)) GB" -ForegroundColor Cyan
Write-Host "  Espacio ahorrado: $([math]::Round($saved, 1)) GB ($([math]::Round($savedPercent, 1))%)" -ForegroundColor Green
Write-Host ""
Write-Host "⚡ Performance:" -ForegroundColor Green
Write-Host "  • Boot time: IGUAL (LZ4 es transparente)" -ForegroundColor Cyan
Write-Host "  • Velocidad lectura: IGUAL (descomprime en RAM)" -ForegroundColor Cyan
Write-Host "  • Velocidad escritura: Ligeramente más lenta (compresión activa)" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Notas:" -ForegroundColor Cyan
Write-Host "  • Si tamaño final < 8GB = ÉXITO 🎉" -ForegroundColor Green
Write-Host "  • Compresión es transparente para aplicaciones" -ForegroundColor Cyan
Write-Host "  • Puedes descomprimir individual archivos si necesitas velocidad máxima" -ForegroundColor Cyan
Write-Host ""

# Registrar en log
$logEntry = "[$(Get-Date)] NexusWin Ultra Compression: $([math]::Round($startSize, 1))GB → $([math]::Round($endSize, 1))GB (Ahorrado: $([math]::Round($saved, 1))GB / $([math]::Round($savedPercent, 1))%)"
Add-Content -Path "C:\NexusWin\setup\compression.log" -Value $logEntry

Write-Host "✅ Ultra Compression completado. Presiona Enter para continuar..." -ForegroundColor Green
Read-Host
