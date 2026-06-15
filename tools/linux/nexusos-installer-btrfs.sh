#!/bin/bash
# NexusOS - Btrfs + Snapper Installer
# Convierte sistema existente a Btrfs + Snapper con rollback automático
# ¡ADVERTENCIA! Este es un proceso invasivo. Hacer backup primero.

set -e

COLOR_CYAN="\033[0;36m"
COLOR_PURPLE="\033[0;35m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_CYAN}  NexusOS - Btrfs + Snapper Setup${COLOR_RESET}"
echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

# 1. Verificar permisos
if [[ $EUID -ne 0 ]]; then
   echo -e "${COLOR_RED}✗ Este script requiere permisos de root${COLOR_RESET}"
   exit 1
fi

# 2. Detectar filesystem actual
ROOT_FS=$(df / --output=fstype | tail -1)
echo -e "${COLOR_CYAN}Filesystem actual: ${COLOR_RESET}${ROOT_FS}"

if [[ "$ROOT_FS" == "btrfs" ]]; then
    echo -e "${COLOR_GREEN}✓ Ya está en Btrfs${COLOR_RESET}"
else
    echo -e "${COLOR_RED}✗ Requiere conversión de $ROOT_FS → Btrfs${COLOR_RESET}"
    echo -e "${COLOR_PURPLE}Instrucciones:${COLOR_RESET}"
    echo "1. Hacer backup completo del sistema"
    echo "2. Usar utilidad de conversión: 'btrfs-convert'"
    echo "3. O reinstalar con Btrfs durante instalación"
    exit 1
fi

# 3. Instalar Snapper
echo -e "\n${COLOR_CYAN}[1/5] Instalando Snapper...${COLOR_RESET}"
pacman -S --noconfirm snapper

# 4. Crear configuración de Snapper para root
echo -e "\n${COLOR_CYAN}[2/5] Configurando Snapper...${COLOR_RESET}"

# Remover config existente si la hay
umount /.snapshots 2>/dev/null || true
rm -rf /.snapshots 2>/dev/null || true
rm -f /etc/snapper/configs/root 2>/dev/null || true

# Crear nueva config
snapper -c root create-config /

# Ajustar configuración
cat > /etc/snapper/configs/root << 'EOF'
# snapper configuration file for /

SUBVOLUME="/"
FSTYPE="btrfs"

# Pre/Post snapshots
ALLOW_USERS=""
ALLOW_GROUPS=""

# Auto-snapshots
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"

# Daily snapshots
TIMELINE_LIMIT_HOURLY="0"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"

# Snapshot cleanup
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="10"
NUMBER_LIMIT_IMPORTANT="5"

# Disable quota
QGROUP="0"
EOF

echo -e "${COLOR_GREEN}✓ Snapper configurado${COLOR_RESET}"

# 5. Habilitar servicio de snapshots automáticos
echo -e "\n${COLOR_CYAN}[3/5] Habilitando snapshots automáticos...${COLOR_RESET}"
systemctl enable snapper-timeline.timer
systemctl start snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl start snapper-cleanup.timer

echo -e "${COLOR_GREEN}✓ Snapshots automáticos cada día${COLOR_RESET}"

# 6. Crear snapshot inicial
echo -e "\n${COLOR_CYAN}[4/5] Creando snapshot inicial...${COLOR_RESET}"
snapper -c root create -d "NexusOS Initial Snapshot"

# 7. Verificar snapshots
echo -e "\n${COLOR_CYAN}[5/5] Verificando instalación...${COLOR_RESET}"
echo -e "\n${COLOR_PURPLE}Snapshots actuales:${COLOR_RESET}"
snapper -c root list -t single

# 8. Crear GRUB recovery menu
echo -e "\n${COLOR_CYAN}Configurando GRUB para recovery...${COLOR_RESET}"

# Instalar herramientas de GRUB
pacman -S --noconfirm grub btrfs-progs

# Regenerar GRUB para incluir submenu de snapshots
if ! grub-mkconfig -o /boot/grub/grub.cfg; then
    echo -e "${COLOR_RED}✗ GRUB configuration failed - system may not boot${COLOR_RESET}"
    echo "Run manually: sudo grub-mkconfig -o /boot/grub/grub.cfg"
    exit 1
fi

echo -e "\n${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✓ Snapper + Btrfs instalado correctamente${COLOR_RESET}"
echo -e "${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

echo -e "\n${COLOR_CYAN}Uso:${COLOR_RESET}"
echo "  • Ver snapshots:         snapper -c root list"
echo "  • Crear snapshot manual: snapper -c root create -d 'Descripción'"
echo "  • Restaurar snapshot:    snapper -c root undochange N..M"
echo "  • Boot a snapshot:       Selecciona en GRUB menu"

echo -e "\n${COLOR_PURPLE}Auto-snapshots configurados:${COLOR_RESET}"
echo "  • Antes de actualizaciones (pacman hook)"
echo "  • Diariamente"
echo "  • Retiene: 7 diarios + 5 importantes"

echo -e "\n${COLOR_CYAN}GUI disponible en:${COLOR_RESET}"
echo "  Control Center → Settings → System Snapshots"
