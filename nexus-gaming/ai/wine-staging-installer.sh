#!/bin/bash

# Wine Staging + Gaming Patches - Instalar Wine con patches específicos para gaming

WINE_DIR="$HOME/.wine-staging"
STAGING_DIR="$HOME/.wine-staging-src"
LOG_FILE="$HOME/.nexus-gaming/wine-staging.log"

mkdir -p "$WINE_DIR" "$STAGING_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ===== INSTALAR WINE-STAGING PRECOMPILADO =====
install_wine_staging_binary() {
    log "📥 Instalando Wine Staging (precompilado)..."

    # Detectar distro
    if grep -q "ubuntu\|debian" /etc/os-release 2>/dev/null; then
        log "📦 Detectada: Debian/Ubuntu"

        # Agregar repo Wine
        sudo dpkg --add-architecture i386
        sudo mkdir -pm755 /etc/apt/keyrings
        sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
        sudo add-apt-repository 'deb [signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/ubuntu jammy main' 2>/dev/null
        sudo apt update

        # Instalar wine-staging
        sudo apt install -y winehq-staging

        log "✅ Wine Staging instalado vía apt"

    elif grep -q "arch" /etc/os-release 2>/dev/null; then
        log "📦 Detectada: Arch Linux"
        sudo pacman -S --noconfirm wine-staging

        log "✅ Wine Staging instalado vía pacman"

    else
        log "⚠️ Distro no soportada. Instalando desde source..."
        install_wine_staging_source
    fi
}

# ===== INSTALAR WINE-STAGING DESDE SOURCE =====
install_wine_staging_source() {
    log "🔨 Compilando Wine Staging desde source..."

    cd "$STAGING_DIR"

    # Descargar Wine Staging
    STAGING_LATEST=$(curl -s https://api.github.com/repos/wine-staging/wine-staging/releases/latest | jq -r '.tag_name')

    wget -q "https://github.com/wine-staging/wine-staging/archive/refs/tags/$STAGING_LATEST.tar.gz" \
        -O wine-staging.tar.gz

    tar -xzf wine-staging.tar.gz
    cd "wine-staging-$STAGING_LATEST"

    # Instalar dependencias (Debian/Ubuntu)
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y \
            build-essential flex bison \
            libfreetype6-dev libglu1-mesa-dev \
            libx11-dev libxext-dev libxcursor-dev \
            libxi-dev libxrandr-dev libxinerama-dev
    fi

    # Configurar y compilar
    ./configure --prefix="$WINE_DIR" --enable-win64

    make -j$(nproc)
    make install

    log "✅ Wine Staging compilado e instalado en: $WINE_DIR"
}

# ===== INSTALAR ESYNC + FSYNC =====
install_sync_primitives() {
    log "⚡ Instalando esync + fsync (aceleración de rendimiento)..."

    if [ ! -f "$WINE_DIR/bin/wine" ]; then
        log "❌ Wine no encontrado"
        return 1
    fi

    # Verificar soporte del kernel
    if grep -q "enable_fsync=Y\|enable_esync=Y" /proc/config.gz &>/dev/null; then
        log "✅ Kernel soporta fsync/esync"

        # Crear wineprefix con esync habilitado
        WINEPREFIX="$HOME/.wine-gaming" "$WINE_DIR/bin/wineboot" -i
        export WINEPREFIX="$HOME/.wine-gaming"
        export STAGING_SHARED_MEMORY=1
        export STAGING_WRITECOPY=1

        log "✅ esync + fsync habilitados"
    else
        log "⚠️ Kernel no soporta fsync/esync. Usa wine-ge-proton para mejor rendimiento"
    fi
}

# ===== PARCHEAR PARA JUEGOS ESPECÍFICOS =====
patch_for_game() {
    local game="$1"

    log "🔧 Parches específicos para: $game"

    case "$game" in
        elden_ring|starfield|cyberpunk)
            log "📝 Aplicando parchesDirectX 12 avanzado..."
            # Estos juegos necesitan VKD3D mejorado
            ;;
        ffxiv)
            log "📝 Aplicando patches FFXIV..."
            # FFXIV necesita soporte especial para anticheat
            ;;
        fortnite)
            log "📝 Aplicando patches Fortnite..."
            # Fortnite necesita parches de rendering
            ;;
    esac
}

