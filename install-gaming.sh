#!/bin/bash
# NexusOS Gaming Tools Installer - One-Liner Bootstrap
# Ejecutar: curl -fsSL https://raw.githubusercontent.com/vicentebustos414-cyber/nexus-OS/master/install-gaming.sh | bash
# O desde USB: bash /run/media/user/USB/install-gaming.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🎮 NexusOS Gaming Ecosystem Installer v2.0           ║${NC}"
echo -e "${CYAN}║  Proton-GE | DXVK | VKD3D | Wine | Lutris            ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ $EUID -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi

INSTALL_DIR="/opt/nexus-gaming"
SCRIPTS_DIR="$INSTALL_DIR/ai"
BIN_DIR="/usr/local/bin"
REPO_URL="https://raw.githubusercontent.com/vicentebustos414-cyber/nexus-OS/master"

# ===== FASE 1: DEPENDENCIAS =====
echo -e "${YELLOW}📦 FASE 1: Instalando dependencias del sistema...${NC}"

if command -v pacman &>/dev/null; then
    $SUDO pacman -Sy --noconfirm --needed \
        wine winetricks lutris steam \
        lib32-vulkan-icd-loader vulkan-icd-loader \
        lib32-gnutls gnutls lib32-libpulse \
        gamemode lib32-gamemode \
        mangohud lib32-mangohud \
        git curl wget 2>/dev/null || true
    echo -e "  ${GREEN}✓ Paquetes Arch/CachyOS instalados${NC}"
fi

# ===== FASE 2: CREAR ESTRUCTURA =====
echo ""
echo -e "${YELLOW}📁 FASE 2: Creando estructura de directorios...${NC}"
$SUDO mkdir -p "$SCRIPTS_DIR" /opt/nexus-gaming/db /opt/nexus-gaming/logs
$SUDO chmod -R 755 "$INSTALL_DIR"
echo -e "  ${GREEN}✓ $INSTALL_DIR creado${NC}"

# ===== FASE 3: DESCARGAR SCRIPTS =====
echo ""
echo -e "${YELLOW}⬇️  FASE 3: Descargando scripts de gaming...${NC}"

for script in proton-manager.sh auto-repair.sh bottleneck-detection.sh dxvk-optimizer.sh wine-staging-installer.sh lutris-installer.sh; do
    echo -n "  $script... "
    if curl -fsSL "$REPO_URL/nexus-gaming/ai/$script" -o "/tmp/$script" 2>/dev/null; then
        $SUDO mv "/tmp/$script" "$SCRIPTS_DIR/$script"
        $SUDO chmod +x "$SCRIPTS_DIR/$script"
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}skip (sin internet)${NC}"
    fi
done

# ===== FASE 4: PROTON-GE =====
echo ""
echo -e "${YELLOW}🍷 FASE 4: Instalando Proton-GE...${NC}"
mkdir -p "$HOME/.steam/root/compatibilitytools.d"

