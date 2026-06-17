#!/bin/bash

# Lutris Installer - Descargar e instalar 1000+ scripts de juegos preconfigurados

LUTRIS_DIR="$HOME/.local/share/lutris"
SCRIPTS_DIR="$LUTRIS_DIR/scripts"
LOG_FILE="$HOME/.nexus-gaming/lutris.log"

mkdir -p "$SCRIPTS_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ===== INSTALAR LUTRIS =====
install_lutris() {
    log "📥 Instalando Lutris..."

    if grep -q "ubuntu\|debian" /etc/os-release 2>/dev/null; then
        sudo add-apt-repository ppa:lutris-team/lutris -y 2>/dev/null
        sudo apt update
        sudo apt install -y lutris

        log "✅ Lutris instalado vía PPA"

    elif grep -q "arch" /etc/os-release 2>/dev/null; then
        sudo pacman -S --noconfirm lutris

        log "✅ Lutris instalado vía pacman"

    elif grep -q "fedora" /etc/os-release 2>/dev/null; then
        sudo dnf install -y lutris

        log "✅ Lutris instalado vía dnf"

    else
        log "⚠️ Distro no soportada. Instala Lutris manualmente"
        return 1
    fi
}

# ===== DESCARGAR TODOS LOS SCRIPTS DE LUTRIS API =====
download_all_lutris_scripts() {
    log "📥 Descargando 1000+ scripts de Lutris API..."

    # Lutris API endpoint para juegos
    API_BASE="https://lutris.net/api/games"

    local page=1
    local total_scripts=0

    while [ $page -le 100 ]; do
        log "📄 Página $page..."

        # Fetchear página de juegos
        response=$(curl -s "${API_BASE}?page=$page&limit=50&filter=installed")

        # Extraer detalles de cada juego
        games=$(echo "$response" | jq -r '.results[] | "\(.id)|\(.name)|\(.slug)"' 2>/dev/null)

        if [ -z "$games" ]; then
            log "✅ Todas las páginas descargadas"
            break
        fi

        echo "$games" | while IFS='|' read -r game_id game_name game_slug; do
            log "🎮 Descargando script: $game_name"

            # Descargar installer script
            installer_url="https://lutris.net/api/games/$game_slug/versions/latest/installer"

            curl -s "$installer_url" -o "$SCRIPTS_DIR/${game_slug}.yml" 2>/dev/null

            if [ -f "$SCRIPTS_DIR/${game_slug}.yml" ]; then
                ((total_scripts++))
            fi
        done

        ((page++))
        sleep 0.5  # Rate limiting
    done

    log "✅ Descargados $total_scripts scripts"
}

# ===== DESCARGAR POPULAR GAMES SCRIPTS =====
download_popular_games() {
    log "📥 Descargando scripts de juegos populares..."

    # Top gaming titles
    local games=(
        "elden-ring"
        "cyberpunk-2077"
        "baldurs-gate-3"
        "starfield"
        "final-fantasy-xiv"
        "fortnite"
        "world-of-warcraft"
        "minecraft"
        "factorio"
        "stardew-valley"
        "helldivers-2"
        "palworld"
        "the-witcher-3"
        "red-dead-redemption-2"
        "gta-v"
    )

    local downloaded=0

    for game in "${games[@]}"; do
        log "🎮 Descargando: $game"

        curl -s "https://lutris.net/api/games/$game/versions/latest/installer" \
            -o "$SCRIPTS_DIR/${game}.yml" 2>/dev/null

        if [ -f "$SCRIPTS_DIR/${game}.yml" ] && [ -s "$SCRIPTS_DIR/${game}.yml" ]; then
            ((downloaded++))
        else
            log "⚠️ No encontrado: $game"
        fi

        sleep 0.2
    done

    log "✅ Descargados $downloaded scripts populares"
}

# ===== INSTALAR JUEGO DESDE SCRIPT LUTRIS =====
install_game_from_lutris() {
    local game_slug="$1"

    log "🎮 Instalando desde Lutris: $game_slug"

    if ! command -v lutris &>/dev/null; then
        log "❌ Lutris no instalado"
        install_lutris
    fi

    # Usar Lutris CLI para instalar
    lutris lutris:$game_slug &

    log "Instalación iniciada en Lutris. Verifica la UI de Lutris"
}

