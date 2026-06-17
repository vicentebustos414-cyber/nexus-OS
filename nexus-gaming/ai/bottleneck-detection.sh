#!/bin/bash

# Bottleneck Detection - Identifica si tu hardware es insuficiente para un juego
# Análisis inteligente: CPU vs GPU bottleneck

NEXUS_DIR="/opt/nexus-gaming"
DB_FILE="$NEXUS_DIR/db/games.json"
CONFIG_DIR="$HOME/.nexus-gaming"
BOTTLENECK_LOG="$CONFIG_DIR/bottleneck.log"

# ===== OBTENER SPECS ACTUALES =====
get_current_specs() {
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    CPU_CORES=$(lscpu | grep "^CPU(s)" | awk '{print $2}')
    RAM_GB=$(free -h | grep Mem | awk '{print $2}' | sed 's/G//')

    # GPU Nvidia
    if command -v nvidia-smi &>/dev/null; then
        GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader)
        VRAM_GB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | sed 's/ MB//' | awk '{printf "%.1f", $1/1024}')
        GPU_VENDOR="nvidia"
    else
        GPU_MODEL=$(lspci | grep -i "vga\|3d" | cut -d: -f3 | head -1)
        VRAM_GB="unknown"
        GPU_VENDOR="amd"
    fi

    echo "CPU: $CPU_MODEL ($CPU_CORES cores)"
    echo "RAM: ${RAM_GB}GB"
    echo "GPU: $GPU_MODEL (${VRAM_GB}GB)"
}

