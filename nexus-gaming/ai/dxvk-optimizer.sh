#!/bin/bash

# DXVK/VKD3D Optimizer - Optimizar DirectX emulation por GPU vendor

NEXUS_DIR="/opt/nexus-gaming"
CONFIG_DIR="$HOME/.nexus-gaming"
DXVK_DIR="$HOME/.dxvk"

mkdir -p "$DXVK_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$CONFIG_DIR/dxvk.log"
}

# ===== DETECTAR GPU =====
detect_gpu() {
    if command -v nvidia-smi &>/dev/null; then
        GPU_VENDOR="nvidia"
        GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader)
        VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader)
    else
        GPU_VENDOR="amd"
        GPU_MODEL=$(lspci | grep -i "vga\|3d" | cut -d: -f3 | head -1)
        VRAM="unknown"
    fi

    log "🎮 GPU detectada: $GPU_VENDOR | $GPU_MODEL | $VRAM"
}

# ===== INSTALAR DXVK ÚLTIMA VERSIÓN =====
install_dxvk() {
    log "📥 Instalando DXVK (Direct3D en Vulkan)..."

    DXVK_LATEST=$(curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | jq -r '.tag_name')

    if [ -z "$DXVK_LATEST" ]; then
        log "❌ No se pudo obtener DXVK"
        return 1
    fi

    cd "$DXVK_DIR"
    wget -q "https://github.com/doitsujin/dxvk/releases/download/$DXVK_LATEST/dxvk-$DXVK_LATEST.tar.gz" \
        -O dxvk.tar.gz

    if tar -tzf dxvk.tar.gz &>/dev/null; then
        tar -xzf dxvk.tar.gz
        rm dxvk.tar.gz
        log "✅ DXVK $DXVK_LATEST instalado"
    else
        log "❌ Descarga corrupta"
        return 1
    fi
}

# ===== INSTALAR VKD3D (Direct3D 12) =====
install_vkd3d() {
    log "📥 Instalando VKD3D (Direct3D 12 en Vulkan)..."

    VKD3D_LATEST=$(curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | jq -r '.tag_name')

    if [ -z "$VKD3D_LATEST" ]; then
        log "❌ No se pudo obtener VKD3D"
        return 1
    fi

    cd "$DXVK_DIR"
    wget -q "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/$VKD3D_LATEST/vkd3d-proton-$VKD3D_LATEST.tar.zst" \
        -O vkd3d.tar.zst

    if command -v tar &>/dev/null; then
        tar -xf vkd3d.tar.zst
        rm vkd3d.tar.zst
        log "✅ VKD3D $VKD3D_LATEST instalado"
    else
        log "❌ zstd no disponible"
        return 1
    fi
}

# ===== OPTIMIZACIÓN NVIDIA =====
optimize_nvidia() {
    log "🟢 Optimizando para NVIDIA..."

    # Heap size para VRAM grande
    VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | grep -o '^[0-9]*')

    if [ "$VRAM_MB" -gt 8000 ]; then
        HEAP_SIZE="8192"  # 8GB heap
    elif [ "$VRAM_MB" -gt 4000 ]; then
        HEAP_SIZE="4096"  # 4GB heap
    else
        HEAP_SIZE="2048"  # 2GB heap
    fi

    cat > "$CONFIG_DIR/dxvk-nvidia.conf" << EOF
# DXVK Config - NVIDIA Optimization
dxvk.enableDeviceDebug = false
dxvk.hud = off

# Memory optimization
dxvk.nvapiDll = nvapi64.dll,nvapi.dll

# DirectX 12 optimizations
dxvk.forceDeviceDriver = nvidia

# Performance tuning
dxvk.transientImageCount = 4

# Enable NVIDIA specific extensions
dxvk.enableNvapi = true

# Heap size: ${HEAP_SIZE}MB
dxvk.forceShaderDumpPath = ${HEAP_SIZE}
EOF

    log "✅ Configuración NVIDIA optimizada (heap: ${HEAP_SIZE}MB)"
}

