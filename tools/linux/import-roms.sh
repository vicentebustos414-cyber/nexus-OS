#!/bin/bash
# Import ROMs a NexusOS
# Script para importar juegos de una carpeta
# Uso: ./import-roms.sh

set -e

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  📁 IMPORT ROMs TO NEXUSOS            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Detectar carpeta de ROMs
ROMS_PATH="${1:-.}"

if [ ! -d "$ROMS_PATH" ]; then
    echo -e "${RED}✗ Carpeta no encontrada: $ROMS_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}Escaneando:${NC} $ROMS_PATH"
echo ""

# Contadores
NES_COUNT=0
SNES_COUNT=0
N64_COUNT=0
GBA_COUNT=0
PS1_COUNT=0
PS2_COUNT=0
SWITCH_COUNT=0
UNKNOWN_COUNT=0

# Escanear
for file in "$ROMS_PATH"/*; do
    ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    case "$ext" in
        nes) NES_COUNT=$((NES_COUNT + 1)) ;;
        snes|smc) SNES_COUNT=$((SNES_COUNT + 1)) ;;
        z64|n64) N64_COUNT=$((N64_COUNT + 1)) ;;
        gba) GBA_COUNT=$((GBA_COUNT + 1)) ;;
        bin|cue) PS1_COUNT=$((PS1_COUNT + 1)) ;;
        iso) PS2_COUNT=$((PS2_COUNT + 1)) ;;
        xci|nso) SWITCH_COUNT=$((SWITCH_COUNT + 1)) ;;
        *) UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1)) ;;
    esac
done

# Mostrar resultados
echo -e "${GREEN}✓ JUEGOS ENCONTRADOS:${NC}"
echo ""
[ $NES_COUNT -gt 0 ] && echo "  🎮 NES:       $NES_COUNT juegos"
[ $SNES_COUNT -gt 0 ] && echo "  🎮 SNES:      $SNES_COUNT juegos"
[ $N64_COUNT -gt 0 ] && echo "  🎮 N64:       $N64_COUNT juegos"
[ $GBA_COUNT -gt 0 ] && echo "  🎮 GBA:       $GBA_COUNT juegos"
[ $PS1_COUNT -gt 0 ] && echo "  🎮 PS1:       $PS1_COUNT juegos"
[ $PS2_COUNT -gt 0 ] && echo "  🎮 PS2:       $PS2_COUNT juegos"
[ $SWITCH_COUNT -gt 0 ] && echo "  🎮 SWITCH:    $SWITCH_COUNT juegos"
[ $UNKNOWN_COUNT -gt 0 ] && echo "  ❓ DESCONOCIDOS: $UNKNOWN_COUNT archivos"

echo ""
TOTAL=$((NES_COUNT + SNES_COUNT + N64_COUNT + GBA_COUNT + PS1_COUNT + PS2_COUNT + SWITCH_COUNT))
echo -e "${YELLOW}TOTAL:${NC} $TOTAL juegos encontrados"
echo ""

# Copiar a carpeta oficial
NEXUSOS_ROMS="$HOME/Roms"
mkdir -p "$NEXUSOS_ROMS"

read -p "¿Copiar juegos a $NEXUSOS_ROMS? (s/n): " confirm

if [[ $confirm == "s" ]]; then
    echo ""
    echo -e "${CYAN}Copiando juegos...${NC}"

    cp -r "$ROMS_PATH"/* "$NEXUSOS_ROMS/" 2>/dev/null || true

    echo -e "${GREEN}✓ Juegos copiados exitosamente${NC}"
    echo ""
    echo "Próximo paso: Abre NexusOS Control Center y ve a Gaming Hub"
else
    echo -e "${YELLOW}⚠ Importación cancelada${NC}"
fi

echo ""
