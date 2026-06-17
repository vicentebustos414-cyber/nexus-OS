#!/bin/bash

# NexusOS Gaming Launcher - One-click game management
# Integrated with AI, Compatibility DB, and Community Ratings

NEXUS_DIR="/opt/nexus-gaming"
CACHE_DIR="$HOME/.cache/nexus-gaming"
CONFIG_DIR="$HOME/.config/nexus-gaming"

mkdir -p "$CACHE_DIR" "$CONFIG_DIR"

# ===== FUNCTIONS =====
show_menu() {
    clear
    echo -e "\033[1;34m"
    echo "╔════════════════════════════════════════╗"
    echo "║   🎮 NexusOS Gaming Launcher 1.0      ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo ""
    echo "1) 🔍 Buscar juego"
    echo "2) ⚡ Predecir performance"
    echo "3) 🎯 Optimizar juego"
    echo "4) 🚀 Lanzar con configuración"
    echo "5) ⭐ Ver ratings de comunidad"
    echo "6) 💻 Información de hardware"
    echo "7) 📊 Estadísticas de compatibilidad"
    echo "8) ⚙️  Configuración avanzada"
    echo "9) ❌ Salir"
    echo ""
}

search_game_interactive() {
    read -p "Ingresa nombre del juego: " game
    /opt/nexus-gaming/bin/nexus-ai search "$game"
    read -p "Presiona Enter para continuar..."
}

predict_interactive() {
    read -p "Ingresa nombre del juego: " game
    /opt/nexus-gaming/bin/nexus-ai predict "$game"
    read -p "Presiona Enter para continuar..."
}

optimize_interactive() {
    read -p "Ingresa nombre del juego: " game
    /opt/nexus-gaming/bin/nexus-ai optimize "$game"
    echo ""
    echo "Archivo de configuración creado en:"
    echo "$HOME/.nexus-gaming/${game,,}_proton.env"
    read -p "Presiona Enter para continuar..."
}

launch_interactive() {
    read -p "Ingresa nombre del juego: " game
    read -p "Ingresa ruta del ejecutable (Enter si es en Steam): " exe_path

    /opt/nexus-gaming/bin/nexus-ai launch "$game" "$exe_path"

    read -p "Presiona Enter para continuar..."
}

show_community_ratings() {
    clear
    echo -e "\033[1;35m"
    echo "╔════════════════════════════════════════╗"
    echo "║   ⭐ Ratings de la Comunidad          ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo ""

    jq -r '.leaderboard.mostCompatible[] | "  ✅ \(.game): \(.rating)⭐"' \
        /opt/nexus-gaming/db/community/ratings.json

    echo ""
    echo "Top Rendimiento:"
    jq -r '.leaderboard.bestPerformance[] | "  🚀 \(.game): \(.avgFps) FPS"' \
        /opt/nexus-gaming/db/community/ratings.json

    echo ""
    echo "Incompatibles:"
    jq -r '.leaderboard.worstCompatibility[] | "  ❌ \(.game)"' \
        /opt/nexus-gaming/db/community/ratings.json

    read -p "Presiona Enter para continuar..."
}

show_hardware() {
    clear
    echo -e "\033[1;33m"
    echo "╔════════════════════════════════════════╗"
    echo "║   💻 Tu Hardware                       ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo ""

    /opt/nexus-gaming/bin/nexus-ai hardware

    read -p "Presiona Enter para continuar..."
}

show_stats() {
    clear
    echo -e "\033[1;36m"
    echo "╔════════════════════════════════════════╗"
    echo "║   📊 Estadísticas Globales             ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo ""

    jq -r '.statsOverall | "Total Juegos: \(.totalGames)\nTotal Compatible: \(.fullyCompatible)\nCompatibilidad Promedio: \(.avgCompatibilityRating)⭐"' \
        /opt/nexus-gaming/db/community/ratings.json

    read -p "Presiona Enter para continuar..."
}

advanced_config() {
    clear
    echo -e "\033[1;31m"
    echo "╔════════════════════════════════════════╗"
    echo "║   ⚙️  Configuración Avanzada           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo ""
    echo "1) Editar configuración Proton"
    echo "2) Actualizar base de datos de juegos"
    echo "3) Sincronizar ratings de comunidad"
    echo "4) Limpiar caché"
    echo "5) Ver logs"
    echo "6) Volver"
    echo ""

    read -p "Opción: " adv_opt

    case $adv_opt in
        1)
            nano "$HOME/.nexus-gaming/proton.conf" 2>/dev/null || \
            nano "$HOME/.config/nexus-gaming/proton.env"
            ;;
        2)
            echo "Descargando base de datos actualizada..."
            # git pull en /opt/nexus-gaming
            ;;
        3)
            echo "Sincronizando ratings..."
            # curl actualización de ratings.json
            ;;
        4)
            rm -rf "$CACHE_DIR"/*
            echo "✅ Caché limpiado"
            ;;
        5)
            tail -f "$HOME/.nexus-gaming/nexus-ai.log"
            ;;
    esac
}

# ===== MAIN LOOP =====
while true; do
    show_menu
    read -p "Selecciona opción: " choice

    case $choice in
        1) search_game_interactive ;;
        2) predict_interactive ;;
        3) optimize_interactive ;;
        4) launch_interactive ;;
        5) show_community_ratings ;;
        6) show_hardware ;;
        7) show_stats ;;
        8) advanced_config ;;
        9)
            echo "Hasta luego! 🎮"
            exit 0
            ;;
        *)
            echo "Opción inválida"
            sleep 1
            ;;
    esac
done
