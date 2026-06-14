# 💾 NexusOS - System Recovery Guide

## Visión General

NexusOS incluye 3 sistemas automáticos de recuperación para garantizar que **NUNCA pierdas tu setup de gaming**:

```
┌────────────────────────────────────────────────────────────┐
│                    SYSTEM RECOVERY                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  📸 SNAPSHOTS (Snapper)     → Minutos
│     ├─ Rollback rápido                                     │
│     ├─ Punto a punto (diferencial)                        │
│     ├─ Automático cada día                                │
│     └─ Retiene: 7 últimos                                 │
│                                                             │
│  📁 BACKUPS (Timeshift)     → Horas
│     ├─ Restauración completa                              │
│     ├─ Sistema entero (bitwise)                           │
│     ├─ Automático cada día                                │
│     └─ Retiene: 5 últimos                                 │
│                                                             │
│  🎮 DRIVER MANAGER          → Automático
│     ├─ Detecta GPU                                        │
│     ├─ Instala drivers                                    │
│     ├─ Configura Vulkan                                  │
│     └─ Ready to game                                      │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## 1️⃣ **SNAPSHOTS - Snapper + Btrfs**

### ¿Qué es?

Sistema de snapshots a nivel filesystem que permite:
- **Rollback instantáneo** de cambios
- **Diferencial** (solo cambios, no copia completa)
- **Automático** cada día
- **Seleccionable en GRUB** boot menu

### Casos de uso

```
ESCENARIO: Instalas Elden Ring, rompe la librería Steam

❌ ANTES (sin Snapper):
   1. Sistema roto
   2. Reinstalar todo
   3. 8 horas de setup

✅ AHORA (con Snapper):
   1. Boot menu GRUB
   2. Selecciona "Snapshot 5" (antes de instalar)
   3. 2 minutos → Sistema igual a antes
```

### Instalación

```bash
# Automática (incluido en nexusos-full-setup.sh)
sudo bash nexusos-full-setup.sh
→ Selecciona opción 1 o 2

# Manual
sudo bash nexusos-installer-btrfs.sh
```

### Requisitos

- **Filesystem: Btrfs** (automático en nueva instalación)
- O convertir ext4 → Btrfs (proceso invasivo, backup primero)

### Comandos

```bash
# Ver snapshots
snapper -c root list

# Crear manual
snapper -c root create -d "Antes de jugar Valorant"

# Restaurar (ambas opciones)
# Opción 1: GRUB boot menu (más fácil para GUI)
# Opción 2: Línea de comandos
snapper -c root undochange 5..0

# Eliminar
snapper -c root delete 5
```

### GUI - Control Center

```
Control Center → Settings → System Recovery → Snapshots
│
├─ 📸 SNAPSHOTS (Snapper)
│  ├─ #10: Gaming Setup (2026-06-13 20:00)
│  │     [↩️ RESTORE]  [🗑️ DELETE]
│  │
│  ├─ #9: Antes de instalar Valorant (2026-06-12 15:30)
│  │     [↩️ RESTORE]  [🗑️ DELETE]
│  │
│  ├─ [+ CREAR SNAPSHOT]  [🔄 REFRESCAR]
│  │
│  └─ Total: 10 snapshots | Automático: Diario
```

### Performance

| Métrica | Valor |
|---------|-------|
| Tiempo crear snapshot | < 1 segundo |
| Tiempo restaurar | 2-10 minutos |
| Espacio por snapshot | ~50-200MB (diferencial) |
| Snapshots retenidos | 7 diarios |

### Configuración automática

```
Calendario de Snapshots:
├─ Antes de actualización (pacman hook)
├─ Diario (2:00 AM)
└─ Retiene: 7 últimos + 5 importantes

Ubicación: /.snapshots/
Filesystem: Btrfs subvolume
Recovery: GRUB submenu automático
```

---

## 2️⃣ **BACKUPS - Timeshift**

### ¿Qué es?

Sistema de backups **completos del sistema** que permite:
- **Restauración bitwise** (bit por bit)
- **Sistema entero** incluyendo /home, /etc, /opt
- **Automático** cada día
- **Seleccionable en boot** (Grub o USB)

### Casos de uso

```
ESCENARIO: Instalas juego corrupto, sistema no bootea

❌ ANTES (sin Timeshift):
   1. Reinstalar Linux desde cero
   2. Instalar todas las apps
   3. Restaurar from settings backups
   4. 48 horas de setup

✅ AHORA (con Timeshift):
   1. Boot desde backup USB
   2. Selecciona "Backup 2026-06-13"
   3. 1 hora → Sistema exactamente igual
   4. Todos los juegos, drivers, configs intactos
```

### Instalación

```bash
# Automática
sudo bash nexusos-full-setup.sh
→ Selecciona opción 1 o 4