# ===== ANALIZAR BOTTLENECK PARA JUEGO =====
analyze_bottleneck() {
    local game="$1"
    local target_fps="${2:-60}"

    echo "🔍 Analizando bottleneck para: $game @ ${target_fps}FPS"

    # Obtener specs del juego
    game_data=$(jq -r ".games[] | select(.name | test(\"$game\"; \"i\")) | ." "$DB_FILE" 2>/dev/null)

    if [ -z "$game_data" ]; then
        echo "❌ Juego no encontrado en base de datos"
        return 1
    fi

    # Extraer requisitos recomendados
    rec_cpu=$(echo "$game_data" | jq -r '.recommendedSpecs.cpu // "unknown"')
    rec_gpu=$(echo "$game_data" | jq -r '.recommendedSpecs.gpu // "unknown"')
    rec_ram=$(echo "$game_data" | jq -r '.recommendedSpecs.ram // 16' | sed 's/GB//')
    rec_vram=$(echo "$game_data" | jq -r '.recommendedSpecs.vram // 8' | sed 's/GB//')

    echo ""
    echo "📊 ANÁLISIS DE BOTTLENECK:"
    echo "═════════════════════════════"

    # ===== CPU BOTTLENECK =====
    cpu_bottleneck=0
    if [ "$CPU_CORES" -lt 4 ]; then
        echo "🔴 CPU CRÍTICO: Menos de 4 cores"
        echo "   Recomendado: $rec_cpu"
        cpu_bottleneck=100
    elif [ "$CPU_CORES" -lt 8 ]; then
        echo "🟡 CPU BAJO: 4-8 cores"
        cpu_bottleneck=50
    else
        echo "🟢 CPU OK: 8+ cores"
        cpu_bottleneck=0
    fi

    # ===== GPU BOTTLENECK =====
    gpu_bottleneck=0
    vram_gb=$(echo "$VRAM_GB" | grep -o '^[0-9]*')

    if [ -z "$vram_gb" ] || [ "$vram_gb" -lt "$((rec_vram / 2))" ]; then
        echo "🔴 GPU CRÍTICO: VRAM insuficiente"
        echo "   Tienes: ${VRAM_GB}GB | Recomendado: ${rec_vram}GB"
        gpu_bottleneck=100
    elif [ "$vram_gb" -lt "$rec_vram" ]; then
        echo "🟡 GPU BAJO: VRAM por debajo de lo recomendado"
        gpu_bottleneck=50
    else
        echo "🟢 GPU OK: VRAM suficiente"
        gpu_bottleneck=0
    fi

    # ===== RAM BOTTLENECK =====
    ram_gb=$(echo "$RAM_GB" | grep -o '^[0-9]*')

    if [ "$ram_gb" -lt 8 ]; then
        echo "🔴 RAM CRÍTICO: Menos de 8GB"
        echo "   Tienes: ${RAM_GB}GB | Recomendado: ${rec_ram}GB"
    elif [ "$ram_gb" -lt "$rec_ram" ]; then
        echo "🟡 RAM BAJO: Por debajo de lo recomendado"
    else
        echo "🟢 RAM OK"
    fi

    echo ""
    echo "═════════════════════════════"

    # ===== VEREDICTO =====
    total_bottleneck=$(( (cpu_bottleneck + gpu_bottleneck) / 2 ))

    if [ $total_bottleneck -eq 0 ]; then
        echo "✅ VEREDICTO: Hardware SUFICIENTE"
        echo "   Deberías lograr $target_fps FPS en settings recomendados"
    elif [ $total_bottleneck -lt 75 ]; then
        echo "⚠️ VEREDICTO: Hardware MARGINAL"
        echo "   Podrías lograr $target_fps FPS con settings BAJOS/MEDIOS"
        echo "   Botella: $([ $cpu_bottleneck -gt $gpu_bottleneck ] && echo "CPU" || echo "GPU")"
    else
        echo "❌ VEREDICTO: Hardware INSUFICIENTE"
        echo "   Posiblemente NO llegues a $target_fps FPS"
        echo "   Botella crítica: $([ $cpu_bottleneck -eq 100 ] && echo "CPU" || echo "GPU")"
    fi

    # ===== RECOMENDACIONES =====
    echo ""
    echo "💡 RECOMENDACIONES:"

    if [ $cpu_bottleneck -gt 0 ]; then
        echo "  • CPU: Busca Ryzen 5 5600X o Intel i7-11700K"
    fi

    if [ $gpu_bottleneck -gt 0 ]; then
        echo "  • GPU: Busca RTX 3070 Ti o RX 6800 XT"
    fi

    echo "  • Reduce settings: Low/Medium en lugar de Ultra"
    echo "  • Baja resolución: 1440p en lugar de 4K"
    echo "  • Desactiva ray-tracing si es muy lento"

    # Log
    log_bottleneck "$game" "$target_fps" "$total_bottleneck" "$cpu_bottleneck" "$gpu_bottleneck"
}

# ===== LOGGING =====
log_bottleneck() {
    echo "[$(date)] Game: $1 @ ${2}FPS | Total: ${3}% | CPU: ${4}% | GPU: ${5}%" >> "$BOTTLENECK_LOG"
}

# ===== COMPARATIVA CON OTROS JUEGOS =====
compare_games() {
    clear
    echo "📋 Comparativa de bottleneck para juegos comunes:"
    echo ""

    for game in "elden ring" "cyberpunk 2077" "baldurs gate 3" "fortnite"; do
        echo -n "$game: "
        analyze_bottleneck "$game" 60 2>/dev/null | grep "VEREDICTO" | sed 's/^.*: //'
    done
}

# ===== MAIN =====
case "${1:-help}" in
    analyze)
        get_current_specs
        echo ""
        analyze_bottleneck "$2" "${3:-60}"
        ;;
    compare)
        get_current_specs
        echo ""
        compare_games
        ;;
    specs)
        get_current_specs
        ;;
    *)
        echo "Bottleneck Detector v1.0"
        echo ""
        echo "Uso:"
        echo "  bottleneck-detection analyze <juego> [fps]  - Analizar juego"
        echo "  bottleneck-detection compare                - Comparar múltiples juegos"
        echo "  bottleneck-detection specs                  - Ver tus specs"
        echo ""
        echo "Ejemplo:"
        echo "  bottleneck-detection analyze cyberpunk 60"
        echo "  bottleneck-detection analyze elden_ring 120"
        ;;
esac