# ===== OPTIMIZACIÓN AMD =====
optimize_amd() {
    log "🔴 Optimizando para AMD..."

    cat > "$CONFIG_DIR/dxvk-amd.conf" << EOF
# DXVK Config - AMD RADV Optimization
dxvk.enableDeviceDebug = false

# RADV specific
vk.amdgpu = true
radv.perftest = all

# ACO compiler (faster than LLVM)
radv.compiler = aco

# Memory optimization
dxvk.enableRawAccessChains = true

# DirectX 9 & 11 optimizations
dxvk.dxvk9 = true
dxvk.enableShaderModuleIdentifier = true

# Performance
dxvk.transientImageCount = 4
EOF

    log "✅ Configuración AMD RADV optimizada (ACO compiler)"
}

# ===== CONFIGURAR PARA JUEGO ESPECÍFICO =====
optimize_game() {
    local game="$1"

    log "🎮 Creando config optimizada para: $game"

    detect_gpu

    if [ "$GPU_VENDOR" = "nvidia" ]; then
        config_file="$CONFIG_DIR/${game,,}_dxvk.conf"

        cat > "$config_file" << EOF
# $game - NVIDIA DXVK Config
dxvk.hud = off
dxvk.enableDeviceDebug = false
dxvk.dxvk9 = true

# Async shader compilation
dxvk.enableAsyncCompilation = true

# Memory settings
dxvk.transientImageCount = 4

# DLSS/Tensor support
dxvk.enableRawAccessChains = true

# Frame rate target
dxvk.maxFrameRate = 0

# Debugging (enable solo si es necesario)
# dxvk.hud = fps,memory
EOF

        log "✅ Config NVIDIA para $game creada"

    else
        config_file="$CONFIG_DIR/${game,,}_dxvk.conf"

        cat > "$config_file" << EOF
# $game - AMD RADV Config
radv.perftest = all
radv.compiler = aco

dxvk.enableDeviceDebug = false
dxvk.enableAsyncCompilation = true
dxvk.transientImageCount = 4
dxvk.enableRawAccessChains = true

# ACO es más rápido que LLVM
EOF

        log "✅ Config AMD para $game creada"
    fi

    echo "Ubicación: $config_file"
}

# ===== VKD3D PARA DIRECTX 12 =====
enable_vkd3d_game() {
    local game="$1"

    log "📀 Habilitando VKD3D para $game (DirectX 12)..."

    vkd3d_conf="$CONFIG_DIR/${game,,}_vkd3d.conf"

    cat > "$vkd3d_conf" << EOF
# VKD3D Config - DirectX 12 via Vulkan
# Para juegos que usan DirectX 12 (Starfield, Cyberpunk, etc.)

[environment]
VKD3D_SHADER_CACHE_PATH=$HOME/.cache/vkd3d
VKD3D_DEBUG=none

# Feature levels
VKD3D_FEATURE_LEVEL=12_1

# Performance
VKD3D_CONFIG=dxil_shader_model_6,virtual_sgpr_count=40
EOF

    log "✅ VKD3D habilitado para $game"
}

# ===== TEST PERFORMANCE =====
test_dxvk_performance() {
    log "🧪 Testeando rendimiento DXVK..."

    if ! command -v glxinfo &>/dev/null; then
        echo "⚠️ glxinfo no disponible (install mesa-utils)"
        return 1
    fi

    echo "Vulkan Info:"
    vulkaninfo 2>/dev/null | grep -i "device\|driver\|version" | head -10

    echo ""
    echo "GPU Load:"
    if [ "$GPU_VENDOR" = "nvidia" ]; then
        nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader
    else
        echo "AMD: instala radeontop para monitoreo"
    fi
}

# ===== MAIN =====
case "${1:-help}" in
    install)
        detect_gpu
        install_dxvk
        install_vkd3d
        ;;
    optimize-nvidia)
        optimize_nvidia
        ;;
    optimize-amd)
        optimize_amd
        ;;
    game)
        optimize_game "$2"
        ;;
    vkd3d)
        enable_vkd3d_game "$2"
        ;;
    test)
        test_dxvk_performance
        ;;
    *)
        echo "DXVK/VKD3D Optimizer v1.0"
        echo ""
        echo "Uso:"
        echo "  dxvk-optimizer install              - Instalar DXVK + VKD3D"
        echo "  dxvk-optimizer optimize-nvidia      - Optimizar para NVIDIA"
        echo "  dxvk-optimizer optimize-amd         - Optimizar para AMD"
        echo "  dxvk-optimizer game <nombre>        - Crear config para juego"
        echo "  dxvk-optimizer vkd3d <juego>        - Habilitar DirectX 12"
        echo "  dxvk-optimizer test                 - Test performance"
        ;;
esac
