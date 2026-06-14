#!/bin/bash
# NexusOS - Timeshift Backup Setup
# Configura backups automáticos diarios del sistema

set -e

COLOR_CYAN="\033[0;36m"
COLOR_PURPLE="\033[0;35m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_CYAN}  NexusOS - Timeshift Backup Setup${COLOR_RESET}"
echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
   echo -e "${COLOR_RED}✗ Este script requiere permisos de root${COLOR_RESET}"
   exit 1
fi

# 1. Instalar Timeshift
echo -e "\n${COLOR_CYAN}[1/5] Instalando Timeshift...${COLOR_RESET}"
pacman -S --noconfirm timeshift

echo -e "${COLOR_GREEN}✓ Timeshift instalado${COLOR_RESET}"

# 2. Detectar partición más grande (para almacenar backups)
echo -e "\n${COLOR_CYAN}[2/5] Detectando almacenamiento...${COLOR_RESET}"

# Buscar partición más grande que no sea root
BACKUP_DISK=$(lsblk -l -o NAME,TYPE,MOUNTPOINT,SIZE | grep disk | awk '{print $1}' | head -1)
if [ -z "$BACKUP_DISK" ]; then
    BACKUP_DISK="/home"
fi

echo -e "${COLOR_YELLOW}Almacenamiento de backups: $BACKUP_DISK${COLOR_RESET}"

# 3. Crear estructura de directorios
echo -e "\n${COLOR_CYAN}[3/5] Creando directorios de backup...${COLOR_RESET}"

BACKUP_DIR="/timeshift/backups"
mkdir -p $BACKUP_DIR

echo -e "${COLOR_GREEN}✓ Directorio creado: $BACKUP_DIR${COLOR_RESET}"

# 4. Crear configuración de Timeshift
echo -e "\n${COLOR_CYAN}[4/5] Configurando Timeshift...${COLOR_RESET}"

cat > /etc/timeshift/timeshift.json << 'EOF'
{
  "btrfs_mode": false,
  "check_boot_partition": true,
  "check_root_partition": true,
  "custom_cron_expr": "0 0 * * *",
  "exclude": [
    "/dev",
    "/proc",
    "/sys",
    "/tmp",
    "/run",
    "/mnt",
    "/media",
    "/var/log",
    "/var/cache",
    "/var/tmp",
    "/home/*/.cache",
    "/home/*/.local/share/Trash"
  ],
  "exclude_from_rsync": [
    "- /dev",
    "- /proc",
    "- /sys",
    "- /tmp",
    "- /run",
    "- /mnt",
    "- /media"
  ],
  "exclude_pidgin_config": false,
  "skip_grub": false,
  "skip_grub_i386": true,
  "gvfs_metadata": true,
  "include_btrfs_home_subvolumes": false,
  "include_btrfs_system_subvolumes": false,
  "notify": true,
  "snapshot_levels": "5:7:4-2",
  "snapshot_size": 2000,
  "app_version": "21.09.1",
  "schedule_monthly": false,
  "schedule_weekly": false,
  "schedule_daily": true,
  "schedule_hourly": false,
  "schedule_boot": false,
  "user_aware": true,
  "versioning": true
}
EOF

echo -e "${COLOR_GREEN}✓ Configuración de Timeshift actualizada${COLOR_RESET}"

# 5. Crear script de backup automático
echo -e "\n${COLOR_CYAN}[5/5] Configurando backups automáticos...${COLOR_RESET}"

cat > /etc/cron.daily/timeshift-backup << 'EOF'
#!/bin/bash
# Backup automático diario con Timeshift

echo "[$(date)] Iniciando backup automático de Timeshift..." >> /var/log/timeshift-backup.log

# Crear snapshot
/usr/bin/timeshift --create --comments "NexusOS Daily Backup" >> /var/log/timeshift-backup.log 2>&1

# Limpiar backups antiguos (mantener últimos 7)
/usr/bin/timeshift --delete-all --older-than 7d >> /var/log/timeshift-backup.log 2>&1

echo "[$(date)] Backup completado" >> /var/log/timeshift-backup.log
EOF

chmod +x /etc/cron.daily/timeshift-backup

# Crear servicio systemd para backup automático
cat > /etc/systemd/system/timeshift-daily.service << 'EOF'
[Unit]
Description=NexusOS Daily System Backup (Timeshift)
After=network.target
Documentation=man:timeshift(1)

[Service]
Type=oneshot
ExecStart=/usr/bin/timeshift --create --comments "NexusOS Daily Backup"
StandardOutput=journal
StandardError=journal
SyslogIdentifier=timeshift-backup

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/timeshift-daily.timer << 'EOF'
[Unit]
Description=Daily System Backup Timer (Timeshift)
Documentation=man:timeshift(1)

[Timer]
# Ejecutar a las 2:00 AM diariamente
OnCalendar=daily
OnCalendar=*-*-* 02:00:00
Persistent=true
Unit=timeshift-daily.service

[Install]
WantedBy=timers.target
EOF

# Habilitar timer
systemctl daemon-reload
systemctl enable timeshift-daily.timer
systemctl start timeshift-daily.timer

echo -e "${COLOR_GREEN}✓ Backups automáticos habilitados${COLOR_RESET}"

# Resumen final
echo -e "\n${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✓ Timeshift instalado y configurado${COLOR_RESET}"
echo -e "${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

echo -e "\n${COLOR_CYAN}Configuración:${COLOR_RESET}"
echo "  • Backups automáticos: Diariamente a las 2:00 AM"
echo "  • Almacenamiento: $BACKUP_DIR"
echo "  • Retención: 7 backups recientes"
echo "  • Tamaño estimado: ~2GB por backup"

echo -e "\n${COLOR_PURPLE}Comandos útiles:${COLOR_RESET}"
echo "  Crear backup manual:   sudo timeshift --create --comments 'Manual backup'"
echo "  Listar backups:        sudo timeshift --list"
echo "  Restaurar backup:      sudo timeshift --restore --snapshot [fecha]"
echo "  Ver logs:              tail -f /var/log/timeshift-backup.log"

echo -e "\n${COLOR_CYAN}GUI disponible en:${COLOR_RESET}"
echo "  Control Center → Settings → System Backups"
echo "  O: sudo timeshift-launcher"

echo -e "\n${COLOR_YELLOW}Primer backup en 24 horas (o manual):${COLOR_RESET}"
echo "  sudo timeshift --create --comments 'Initial backup'"