# ===== LISTAR SCRIPTS DISPONIBLES =====
list_available_scripts() {
    clear
    echo "📋 Scripts de Lutris Disponibles:"
    echo "═════════════════════════════════"
    echo ""

    if [ ! -d "$SCRIPTS_DIR" ] || [ -z "$(ls -A $SCRIPTS_DIR)" ]; then
        echo "❌ No hay scripts descargados"
        echo "Usa: lutris-installer download-popular"
        return
    fi

    local count=0
    ls "$SCRIPTS_DIR" | while read script; do
        game_name=$(echo "$script" | sed 's/.yml$//' | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
        echo "  ✓ $game_name"

        ((count++))
        if [ $((count % 5)) -eq 0 ]; then
            echo ""
        fi
    done

    echo ""
    echo "Total: $(ls "$SCRIPTS_DIR" | wc -l) scripts"
}

# ===== SYNC SCRIPTS DESDE REPOSITORIO EXTERNO =====
sync_scripts_from_repo() {
    log "🔄 Sincronizando scripts desde repositorio..."

    # Repositorio comunitario de Lutris
    REPO="https://github.com/lutris/lutris/raw/master/share/lutris/runners"

    # Descargar wine runners, proton, etc.
    curl -s "${REPO}/wine-ge/latest.yml" -o "$SCRIPTS_DIR/wine-ge-latest.yml"
    curl -s "${REPO}/proton/latest.yml" -o "$SCRIPTS_DIR/proton-latest.yml"

    log "✅ Scripts sincronizados"
}

# ===== CREAR SCRIPT PERSONALIZADO PARA JUEGO =====
create_custom_script() {
    local game="$1"
    local exe_path="$2"

    log "📝 Creando script personalizado para: $game"

    cat > "$SCRIPTS_DIR/${game,,}-custom.yml" << EOF
name: $game
description: Custom script for $game
game_slug: ${game,,}
version: Custom

runners:
  - proton

game:
  exe: $exe_path
  prefix: ~/.wine-gaming

env:
  STAGING_SHARED_MEMORY: 1
  STAGING_WRITECOPY: 1
  DXVK_ASYNC: 1

system:
  pulse_latency_msec: 10
  gamemode: true
  esync: true
  fsync: true
EOF

    log "✅ Script personalizado creado: $SCRIPTS_DIR/${game,,}-custom.yml"
}

# ===== BACKUP DE SCRIPTS =====
backup_scripts() {
    log "💾 Haciendo backup de scripts..."

    backup_file="$HOME/.nexus-gaming/lutris-scripts-backup-$(date +%Y%m%d).tar.gz"

    tar -czf "$backup_file" "$SCRIPTS_DIR" 2>/dev/null

    log "✅ Backup creado: $backup_file"
}

# ===== SEARCH SCRIPT =====
search_game_script() {
    local query="$1"

    echo "🔍 Buscando scripts para: $query"
    echo ""

    ls "$SCRIPTS_DIR" | grep -i "$query" | while read script; do
        game=$(echo "$script" | sed 's/.yml$//' | tr '-' ' ')
        echo "  ✓ $game"
    done
}

# ===== MAIN =====
case "${1:-help}" in
    install)
        install_lutris
        ;;
    download-all)
        download_all_lutris_scripts
        ;;
    download-popular)
        download_popular_games
        ;;
    install-game)
        install_game_from_lutris "$2"
        ;;
    list)
        list_available_scripts
        ;;
    sync)
        sync_scripts_from_repo
        ;;
    custom)
        create_custom_script "$2" "$3"
        ;;
    backup)
        backup_scripts
        ;;
    search)
        search_game_script "$2"
        ;;
    *)
        echo "Lutris Script Manager v1.0"
        echo ""
        echo "Uso:"
        echo "  lutris-installer install                - Instalar Lutris"
        echo "  lutris-installer download-popular       - Descargar juegos populares"
        echo "  lutris-installer download-all           - Descargar TODOS los scripts"
        echo "  lutris-installer list                   - Listar scripts disponibles"
        echo "  lutris-installer search <juego>         - Buscar script"
        echo "  lutris-installer install-game <slug>    - Instalar juego desde script"
        echo "  lutris-installer custom <juego> <exe>   - Script personalizado"
        echo "  lutris-installer sync                   - Sincronizar desde repo"
        echo "  lutris-installer backup                 - Hacer backup de scripts"
        ;;
esac