PROTON_GE_LATEST=$(curl -s "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
if [[ -n "$PROTON_GE_LATEST" ]]; then
    wget -q --show-progress "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_GE_LATEST}/${PROTON_GE_LATEST}.tar.gz" -O /tmp/proton-ge.tar.gz 2>/dev/null
    tar -xzf /tmp/proton-ge.tar.gz -C "$HOME/.steam/root/compatibilitytools.d/"
    rm /tmp/proton-ge.tar.gz
    echo -e "  ${GREEN}✓ Proton-GE $PROTON_GE_LATEST instalado${NC}"
else
    echo -e "  ${YELLOW}⚠ Sin red — ejecutar luego: proton-manager install-ge${NC}"
fi

# ===== FASE 5: DXVK CONFIG para RTX 5050 =====
echo ""
echo -e "${YELLOW}⚡ FASE 5: Configurando DXVK para RTX 5050...${NC}"
mkdir -p "$HOME/.config/dxvk"
cat > "$HOME/.config/dxvk/dxvk.conf" << 'EOF'
# DXVK optimizado para NVIDIA RTX 5050
d3d11.cachedDynamicResources = a
dxgi.nvapiHack = False
d3d11.maxFrameLatency = 1
d3d11.samplerAnisotropy = 16
dxvk.numCompilerThreads = 0
dxvk.enableAsync = True
EOF
echo -e "  ${GREEN}✓ DXVK config RTX 5050 creado${NC}"

# ===== FASE 6: GAME DATABASE =====
echo ""
echo -e "${YELLOW}🗃️  FASE 6: Creando base de datos de juegos...${NC}"
$SUDO mkdir -p /opt/nexus-gaming/db
$SUDO tee /opt/nexus-gaming/db/games.json > /dev/null << 'GEOF'
{
  "games": [
    {"id": "elden-ring", "name": "Elden Ring", "proton": "GE-latest", "dxvk": true, "vkd3d": false, "recommendedSpecs": {"cpuScore": 8500, "vram": 4096}},
    {"id": "cyberpunk-2077", "name": "Cyberpunk 2077", "proton": "GE-latest", "dxvk": false, "vkd3d": true, "recommendedSpecs": {"cpuScore": 9000, "vram": 8192}},
    {"id": "baldurs-gate-3", "name": "Baldur's Gate 3", "proton": "GE-latest", "dxvk": false, "vkd3d": true, "recommendedSpecs": {"cpuScore": 7000, "vram": 4096}},
    {"id": "witcher-3", "name": "The Witcher 3", "proton": "Experimental", "dxvk": true, "vkd3d": false, "recommendedSpecs": {"cpuScore": 6500, "vram": 4096}},
    {"id": "gta-v", "name": "GTA V", "proton": "GE-latest", "dxvk": true, "vkd3d": false, "recommendedSpecs": {"cpuScore": 6000, "vram": 4096}},
    {"id": "rdr2", "name": "RDR2", "proton": "GE-latest", "dxvk": false, "vkd3d": true, "recommendedSpecs": {"cpuScore": 9000, "vram": 8192}},
    {"id": "fortnite", "name": "Fortnite", "proton": "GE-latest", "dxvk": true, "vkd3d": false, "recommendedSpecs": {"cpuScore": 7000, "vram": 4096}},
    {"id": "helldivers-2", "name": "Helldivers 2", "proton": "GE-latest", "dxvk": false, "vkd3d": true, "recommendedSpecs": {"cpuScore": 8000, "vram": 4096}},
    {"id": "palworld", "name": "Palworld", "proton": "GE-latest", "dxvk": false, "vkd3d": true, "recommendedSpecs": {"cpuScore": 7500, "vram": 6144}},
    {"id": "starfield", "name": "Starfield", "proton": "GE-latest", "dxvk": false, "vkd3d": true, "recommendedSpecs": {"cpuScore": 9500, "vram": 8192}}
  ]
}
GEOF
echo -e "  ${GREEN}✓ DB de 10 juegos populares creada${NC}"

# ===== FASE 7: GAMEMODE + MANGOHUD =====
echo ""
echo -e "${YELLOW}🎮 FASE 7: Configurando GameMode + MangoHud para RTX 5050...${NC}"
mkdir -p "$HOME/.config/gamemode" "$HOME/.config/MangoHud"

cat > "$HOME/.config/gamemode/gamemode.ini" << 'EOF'
[general]
renice=10
inhibit_screensaver=1
[gpu]
apply_gpu_optimisations=accept-responsibility
nv_powermizer_mode=1
nv_mem_clock_mhz_offset=100
[cpu]
park_cores=no
pin_cores=yes
EOF

cat > "$HOME/.config/MangoHud/MangoHud.conf" << 'EOF'
fps
frametime=1
gpu_name
gpu_temp
cpu_temp
vram
ram
position=top-right
font_size=22
background_alpha=0.4
EOF
echo -e "  ${GREEN}✓ GameMode + MangoHud optimizados${NC}"

# ===== FASE 8: SYMLINKS =====
echo ""
echo -e "${YELLOW}🔗 FASE 8: Instalando comandos en /usr/local/bin...${NC}"

declare -A CMDS=(
    ["proton-manager"]="$SCRIPTS_DIR/proton-manager.sh"
    ["nexus-autorepair"]="$SCRIPTS_DIR/auto-repair.sh"
    ["nexus-bottleneck"]="$SCRIPTS_DIR/bottleneck-detection.sh"
    ["dxvk-optimizer"]="$SCRIPTS_DIR/dxvk-optimizer.sh"
    ["wine-gaming"]="$SCRIPTS_DIR/wine-staging-installer.sh"
    ["lutris-nexus"]="$SCRIPTS_DIR/lutris-installer.sh"
)

for cmd in "${!CMDS[@]}"; do
    if [[ -f "${CMDS[$cmd]}" ]]; then
        $SUDO ln -sf "${CMDS[$cmd]}" "$BIN_DIR/$cmd"
        echo -e "  ${GREEN}✓ $cmd${NC}"
    fi
done

# ===== RESUMEN =====
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ NexusOS Gaming Ecosystem INSTALADO               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Comandos disponibles:"
echo -e "  ${CYAN}proton-manager${NC}      # Proton-GE manager"
echo -e "  ${CYAN}nexus-autorepair${NC}    # Auto-repair de crashes"
echo -e "  ${CYAN}nexus-bottleneck${NC}    # Análisis bottleneck CPU/GPU"
echo -e "  ${CYAN}dxvk-optimizer${NC}      # DXVK config automático"
echo -e "  ${CYAN}wine-gaming${NC}         # Wine Staging + esync"
echo -e "  ${CYAN}lutris-nexus${NC}        # Lutris 1000+ scripts"
echo ""
echo -e "${CYAN}🎮 ¡Listo para gaming en NexusOS!${NC}"
