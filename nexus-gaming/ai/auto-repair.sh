#!/bin/bash

# NexusCrashGuard - Game Auto-Repair System
# Detecta crashes, identifica archivos dañados, repara automáticamente

NEXUS_DIR="/opt/nexus-gaming"
CRASH_LOG="$HOME/.nexus-gaming/crashes.log"
REPAIR_LOG="$HOME/.nexus-gaming/repairs.log"

log_crash() {
    echo "[$(date)] Game: $1 | Exit Code: $2" >> "$CRASH_LOG"
}

log_repair() {
    echo "[$(date)] $1" >> "$REPAIR_LOG"
}

# ===== DETECTAR ARCHIVOS CORRUPTOS =====
detect_corrupted_files() {
    local game="$1"
    local game_path="$2"

    if [ ! -d "$game_path" ]; then
        echo "❌ Ruta de juego no encontrada: $game_path"
        return 1
    fi

    echo "🔍 Escaneando archivos dañados en: $game"

    # Buscar archivos con tamaños inusuales (señal de corrupción)
    corrupted=$(find "$game_path" -type f -size 0 2>/dev/null | wc -l)

    if [ "$corrupted" -gt 0 ]; then
        echo "⚠️ Encontrados $corrupted archivos vacíos (corruptos)"
        log_repair "Detectados $corrupted archivos vacíos en $game"
        return 0
    fi

    return 1
}

# ===== REPARAR A TRAVÉS DE STEAM =====
repair_via_steam() {
    local appid="$1"
    local game="$2"

    echo "🔧 Reparando a través de Steam Verify..."

    # Hacer backup
    steam_dir="$HOME/.steam/steam/steamapps/common/$game"
    backup_dir="$HOME/.nexus-gaming/backups/${game}_$(date +%s)"

    if [ -d "$steam_dir" ]; then
        mkdir -p "$backup_dir"
        cp -r "$steam_dir" "$backup_dir" &>/dev/null
        log_repair "Backup creado: $backup_dir"
    fi

    # Trigger Steam integrity check
    steam "steam://validate/$appid" 2>/dev/null &

    echo "⏳ Steam verificando archivos (verifica en Steam en 30s)"
    log_repair "Steam integrity check iniciado para AppID: $appid"
}

# ===== ANALIZAR LOG DE EVENTOS (LINUX) =====
analyze_event_log() {
    local game="$1"

    # Buscar crashes recientes en journalctl
    echo "📋 Buscando crashes recientes..."

    journalctl --since "2 hours ago" -p err 2>/dev/null | grep -i "segmentation\|illegal\|abort" | tail -5
}

# ===== MACHINE LEARNING CRASH DETECTION =====
predict_crash_pattern() {
    local game="$1"

    if [ ! -f "$CRASH_LOG" ]; then
        echo "No hay historial de crashes"
        return
    fi

    # Analizar patrones básicos
    crashes_today=$(grep "$(date +%Y-%m-%d)" "$CRASH_LOG" | wc -l)
    crashes_week=$(tail -100 "$CRASH_LOG" | wc -l)

    echo "📊 Análisis de patrones:"
    echo "  Crashes hoy: $crashes_today"
    echo "  Crashes última semana: $crashes_week"

    if [ "$crashes_today" -gt 3 ]; then
        echo "🚨 ALERTA: Múltiples crashes detectados"
        echo "   Recomendación: Verificar integridad de Steam"
        log_repair "ALERTA: Múltiples crashes en $game - recomendada verificación"
    fi
}

# ===== AUTOREPAIR LAUNCHER =====
launch_with_autorepair() {
    local game="$1"
    local exe_path="$2"

    echo "🛡️ Lanzando $game con AutoRepair activo..."

    # Crear wrapper que capture crashes
    if [ -z "$exe_path" ]; then
        echo "Lanzando desde Steam..."
        exec_cmd="steam run"
    else
        exec_cmd="$exe_path"
    fi

    # Ejecutar juego y capturar exit code
    $exec_cmd "$game"
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        echo "❌ Juego terminó con código: $EXIT_CODE"
        log_crash "$game" "$EXIT_CODE"

        # Trigger auto-repair
        echo ""
        echo "⚡ Iniciando reparación automática..."
        repair_via_steam "$game" "$game"
    else
        echo "✅ Juego terminó correctamente"
    fi
}

# ===== RESTORE FROM BACKUP =====
restore_backup() {
    local game="$1"
    local backup_dir="$HOME/.nexus-gaming/backups/${game}_*"

    latest_backup=$(ls -t "$backup_dir" 2>/dev/null | head -1)

    if [ -z "$latest_backup" ]; then
        echo "❌ No hay backups disponibles para $game"
        return 1
    fi

    echo "↩️ Restaurando desde: $latest_backup"

    game_install_dir="$HOME/.steam/steam/steamapps/common/$game"
    rm -rf "$game_install_dir"
    cp -r "$latest_backup" "$game_install_dir"

    log_repair "Restaurado backup para $game desde: $latest_backup"
    echo "✅ Restauración completa"
}

# ===== MAIN =====
case "${1:-help}" in
    detect)
        detect_corrupted_files "$2" "$3"
        ;;
    repair)
        repair_via_steam "$2" "$3"
        ;;
    analyze)
        analyze_event_log "$2"
        predict_crash_pattern "$2"
        ;;
    launch)
        launch_with_autorepair "$2" "$3"
        ;;
    restore)
        restore_backup "$2"
        ;;
    status)
        echo "=== Crash Statistics ==="
        [ -f "$CRASH_LOG" ] && echo "Total crashes: $(wc -l < "$CRASH_LOG")" || echo "No crashes recorded"
        [ -f "$REPAIR_LOG" ] && echo "Total repairs: $(wc -l < "$REPAIR_LOG")" || echo "No repairs recorded"
        ;;
    *)
        echo "NexusCrashGuard v1.0"
        echo ""
        echo "Uso:"
        echo "  auto-repair detect <juego> <ruta>      - Detectar archivos corruptos"
        echo "  auto-repair repair <appid> <juego>     - Reparar vía Steam"
        echo "  auto-repair analyze <juego>            - Analizar patrones de crash"
        echo "  auto-repair launch <juego> [exe]       - Lanzar con auto-repair"
        echo "  auto-repair restore <juego>            - Restaurar desde backup"
        echo "  auto-repair status                      - Ver estadísticas"
        ;;
esac
