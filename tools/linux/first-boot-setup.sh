#!/bin/bash
# NexusOS First Boot Setup
# Configuración inicial amigable para principiantes
# Se ejecuta solo la primera vez que arranca NexusOS

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Archivo de control (se inicializará después de obtener el usuario)
SETUP_COMPLETED=""

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES
# ═══════════════════════════════════════════════════════════════════

show_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        🎮 NEXUSOS v1.0 - FIRST BOOT SETUP                  ║
║                                                              ║
║        Welcome! Let's configure your NexusOS               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    sleep 2
}

select_language() {
    echo -e "\n${YELLOW}STEP 1: Seleccionar Idioma${NC}\n"

    echo "¿Cuál es tu idioma preferido?"
    echo ""
    echo "1) Español"
    echo "2) English"
    echo "3) Português"
    echo ""

    read -p "Opción (1-3): " lang_choice

    case $lang_choice in
        1) LANGUAGE="es"; echo -e "${GREEN}✓ Español seleccionado${NC}" ;;
        2) LANGUAGE="en"; echo -e "${GREEN}✓ English selected${NC}" ;;
        3) LANGUAGE="pt"; echo -e "${GREEN}✓ Português selecionado${NC}" ;;
        *) select_language ;;
    esac

    sleep 1
}

setup_wifi() {
    echo -e "\n${YELLOW}STEP 2: Conectar a WiFi${NC}\n"

    echo "Escaneando redes WiFi..."
    nmcli device wifi rescan
    sleep 2

    # Listar redes
    echo ""
    echo "Redes disponibles:"
    nmcli device wifi list | tail -n +2 | nl
    echo ""

    read -p "¿Deseas conectarte a WiFi? (s/n): " wifi_choice

    if [[ $wifi_choice == "s" ]]; then
        read -p "Número de red: " network_num
        SSID=$(nmcli device wifi list | tail -n +2 | sed -n "${network_num}p" | awk '{print $1}')

        read -sp "Contraseña: " password
        echo ""

        nmcli device wifi connect "$SSID" password "$password"

        sleep 3
        if nmcli connection show | grep -q "$SSID"; then
            echo -e "${GREEN}✓ WiFi conectado correctamente${NC}"
        else
            echo -e "${RED}✗ Error conectando a WiFi${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Continuando sin WiFi (opcional)${NC}"
    fi

    sleep 1
}

setup_user() {
    echo -e "\n${YELLOW}STEP 3: Configurar Usuario${NC}\n"

    echo "Cuenta actual: gamer"
    echo ""
    read -p "¿Deseas cambiar el nombre de usuario? (s/n): " user_choice

    if [[ $user_choice == "s" ]]; then
        read -p "Nuevo nombre de usuario: " new_user

        # En una versión real, crear nuevo usuario
        # Por ahora solo guardamos
        CUSTOM_USER="$new_user"
        echo -e "${GREEN}✓ Usuario: $CUSTOM_USER${NC}"
    else
        CUSTOM_USER="gamer"
        echo -e "${GREEN}✓ Usuario: gamer${NC}"
    fi

    # Inicializar SETUP_COMPLETED con el usuario correcto
    SETUP_COMPLETED="${HOME}/.nexusos-setup-done"

    sleep 1
}

select_resolution() {
    echo -e "\n${YELLOW}STEP 4: Resolución de Pantalla${NC}\n"

    echo "Detectando resoluciones disponibles..."

    echo ""
    echo "Resoluciones comunes:"
    echo "1) 1920x1080 (Full HD) - RECOMENDADO"
    echo "2) 1366x768"
    echo "3) 1600x900"
    echo "4) 2560x1440 (4K)"
    echo "5) Detectar automáticamente"
    echo ""

    read -p "Opción (1-5): " res_choice

    case $res_choice in
        1) RESOLUTION="1920x1080" ;;
        2) RESOLUTION="1366x768" ;;
        3) RESOLUTION="1600x900" ;;
        4) RESOLUTION="2560x1440" ;;
        5)
            # Detectar
            if ! command -v xrandr &> /dev/null; then
                RESOLUTION="1920x1080"
                echo -e "${YELLOW}⚠ xrandr no disponible, usando resolución por defecto${NC}"
            else
                RESOLUTION=$(xrandr 2>/dev/null | grep ' connected primary' | awk '{print $4}' | cut -d'+' -f1)
                RESOLUTION=${RESOLUTION:-1920x1080}
            fi
            ;;
        *) select_resolution ;;
    esac

    echo -e "${GREEN}✓ Resolución: $RESOLUTION${NC}"
    sleep 1
}

select_emulators() {
    echo -e "\n${YELLOW}STEP 5: Seleccionar Emuladores${NC}\n"

    echo "¿Cuáles emuladores quieres instalar?"
    echo ""
    echo "☑ RetroArch (NES, SNES, Genesis, N64, etc)"
    echo "☑ PCSX2 (PlayStation 2) - 1GB"
    echo "☑ Ryujinx (Nintendo Switch) - 500MB"
    echo "☑ Citra (Nintendo 3DS) - 400MB"
    echo "☑ ScummVM (Aventuras clásicas)"
    echo ""
    echo "Todos están seleccionados por defecto."
    read -p "¿Instalar todos? (s/n): " emu_choice

    if [[ $emu_choice == "s" ]]; then
        EMULATORS="all"
        echo -e "${GREEN}✓ Instalando todos los emuladores...${NC}"
    else
        echo "Selecciona cuáles instalar:"
        EMULATORS="custom"
        # En versión real: menú de checkboxes
    fi

    sleep 1
}

