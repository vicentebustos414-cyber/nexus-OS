#!/bin/bash
# NexusOS - Auto Driver Manager
# Detecta GPU automáticamente e instala drivers óptimos

set -e

COLOR_CYAN="\033[0;36m"
COLOR_PURPLE="\033[0;35m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

# Función para detectar GPU
detect_gpu() {
    local gpu_vendor=$(lspci | grep -i vga | head -1)

    if [[ $gpu_vendor == *"NVIDIA"* ]]; then
        echo "nvidia"
    elif [[ $gpu_vendor == *"AMD"* ]]; then
        echo "amd"
    elif [[ $gpu_vendor == *"Intel"* ]]; then
        echo "intel"
    else
        echo "unknown"
    fi
}

# Función para instalar drivers NVIDIA
install_nvidia() {
    echo -e "${COLOR_CYAN}[GPU] NVIDIA RTX detectado${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Instalando drivers NVIDIA...${COLOR_RESET}"

    # Instalar driver
    pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils

    # Instalar utilidades
    pacman -S --noconfirm nvidia-settings cuda

    # Habilitar DRM
    echo -e "\n${COLOR_CYAN}Configurando kernel parameters...${COLOR_RESET}"
    echo "nvidia_drm.modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf

    echo -e "${COLOR_GREEN}✓ NVIDIA drivers instalados${COLOR_RESET}"
    echo "  • GPU: RTX"
    echo "  • CUDA: Habilitado"
    echo "  • Performance: Máximo"
}

# Función para instalar drivers AMD
install_amd() {
    echo -e "${COLOR_CYAN}[GPU] AMD Radeon detectado${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Instalando drivers AMD...${COLOR_RESET}"

    # Instalar driver (AMDGPU)
    pacman -S --noconfirm amdgpu-dkms lib32-amdgpu-dkms

    # Alternativa: xf86-video-amdgpu (newer)
    pacman -S --noconfirm xf86-video-amdgpu lib32-mesa-vdpau

    # Utilidades
    pacman -S --noconfirm amd-ucode radeontop

    echo -e "${COLOR_GREEN}✓ AMD drivers instalados${COLOR_RESET}"
    echo "  • GPU: Radeon / RDNA"
    echo "  • Renderer: Vulkan optimizado"
    echo "  • Performance: Máximo"
}

# Función para instalar drivers Intel
install_intel() {
    echo -e "${COLOR_CYAN}[GPU] Intel Iris detectado${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Instalando drivers Intel...${COLOR_RESET}"

    # Instalar driver
    pacman -S --noconfirm intel-media-driver libva-intel-driver

    # Microcode
    pacman -S --noconfirm intel-ucode

    # Utilidades
    pacman -S --noconfirm intel-gpu-tools

    echo -e "${COLOR_GREEN}✓ Intel drivers instalados${COLOR_RESET}"
    echo "  • GPU: Intel Iris"
    echo "  • Encoder: Hardware accelerated"
    echo "  • Performance: Optimizado"
}

# Función para instalar Vulkan
install_vulkan() {
    echo -e "${COLOR_CYAN}[Gráficos] Instalando Vulkan...${COLOR_RESET}"

    GPU=$1

    case $GPU in
        nvidia)
            pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader
            pacman -S --noconfirm nvidia-utils
            ;;
        amd)
            pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader
            pacman -S --noconfirm vulkan-radeon lib32-vulkan-radeon
            ;;
        intel)
            pacman -S --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader
            pacman -S --noconfirm vulkan-intel lib32-vulkan-intel
            ;;
    esac

    echo -e "${COLOR_GREEN}✓ Vulkan instalado${COLOR_RESET}"
}

# Función para instalar dependencias gaming
install_gaming_libs() {
    echo -e "${COLOR_CYAN}[Gaming] Instalando librerías...${COLOR_RESET}"

    # DXVK y VKD3D
    pacman -S --noconfirm dxvk vkd3d

    # Wine 32-bit
    pacman -S --noconfirm wine wine-staging lib32-wine lib32-wine-staging

    # Proton
    pacman -S --noconfirm proton proton-ge-custom-bin

    # Otras librerías
    pacman -S --noconfirm lib32-vulkan-icd-loader lib32-openssl lib32-glib2

    echo -e "${COLOR_GREEN}✓ Gaming libraries instaladas${COLOR_RESET}"
}

# Función principal
main() {
    echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  NexusOS - Driver Manager${COLOR_RESET}"
    echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

    # Detectar GPU
    echo -e "\n${COLOR_YELLOW}Detectando GPU...${COLOR_RESET}"
    GPU=$(detect_gpu)

    if [[ "$GPU" == "unknown" ]]; then
        echo -e "${COLOR_RED}✗ GPU no detectada o no soportada${COLOR_RESET}"
        lspci | grep -i vga
        exit 1
    fi

    echo -e "${COLOR_GREEN}✓ GPU detectada: $GPU${COLOR_RESET}"

    # Instalar drivers según GPU
    echo -e "\n${COLOR_CYAN}[Paso 1/3] Instalando drivers GPU...${COLOR_RESET}"
    case $GPU in
        nvidia)
            install_nvidia
            ;;
        amd)
            install_amd
            ;;
        intel)
            install_intel
            ;;
    esac

    # Instalar Vulkan
    echo -e "\n${COLOR_CYAN}[Paso 2/3] Instalando Vulkan...${COLOR_RESET}"
    install_vulkan $GPU

    # Instalar librerías gaming
    echo -e "\n${COLOR_CYAN}[Paso 3/3] Instalando gaming libraries...${COLOR_RESET}"
    install_gaming_libs

    # Configuración final
    echo -e "\n${COLOR_CYAN}Configuración final...${COLOR_RESET}"

    # Actualizar mkinitcpio si usa NVIDIA
    if [[ "$GPU" == "nvidia" ]]; then
        echo -e "${COLOR_YELLOW}Regenerando initramfs...${COLOR_RESET}"
        mkinitcpio -P
    fi

    # Mostrar resumen
    echo -e "\n${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_GREEN}✓ Driver Manager completado${COLOR_RESET}"
    echo -e "${COLOR_GREEN}═══════════════════════════════════════════════════════════${COLOR_RESET}"

    echo -e "\n${COLOR_CYAN}Sistema listo para gaming:${COLOR_RESET}"
    echo "  • GPU: $GPU"
    echo "  • Drivers: Optimizados"
    echo "  • Vulkan: ✓"
    echo "  • Wine/Proton: ✓"
    echo "  • Windows apps: Listos"

    echo -e "\n${COLOR_PURPLE}Reinicia para aplicar cambios:${COLOR_RESET}"
    echo "  reboot"
}

# Ejecutar si es root
if [[ $EUID -eq 0 ]]; then
    main
else
    echo -e "${COLOR_RED}Este script requiere permisos de root${COLOR_RESET}"
    exit 1
fi