# Manual
sudo bash timeshift-setup.sh
```

### Requisitos

- **Espacio en disco**: ~2GB por backup × 5 = 10GB mínimo
- **Partición libre**: Recomienda disco separado (o /home)
- **Filesystem**: Cualquiera (ext4, Btrfs, etc.)

### Comandos

```bash
# Ver backups
timeshift --list

# Crear manual
timeshift --create --comments "Antes de instalar Steam"

# Restaurar (interactivo)
sudo timeshift-launcher
# O línea de comandos:
sudo timeshift --restore --snapshot 2026-06-13_20-00-00

# Eliminar
sudo timeshift --delete --snapshot 2026-06-13_20-00-00
```

### GUI - Control Center

```
Control Center → Settings → System Recovery → Backups
│
├─ 📁 BACKUPS (Timeshift)
│  ├─ 2026-06-13 @ 20:00 (Gaming Setup) [2.1GB]
│  │     [↩️ RESTORE]  [🗑️ DELETE]
│  │
│  ├─ 2026-06-12 @ 02:00 (Auto) [1.9GB]
│  │     [↩️ RESTORE]  [🗑️ DELETE]
│  │
│  ├─ [+ CREAR BACKUP]  [🔄 REFRESCAR]
│  │
│  └─ Total: 5 backups | Automático: Diario 02:00 AM
```

### Performance

| Métrica | Valor |
|---------|-------|
| Tiempo crear backup | 10-60 minutos |
| Tiempo restaurar | 30-120 minutos |
| Espacio por backup | ~2-5GB |
| Backups retenidos | 5 más recientes |
| Actualización diaria | 02:00 AM |

### Almacenamiento automático

```
Ubicación: /timeshift/backups/ (o disco separado)
Schedule: Diariamente 02:00 AM
Retención: 5 backups (auto-delete antiguos)
Exclusiones: /dev, /proc, /sys, /tmp, cache
```

---

## 3️⃣ **DRIVER MANAGER - Auto Detection**

### ¿Qué es?

Sistema automático que:
- **Detecta GPU** (NVIDIA, AMD, Intel)
- **Instala drivers** óptimos
- **Configura Vulkan** para gaming
- **Instala Wine/Proton** dependencias

### Casos de uso

```
ESCENARIO: Usuario compra GTX 4060 Ti, instala NexusOS

❌ ANTES (sin Driver Manager):
   1. ¿Qué GPU tengo?
   2. Buscar drivers en NVIDIA
   3. Descargar instalador
   4. Compilar módulo kernel
   5. 30 minutos + riesgo de error

✅ AHORA (con Driver Manager):
   1. Sistema detecta: "NVIDIA GTX 4060 Ti"
   2. Propone: "Instalar drivers?"
   3. Click SÍ
   4. 10 minutos → Drivers + Vulkan + Wine + Listo
```

### Instalación

```bash
# Automática (recomendado)
sudo bash nexusos-full-setup.sh
→ Selecciona opción 1, 2 o 3

# Manual
sudo bash driver-manager.sh
```

### GPUs Soportadas

```
✅ NVIDIA
   ├─ RTX 40xx, 30xx, 20xx series
   ├─ Drivers: nvidia, nvidia-utils
   ├─ CUDA: Compilación máxima
   └─ Performance: Máximo

✅ AMD
   ├─ Radeon RX 7000, 6000 series
   ├─ Drivers: amdgpu-dkms
   ├─ RDNA: Excelente
   └─ Performance: Máximo

✅ Intel
   ├─ Iris Xe (10th gen+)
   ├─ Drivers: intel-media-driver
   ├─ Encoder: Hardware accelerated
   └─ Performance: Optimizado
```

### Qué instala

```
1. GPU Drivers
   └─ NVIDIA: nvidia + cuda
   └─ AMD: amdgpu-dkms
   └─ Intel: intel-media-driver

2. Vulkan
   └─ vulkan-icd-loader
   └─ vulkan-radeon / vulkan-intel (según GPU)

3. Gaming Libraries
   ├─ Wine + Wine-staging
   ├─ Proton-GE
   ├─ DXVK (DirectX → Vulkan)
   └─ VKD3D (Direct3D 12)

4. Utilidades
   └─ GPU monitoring tools
   └─ Driver management tools
```

### GUI - Control Center

```
Control Center → Settings → Drivers
│
├─ 🎮 DRIVER MANAGER
│  ├─ GPU Detectada: NVIDIA RTX 3080
│  │
│  ├─ Estado:
│  │  ✓ Drivers: Instalados (535.xx)
│  │  ✓ Vulkan: Habilitado
│  │  ✓ CUDA: Disponible
│  │  ✓ Wine: Configurado
│  │
│  ├─ Performance:
│  │  • Modo: Optimizado
│  │  • Memory: 10GB
│  │  • Monitor: nvidia-smi
│  │
│  └─ [🔄 CHECK UPDATES]  [⚙️ SETTINGS]
```

### Comandos de prueba

```bash
# Verificar GPU
lspci | grep -i vga

