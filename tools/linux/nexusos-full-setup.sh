#!/bin/bash
# NexusOS - Full Setup Installer
# Instala y configura todo automáticamente:
# 1. Snapper + Btrfs (System Snapshots)
# 2. Driver Manager (Auto GPU detection)
# 3. Timeshift (Automatic backups)

set -e

COLOR_CYAN="\033[0;36m"
COLOR_PURPLE="\033[0;35m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_CYAN}     NexusOS - Complete System Setup${COLOR_RESET}"
echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
   echo -e "${COLOR_RED}✗ Este script requiere permisos de root${COLOR_RESET}"
   echo "Ejecutar: sudo bash $0"
   exit 1
fi

# Menú de selección
echo -e "\n${COLOR_PURPLE}¿Qué componentes instalar?${COLOR_RESET}"
echo "1) Todo (Snapper + Driver Manager + Timeshift)"
echo "2) Solo Snapper + Driver Manager"
echo "3) Solo Driver Manager"
echo "4) Solo Timeshift"
echo ""
read -p "Selecciona (1-4): " choice

# Actualizar sistema primero
echo -e "\n${COLOR_CYAN}[Paso 0/3] Actualizando sistema...${COLOR_RESET}"
pacman -Syu --noconfirm

case $choice in
    1)
        # Todo
        echo -e "\n${COLOR_CYAN}[Paso 1/3] Instalando Snapper + Btrfs...${COLOR_RESET}"
        bash "$SCRIPT_DIR/nexusos-installer-btrfs.sh"

        echo -e "\n${COLOR_CYAN}[Paso 2/3] Instalando Driver Manager...${COLOR_RESET}"
        bash "$SCRIPT_DIR/driver-manager.sh"

        echo -e "\n${COLOR_CYAN}[Paso 3/3] Instalando Timeshift...${COLOR_RESET}"
        bash "$SCRIPT_DIR/timeshift-setup.sh"
        ;;
    2)
        # Snapper + Driver Manager
        echo -e "\n${COLOR_CYAN}[Paso 1/2] Instalando Snapper...${COLOR_RESET}"
        bash "$SCRIPT_DIR/nexusos-installer-btrfs.sh"

        echo -e "\n${COLOR_CYAN}[Paso 2/2] Instalando Driver Manager...${COLOR_RESET}"
        bash "$SCRIPT_DIR/driver-manager.sh"
        ;;
    3)
        # Solo Driver Manager
        echo -e "\n${COLOR_CYAN}[Paso 1/1] Instalando Driver Manager...${COLOR_RESET}"
        bash "$SCRIPT_DIR/driver-manager.sh"
        ;;
    4)
        # Solo Timeshift
        echo -e "\n${COLOR_CYAN}[Paso 1/1] Instalando Timeshift...${COLOR_RESET}"
        bash "$SCRIPT_DIR/timeshift-setup.sh"
        ;;
    *)
        echo -e "${COLOR_RED}Opción inválida${COLOR_RESET}"
        exit 1
        ;;
esac

# Resumen final
echo -e "\n${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✓ Setup completado exitosamente${COLOR_RESET}"
echo -e "${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

echo -e "\n${COLOR_CYAN}Sistema Recovery instalado:${COLOR_RESET}"
echo "  📸 Snapshots: Snapper (rollback rápido)"
echo "  📁 Backups: Timeshift (restauración completa)"
echo "  🎮 Drivers: Auto-detectados e instalados"

echo -e "\n${COLOR_PURPLE}Acceder desde:${COLOR_RESET}"
echo "  • Control Center → Settings → System Recovery"
echo "  • O: sudo timeshift-launcher"

echo -e "\n${COLOR_YELLOW}Próximos pasos:${COLOR_RESET}"
if [[ "$choice" == "1" || "$choice" == "3" ]]; then
    echo "  1. Reiniciar sistema: reboot"
    echo "  2. Verificar drivers: nvidia-smi (si es Nvidia)"
fi

echo -e "\n${COLOR_CYAN}Documentación:${COLOR_RESET}"
echo "  • Snapper: man snapper"
echo "  • Timeshift: timeshift --help"
echo "  • Drivers: lspci -v"