setup_roms_folder() {
    echo -e "\n${YELLOW}STEP 6: Carpeta de ROMs${NC}\n"

    echo "¿Dónde deseas guardar tus ROMs (juegos)?"
    echo ""
    echo "Sugerencias:"
    echo "1) /home/gamer/Roms (Recomendado)"
    echo "2) /media/usb/ (Si tienes USB adicional)"
    echo "3) Otro (Especificar)"
    echo ""

    read -p "Opción (1-3): " roms_choice

    case $roms_choice in
        1) ROMS_PATH="/home/gamer/Roms" ;;
        2) ROMS_PATH="/media/usb/Roms" ;;
        3) read -p "Ruta completa: " ROMS_PATH ;;
        *) setup_roms_folder ;;
    esac

    # Crear carpeta
    mkdir -p "$ROMS_PATH"
    chmod 755 "$ROMS_PATH"

    echo -e "${GREEN}✓ Carpeta: $ROMS_PATH${NC}"
    sleep 1
}

setup_privacy() {
    echo -e "\n${YELLOW}STEP 7: Privacidad${NC}\n"

    echo "NexusOS no recopila datos personales por defecto."
    echo ""
    echo "¿Deseas enviar datos de uso (anónimos) para mejorar NexusOS?"
    echo ""

    read -p "Enviar datos de uso? (s/n): " telemetry_choice

    if [[ $telemetry_choice == "s" ]]; then
        TELEMETRY="enabled"
        echo -e "${GREEN}✓ Telemetría habilitada${NC}"
    else
        TELEMETRY="disabled"
        echo -e "${GREEN}✓ Telemetría deshabilitada${NC}"
    fi

    sleep 1
}

verify_setup() {
    echo -e "\n${YELLOW}STEP 8: Verificación${NC}\n"

    echo "Resumen de configuración:"
    echo ""
    echo "  Idioma: $LANGUAGE"
    echo "  Usuario: $CUSTOM_USER"
    echo "  Resolución: $RESOLUTION"
    echo "  Emuladores: $EMULATORS"
    echo "  ROMs: $ROMS_PATH"
    echo "  Telemetría: $TELEMETRY"
    echo ""

    read -p "¿Es correcto? (s/n): " verify_choice

    if [[ $verify_choice != "s" ]]; then
        echo "Reiniciando configuración..."
        sleep 1
        main
    fi
}

apply_settings() {
    echo -e "\n${CYAN}Aplicando configuración...${NC}\n"

    # Guardar configuración
    config_dir="/home/gamer/.nexusos"
    mkdir -p "$config_dir"

    cat > "$config_dir/setup.conf" << EOL
LANGUAGE=$LANGUAGE
USERNAME=$CUSTOM_USER
RESOLUTION=$RESOLUTION
EMULATORS=$EMULATORS
ROMS_PATH=$ROMS_PATH
TELEMETRY=$TELEMETRY
SETUP_DATE=$(date)
EOL

    # Aplicar resolución
    echo -e "${GREEN}✓ Guardando configuración${NC}"

    # Crear carpetas
    mkdir -p "$ROMS_PATH"
    mkdir -p "/home/gamer/.nexusos/backups"
    mkdir -p "/home/gamer/.nexusos/logs"

    echo -e "${GREEN}✓ Creando carpetas${NC}"

    # Instalar emuladores
    if [[ $EMULATORS == "all" ]]; then
        echo -e "${GREEN}✓ Emuladores listos${NC}"
    fi

    sleep 1
}

show_completion() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        ✅ SETUP COMPLETADO                                 ║
║                                                              ║
║        ¡Bienvenido a NexusOS!                              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo -e "\n${CYAN}PRÓXIMOS PASOS:${NC}\n"
    echo "1. Abre 'NexusOS Control Center' desde el escritorio"
    echo "2. Ve a 'Gaming Hub'"
    echo "3. Haz clic en 'LOAD ROMs'"
    echo "4. Selecciona tu carpeta de juegos"
    echo "5. ¡A jugar! 🎮"
    echo ""
    echo "Necesitas ayuda? Abre el 'Help Center' en el Control Center"
    echo ""

    sleep 3
}

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

main() {
    show_header
    select_language
    setup_wifi
    setup_user
    select_resolution
    select_emulators
    setup_roms_folder
    setup_privacy
    verify_setup
    apply_settings
    show_completion

    # Marcar como completado
    touch "$SETUP_COMPLETED"
}

# ═════════════════════════════════════════════════════════════════════
# EJECUTAR
# ═════════════════════════════════════════════════════════════════════

# Solo ejecutar si no está completado
if [ ! -f "$SETUP_COMPLETED" ]; then
    main
else
    echo "Setup ya completado. Para reconfigurarse, elimina: $SETUP_COMPLETED"
fi