# Verificar drivers (NVIDIA)
nvidia-smi

# Verificar Vulkan
vulkaninfo

# Verificar Wine
wine --version
proton --version
```

---

## 🔄 **Flujo Completo de Recuperación**

### Escenario: Usuario rompe sistema

```
1. Usuario instala juego.exe
2. Sistema se corrompe
3. ¿Qué hacer?

OPCIÓN A: Usar Snapshot (minutos)
├─ Reiniciar
├─ GRUB → Snapshot submenu
├─ Selecciona "Snapshot 12: Antes de instalar"
└─ 2-5 minutos → Sistema funcional
    ✓ Todo igual
    ✓ Juego NO instalado
    ✓ Resto intacto

OPCIÓN B: Usar Timeshift Backup (horas)
├─ Reiniciar
├─ Boot menu → Recovery media
├─ Selecciona "Backup 2026-06-13_20-00"
└─ 60-120 minutos → Sistema exacto
    ✓ Bitwise identical
    ✓ Todos los juegos
    ✓ Todos los drivers
    ✓ Todas las configuraciones
```

---

## 📊 **Comparativa: Snapper vs Timeshift vs Drivers**

| Feature | Snapper | Timeshift | Driver Manager |
|---------|---------|-----------|-----------------|
| **Tipo** | Snapshots | Backups | Auto-instalación |
| **Velocidad** | ⚡⚡⚡ Minutos | ⚡⚡ Horas | ⚡ Automático |
| **Cobertura** | Sistema | Sistema + Home | Drivers + Libs |
| **Almacenamiento** | ~100MB c/u | ~2-5GB c/u | 1x instalación |
| **Automático** | ✓ Diario | ✓ Diario | ✓ Al startup |
| **Boot Recovery** | ✓ GRUB menu | ✓ Recovery USB | - |
| **CLI/GUI** | ✓ Ambos | ✓ Ambos | ✓ Automático |

---

## 🛠️ **Troubleshooting**

### Problema: "No puedo restaurar Snapshot"

```bash
# Verificar Snapper
snapper -c root list
snapper -c root get-config

# Si está corrupto:
snapper -c root undochange 0..N  # Donde N = snapshot a restaurar
```

### Problema: "Timeshift tarda demasiado"

```bash
# Verificar espacio
df -h

# Limpiar cache
pacman -Sc
rm -rf ~/.cache/*

# Verificar velocidad disco
iostat -x 1
```

### Problema: "Drivers no instalados"

```bash
# Ejecutar driver manager manualmente
sudo bash driver-manager.sh

# Verificar GPU
lspci | grep VGA

# Ver logs
dmesg | tail -20
```

---

## 📋 **Checklist de Setup**

```
NexusOS System Recovery Setup:

[ ] 1. Instalar Snapper
    └─ sudo bash nexusos-installer-btrfs.sh
    
[ ] 2. Instalar Driver Manager
    └─ sudo bash driver-manager.sh
    
[ ] 3. Instalar Timeshift
    └─ sudo bash timeshift-setup.sh
    
[ ] 4. Crear primer snapshot
    └─ snapper -c root create -d "Initial Setup"
    
[ ] 5. Crear primer backup
    └─ sudo timeshift --create --comments "Initial backup"
    
[ ] 6. Verificar en Control Center
    └─ Control Center → Settings → System Recovery
    
[ ] 7. Hacer gaming setup (instalar juegos, apps)
    └─ Steam, Discord, OBS, etc.
    
[ ] 8. Crear snapshot de "Gaming Ready"
    └─ snapper -c root create -d "Gaming Setup Complete"
    
[ ] 9. Ahora NUNCA perderás tu setup
    └─ ¡Disfruta gaming sin miedo!
```

---

## 🎓 **Recursos**

```
Snapper:
  • Manual: man snapper
  • Docs: https://snapper.io/
  • Config: /etc/snapper/configs/root

Timeshift:
  • Help: timeshift --help
  • Docs: https://github.com/teejee2008/timeshift
  • Launcher: sudo timeshift-launcher

Btrfs:
  • Wiki: https://btrfs.wiki.kernel.org/
  • Tools: btrfs filesystem usage /
  • Convert: btrfs-convert /dev/sdX
```

---

## ✅ **¿Todo listo?**

```bash
# Verificar instalación completa
snapper -c root list                    # ✓ Snapshots OK
timeshift --list                        # ✓ Backups OK
nvidia-smi                              # ✓ Drivers OK (si NVIDIA)
vulkaninfo                              # ✓ Vulkan OK
```

**¡NexusOS ahora es resistente a fallos!**

Puedes experimentar, instalar cualquier cosa, y **NUNCA perderás tu setup**. 🚀

---

**NexusOS System Recovery Guide v1.0**  
*Fecha: 2026-06-14*  
*Soporte: Complete system reliability*
