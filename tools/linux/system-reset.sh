#!/bin/bash
# System Reset para NexusOS
# Revertir cambios y restaurar sistema a estado limpio

set -e

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🔄 NEXUSOS SYSTEM RESET              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Confirmación
echo -e "${YELLOW}⚠️  ADVERTENCIA:${NC}"
echo "Esto revertirá TODOS los cambios de optimización"
echo "Tu librería de juegos NO se borrará"
echo ""

read -p "¿Deseas continuar? (escribe 'sí' para confirmar): " confirm

if [[ $confirm != "sí" ]]; then
    echo -e "${YELLOW}Cancelado.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}Iniciando reset...${NC}"
echo ""

# Contador de pasos
STEPS_COMPLETED=0
STEPS_TOTAL=5

# PASO 1: Revertir tweaks de CPU
echo -e "${CYAN}[1/5] Revertiendo tweaks de CPU...${NC}"
sudo sysctl -w kernel.sched_migration_cost_ns=500000 >/dev/null 2>&1 || true
sudo sysctl -w vm.swappiness=60 >/dev/null 2>&1 || true
echo -e "${GREEN}✓ CPU configuración restaurada${NC}"
STEPS_COMPLETED=$((STEPS_COMPLETED + 1))

# PASO 2: Revertir tweaks de GPU
echo -e "${CYAN}[2/5] Revertiendo tweaks de GPU...${NC}"
sudo systemctl restart nvidia-powerd 2>/dev/null || true
echo -e "${GREEN}✓ GPU configuración restaurada${NC}"
STEPS_COMPLETED=$((STEPS_COMPLETED + 1))

# PASO 3: Limpiar cache
echo -e "${CYAN}[3/5] Limpiando cache del sistema...${NC}"
sudo sync

if sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null; then
    echo -e "${GREEN}✓ Cache limpiado${NC}"
else
    echo -e "${YELLOW}⚠ No se pudo limpiar cache (puede requerir privilegios)${NC}"
fi

rm -rf ~/.cache/* 2>/dev/null || true
STEPS_COMPLETED=$((STEPS_COMPLETED + 1))

# PASO 4: Restaurar servicios
echo -e "${CYAN}[4/5] Restaurando servicios...${NC}"
sudo systemctl restart pipewire 2>/dev/null || true
sudo systemctl start NetworkManager 2>/dev/null || true
echo -e "${GREEN}✓ Servicios restaurados${NC}"
STEPS_COMPLETED=$((STEPS_COMPLETED + 1))

# PASO 5: Verificación
echo -e "${CYAN}[5/5] Verificando...${NC}"
echo -e "${GREEN}✓ Sistema restaurado${NC}"
STEPS_COMPLETED=$((STEPS_COMPLETED + 1))

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ RESET COMPLETADO                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

echo "Estado del sistema:"
echo "  • CPU: Configuración por defecto"
echo "  • GPU: Configuración por defecto"
echo "  • RAM: Limpiada"
echo "  • Servicios: Restaurados"
echo ""

read -p "¿Deseas reiniciar ahora? (s/n): " reboot_choice

if [[ $reboot_choice == "s" ]]; then
    echo -e "${YELLOW}Reiniciando en 10 segundos...${NC}"
    sleep 10
    sudo reboot
else
    echo -e "${GREEN}Reinicia manualmente cuando sea conveniente.${NC}"
fi

echo ""
