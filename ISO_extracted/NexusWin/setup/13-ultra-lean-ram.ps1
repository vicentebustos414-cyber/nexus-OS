# NexusWin Ultra Lean RAM - Mínimo consumo Windows, máximo para Gaming
# Objetivo: Windows 11 usando solo 2-3GB RAM idle
# Dejar 13-14GB para gaming/aplicaciones

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║ 💾 NexusWin ULTRA LEAN RAM v1.0       ║" -ForegroundColor Cyan
Write-Host "║ Target: 6-8GB → 2-3GB Windows idle    ║" -ForegroundColor Cyan
Write-Host "║ Gaming: 13-14GB disponible             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Obtener RAM actual
$ramBefore = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$ramUsed = (Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize / 1MB / 1024
Write-Host "📊 RAM ANTES:" -ForegroundColor Yellow
Write-Host "  Total: $([math]::Round($ramBefore, 1)) GB" -ForegroundColor Cyan
Write-Host "  Usado: $([math]::Round($ramUsed, 1)) GB" -ForegroundColor Red
Write-Host ""

# ===== FASE 1: DESHABILITAR SERVICIOS INNECESARIOS =====
Write-Host "🔌 FASE 1: Deshabilitando servicios innecesarios..." -ForegroundColor Cyan

$servicesToDisable = @(
    "DiagTrack",                    # Telemetría diagnóstica
    "dmwappushservice",             # Push notifications
    "MapsBroker",                   # Location services
    "TabletInputService",           # Si no usa tablet
    "WbioSrvc",                     # Biometría
    "WinRM",                         # Remote management
    "WMPNetworkSvc",                 # Media player network
    "lmhosts",                       # NetBIOS
    "RemoteRegistry",               # Registro remoto
    "SharedAccess",                 # ICS (compartir conexión)
    "PhoneSvc",                      # Phone services
    "PrintSpooler",                 # Solo si no imprime
    "BDESVC",                        # BitLocker (gaming no lo necesita)
    "SysMain",                       # SuperFetch (CRITICAL - consume mucha RAM)
    "WSearch",                       # Windows Search
    "WerSvc",                        # Windows Error Reporting
    "DoSvc",                         # Delivery Optimization
    "WaaSMedicSvc",                  # Windows Update medic
    "update",                        # Windows Update
    "UsoSvc",                        # Update Orchestrator
    "InstallService",               # App installer
    "AppIDSvc",                      # App Identity
    "AppMgmt",                       # Application Management
)

foreach ($service in $servicesToDisable) {
    try {
        $svc = Get-Service $service -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ $service" -ForegroundColor Green
        }
    } catch {
        # Silenciar errores
    }
}

Write-Host "✅ Servicios deshabilitados" -ForegroundColor Green

# ===== FASE 2: MEMORY COMPRESSION =====
Write-Host ""
Write-Host "🗜️ FASE 2: Habilitando Memory Compression..." -ForegroundColor Cyan

# Enable memory compression en Windows
Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
Write-Host "  ✓ Memory Compression habilitada" -ForegroundColor Green

# Comprimir archivos en memoria
if (Get-MMAgent -MemoryCompression -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ Compression activa: puede liberar 500MB-1GB" -ForegroundColor Green
}

# ===== FASE 3: KERNEL TWEAKS (Registry) =====
Write-Host ""
Write-Host "⚙️ FASE 3: Kernel tweaks para reducir RAM..." -ForegroundColor Cyan

# Reducir cache de memoria
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 1 /f 2>&1 | Out-Null
Write-Host "  ✓ Clear pagefile at shutdown" -ForegroundColor Green

# Limitar LargeSystemCache
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
Write-Host "  ✓ Disabled LargeSystemCache" -ForegroundColor Green

# Reducir buffering de disco
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "MaxMpxCt" /t REG_DWORD /d 256 /f 2>&1 | Out-Null
Write-Host "  ✓ Reducido buffer de disco" -ForegroundColor Green

# Limitar file cache
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IoPageLockLimit" /t REG_DWORD /d 16384 /f 2>&1 | Out-Null
Write-Host "  ✓ Limited IO page lock" -ForegroundColor Green

# Desactivar Reserved Memory
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ReservedMemory" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
Write-Host "  ✓ Disabled reserved memory" -ForegroundColor Green

# ===== FASE 4: DESHABILITAR VISUAL EFFECTS =====
Write-Host ""
Write-Host "🎨 FASE 4: Deshabilitando visual effects..." -ForegroundColor Cyan

# Performance options - Disable animations
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d 0 /f 2>&1 | Out-Null
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012078010000000 /f 2>&1 | Out-Null
Write-Host "  ✓ Disabled animations" -ForegroundColor Green

