#!/bin/bash

# Proton Manager - Gestionar múltiples versiones de Proton + Custom builds

PROTON_DIR="$HOME/.proton"
GE_DIR="$PROTON_DIR/ge-proton"
EXPERIMENTAL_DIR="$PROTON_DIR/experimental"
LOG_FILE="$HOME/.nexus-gaming/proton.log"

mkdir -p "$PROTON_DIR" "$GE_DIR" "$EXPERIMENTAL_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ===== PROTON-GE CUSTOM BUILD =====
install_proton_ge() {
    log "📥 Descargando Proton-GE Custom..."

    GE_LATEST=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | jq -r '.assets[] | select(.name | contains("tar.gz")) | .browser_download_url' | head -1)

    if [ -z "$GE_LATEST" ]; then
        log "❌ No se pudo obtener URL de Proton-GE"
        return 1
    fi

    cd "$GE_DIR"
    wget -q "$GE_LATEST" -O proton-ge.tar.gz

    if tar -tzf proton-ge.tar.gz &>/dev/null; then
        tar -xzf proton-ge.tar.gz
        rm proton-ge.tar.gz
        log "✅ Proton-GE instalado"
        ls -d Proton-* | head -1
    else
        log "❌ Descarga corrupta"
        return 1
    fi
}

# ===== PROTON EXPERIMENTAL =====
install_proton_experimental() {
    log "📥 Descargando Proton Experimental..."

    EXP_LATEST=$(curl -s https://api.github.com/repos/ValveSoftware/Proton/releases | jq -r '.[] | select(.tag_name | contains("experimental")) | .assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url' | head -1)

    if [ -z "$EXP_LATEST" ]; then
        log "❌ No se pudo obtener Proton Experimental"
        return 1
    fi

    cd "$EXPERIMENTAL_DIR"
    wget -q "$EXP_LATEST" -O proton-experimental.tar.gz
    tar -xzf proton-experimental.tar.gz
    rm proton-experimental.tar.gz
    log "✅ Proton Experimental instalado"
}

# ===== LISTAR VERSIONES INSTALADAS =====
list_proton_versions() {
    clear
    echo -e "\033[1;34m=== Versiones de Proton Instaladas ===${NC}"
    echo ""
    echo "Proton-GE Custom:"
    ls -d "$GE_DIR"/Proton-* 2>/dev/null | xargs -I {} basename {} || echo "  (ninguno)"
    echo ""
    echo "Proton Experimental:"
    ls -d "$EXPERIMENTAL_DIR"/Proton* 2>/dev/null | xargs -I {} basename {} || echo "  (ninguno)"
}

# ===== USAR VERSION ESPECIFICA =====
set_proton_version() {
    local game="$1"
    local version="$2"

    if [ -z "$game" ] || [ -z "$version" ]; then
        echo "Uso: proton-manager set <juego> <version>"
        return 1
    fi

    # Guardar en config
    echo "PROTON_VERSION=$version" >> "$HOME/.nexus-gaming/${game,,}_proton.env"
    log "✅ Proton $version asignado a $game"
}

# ===== MAIN =====
case "${1:-menu}" in
    install-ge)
        install_proton_ge
        ;;
    install-experimental)
        install_proton_experimental
        ;;
    list)
        list_proton_versions
        ;;
    set)
        set_proton_version "$2" "$3"
        ;;
    *)
        echo "Uso:"
        echo "  proton-manager install-ge         - Instalar Proton-GE"
        echo "  proton-manager install-experimental - Instalar Experimental"
        echo "  proton-manager list                - Listar versiones"
        echo "  proton-manager set <juego> <ver>  - Asignar versión a juego"
        ;;
esac