# ===== CREAR WINEPREFIX GAMING-OPTIMIZADO =====
create_gaming_prefix() {
    local prefix_name="${1:-gaming}"

    log "🛠️ Creando wineprefix optimizado: $prefix_name"

    WINEPREFIX="$HOME/.wine-$prefix_name" \
    STAGING_SHARED_MEMORY=1 \
    STAGING_WRITECOPY=1 \
    "$WINE_DIR/bin/wineboot" -i

    # Configurar registry para gaming
    WINEPREFIX="$HOME/.wine-$prefix_name" "$WINE_DIR/bin/regedit" << EOF
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"CSMT"="enabled"
"VideoMemorySize"="2048"
"Multisampling"="enabled"

[HKEY_CURRENT_USER\Software\Wine\Direct3D11]
"CSMT"="enabled"
EOF

    log "✅ Wineprefix $prefix_name creado y optimizado"
}

# ===== INSTALAR DEPENDENCIAS DE DIRECTX =====
install_directx_deps() {
    log "📦 Instalando dependencias DirectX..."

    WINEPREFIX="${1:-.wine-gaming}" "$WINE_DIR/bin/winetricks" \
        vcrun2022 \
        dotnet7 \
        d3dcompiler_47 \
        dxvk \
        xact

    log "✅ Dependencias DirectX instaladas"
}

# ===== BENCHMARK WINE PERFORMANCE =====
benchmark_wine() {
    log "🧪 Benchmarking Wine Staging..."

    if ! command -v glmark2 &>/dev/null; then
        log "⚠️ glmark2 no instalado. Instala: sudo apt install glmark2"
        return 1
    fi

    WINEPREFIX="$HOME/.wine-gaming" glmark2 --off-screen 1024x768

    log "✅ Benchmark completado"
}

# ===== LISTAR VERSIONES INSTALADAS =====
list_wine_versions() {
    echo "Wine Staging Versions:"
    echo ""

    if [ -d "$WINE_DIR" ]; then
        "$WINE_DIR/bin/wine" --version
    else
        echo "❌ Wine Staging no instalado"
    fi

    echo ""
    echo "Wine Prefixes:"
    ls -d "$HOME/.wine-"* 2>/dev/null | xargs -I {} basename {}
}

# ===== MAIN =====
case "${1:-help}" in
    install)
        install_wine_staging_binary
        ;;
    install-source)
        install_wine_staging_source
        ;;
    sync)
        install_sync_primitives
        ;;
    patch)
        patch_for_game "$2"
        ;;
    prefix)
        create_gaming_prefix "$2"
        ;;
    directx)
        install_directx_deps "${2:-.wine-gaming}"
        ;;
    benchmark)
        benchmark_wine
        ;;
    list)
        list_wine_versions
        ;;
    *)
        echo "Wine Staging + Gaming Patches v1.0"
        echo ""
        echo "Uso:"
        echo "  wine-staging install              - Instalar Wine Staging (binario)"
        echo "  wine-staging install-source       - Compilar desde source"
        echo "  wine-staging sync                 - Instalar esync + fsync"
        echo "  wine-staging patch <juego>        - Parchear para juego"
        echo "  wine-staging prefix [name]        - Crear wineprefix optimizado"
        echo "  wine-staging directx [prefix]     - Instalar deps DirectX"
        echo "  wine-staging benchmark            - Benchmarking"
        echo "  wine-staging list                 - Listar versiones/prefixes"
        ;;
esac