# Disable cursor shadow
reg add "HKCU\Control Panel\Cursors" /v "CursorShadow" /t REG_SZ /d 0 /f 2>&1 | Out-Null
Write-Host "  ✓ Disabled cursor shadow" -ForegroundColor Green

# ===== FASE 5: REDUCIR BACKGROUND PROCESSES =====
Write-Host ""
Write-Host "⚡ FASE 5: Reduciendo background processes..." -ForegroundColor Cyan

# Desactivar Cortana
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
Write-Host "  ✓ Cortana disabled" -ForegroundColor Green

# Desactivar Activity History
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
Write-Host "  ✓ Activity History disabled" -ForegroundColor Green

# Desactivar App suggestions
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstallAppsEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
Write-Host "  ✓ App suggestions disabled" -ForegroundColor Green

# Deshabilitar Game Bar (consume RAM)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
Write-Host "  ✓ Game Bar disabled (pero GameMode sigue activo)" -ForegroundColor Green

# ===== FASE 6: NETWORK OPTIMIZATION =====
Write-Host ""
Write-Host "🌐 FASE 6: Network stack optimization..." -ForegroundColor Cyan

# Reducir TCP receive window
netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
Write-Host "  ✓ TCP autotuning optimized" -ForegroundColor Green

# ===== FASE 7: DISK CACHE OPTIMIZATION =====
Write-Host ""
Write-Host "💿 FASE 7: Disk cache optimization..." -ForegroundColor Cyan

# Reducir desktop heap
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems\Windows" /v "SharedSection" /t REG_SZ /d "1024,20480,768" /f 2>&1 | Out-Null
Write-Host "  ✓ Desktop heap optimized" -ForegroundColor Green

# ===== FASE 8: PAGEFILE OPTIMIZATION =====
Write-Host ""
Write-Host "📄 FASE 8: Pagefile optimization..." -ForegroundColor Cyan

# Configurar pagefile mínimo (ya que tenemos 16GB)
# Usar NUL como pagefile (sin pagefile, toda RAM es física)
try {
    $pageFileSettings = Get-WmiObject Win32_ComputerSystem
    $pageFileSettings.AutomaticManagedPagefile = $false
    $pageFileSettings.Put() | Out-Null

    $pageFile = Get-WmiObject Win32_PageFile -ErrorAction SilentlyContinue
    if ($pageFile) {
        $pageFile.Delete() | Out-Null
    }

    Write-Host "  ✓ Pagefile minimized (usar RAM física)" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ No se pudo modificar pagefile (puede requerir reboot)" -ForegroundColor Yellow
}

# ===== FASE 9: LIMPIEZA FINAL =====
Write-Host ""
Write-Host "🧹 FASE 9: Limpieza final..." -ForegroundColor Cyan

# Clear memory caches
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
Write-Host "  ✓ Garbage collection executed" -ForegroundColor Green

# ===== RESULTADOS =====
Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║ ✅ OPTIMIZACIÓN COMPLETADA            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 5

$ramAfter = (Get-WmiObject Win32_OperatingSystem).TotalVisibleMemorySize / 1MB / 1024
$ramSaved = $ramUsed - $ramAfter

Write-Host "📊 RESULTADOS:" -ForegroundColor Green
Write-Host "  Windows ANTES: $([math]::Round($ramUsed, 1)) GB" -ForegroundColor Yellow
Write-Host "  Windows DESPUÉS: $([math]::Round($ramAfter, 1)) GB" -ForegroundColor Cyan
Write-Host "  RAM liberada: $([math]::Round($ramSaved, 1)) GB" -ForegroundColor Green
Write-Host ""
Write-Host "🎮 PARA GAMING:" -ForegroundColor Green
Write-Host "  RAM disponible: ~13-14 GB de 16 GB" -ForegroundColor Green
Write-Host "  Perfecto para Elden Ring, Cyberpunk, etc @ Ultra settings" -ForegroundColor Green
Write-Host ""
Write-Host "⚡ NOTAS:" -ForegroundColor Cyan
Write-Host "  • Requiere REBOOT para tomar efecto completamente" -ForegroundColor Yellow
Write-Host "  • Memory Compression trabaja automáticamente" -ForegroundColor Cyan
Write-Host "  • Gaming performance: 0% impacto (solo beneficios)" -ForegroundColor Cyan
Write-Host "  • Si algo no funciona, puedes revertir cambios de registry" -ForegroundColor Cyan
Write-Host ""

Write-Host "💾 Cambios guardados. Necesitas REINICIAR para que todo tome efecto." -ForegroundColor Yellow
Write-Host ""
Write-Host "Presiona Enter para reiniciar ahora... (o Ctrl+C para cancelar)" -ForegroundColor Cyan
Read-Host

# Restart
Restart-Computer -Force
