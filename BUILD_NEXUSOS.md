# 🔨 NexusOS - Build Guide

## Opciones para compilar la ISO

La ISO se compila dentro de un contenedor Docker usando el sistema de ChimeraOS.

---

## ✅ OPCIÓN 1 (RECOMENDADO): GitHub Actions

El método más simple. Solo necesitas subir los cambios a tu propio repositorio.

### Paso 1 - Crear tu repo en GitHub

1. Ve a https://github.com/new
2. Nombre: `nexusos`
3. Visibilidad: Public o Private
4. Click **Create repository**

### Paso 2 - Conectar tu repo

```powershell
cd C:\Users\vicente\ChimeraOS

# Renombrar origin a upstream (para no perder referencia al original)
git remote rename origin upstream

# Agregar tu repo como origin
git remote add origin https://github.com/TU_USUARIO/nexusos.git
```

### Paso 3 - Commit y Push

```powershell
cd C:\Users\vicente\ChimeraOS

# Stage todos los cambios de NexusOS
git add manifest
git add rootfs/
git add tools/
git add *.md
git add .github/

# Commit
git commit -m "feat: NexusOS v1.0 - CachyOS kernel, Recovery System, Gaming GUI"

# Push (dispara GitHub Actions automáticamente)
git push -u origin master
```

### Paso 4 - Ver el build

GitHub Actions construye automáticamente:
- Ir a: `github.com/TU_USUARIO/nexusos/actions`
- Ver: `System image build` → En progreso

⏱️ **Tiempo estimado: 45-90 minutos**

### Paso 5 - Descargar la ISO

Cuando termine:
- GitHub Actions → Build completado ✅
- Releases → `nexusos-pro-1.0-cachyos.img.tar.xz`
- Descargar → Descomprimir → Instalar con `frzr`

---

## 🐳 OPCIÓN 2: Docker Local (Avanzado)

Requiere Docker Desktop + WSL2 actualizado.

### Prerequisitos

```powershell
# Actualizar WSL2 (requerido)
wsl --update

# Verificar Docker
docker --version
# Docker version 29.5.2 ✅
```

### Paso 1 - Construir imagen builder

```powershell
cd C:\Users\vicente\ChimeraOS

# Construir imagen Docker del builder (~10 minutos)
docker build -t nexusos-builder .
```

### Paso 2 - Crear directorio output

```powershell
mkdir output
```

### Paso 3 - Compilar la ISO

```powershell
# Ejecutar build dentro del container
# IMPORTANTE: requiere --privileged para btrfs
docker run `
  --rm `
  --privileged `
  -v "${PWD}:/workdir" `
  -v "${PWD}/output:/output" `
  --entrypoint /workdir/build-image.sh `
  nexusos-builder

# Resultado: output/nexusos-pro-1.0-cachyos.img.tar.xz
```

### Paso 4 - Verificar output

```powershell
dir output\
# nexusos-pro-1.0-cachyos.img.tar.xz
# build_info.txt
# sha256sum.txt
```

⚠️ **Nota**: El build dentro de Docker en Windows puede fallar por limitaciones de btrfs.
Si falla, usa Opción 1 (GitHub Actions).

---

## 📦 Estructura del Build

```
build-image.sh ejecuta:
│
├─ 1. Crear imagen Btrfs vacía (13.5GB)
│
├─ 2. pacstrap: instalar base Arch Linux
│
├─ 3. arch-chroot: instalar paquetes
│  ├─ Kernel: linux-cachyos (BORE scheduler)
│  ├─ PACKAGES (100+ paquetes gaming)
│  │  ├─ Wine + Wine-staging
│  │  ├─ DXVK + VKD3D
│  │  ├─ Snapper + Timeshift + btrfs-progs
│  │  ├─ GameMode + MangoHUD
│  │  ├─ RetroArch + cores
│  │  └─ GNOME + Steam
│  └─ AUR_PACKAGES (40+ paquetes)
│     ├─ proton-ge-custom-bin
│     ├─ bottles + lutris
│     ├─ citra-canary + ryujinx + pcsx2
│     └─ emulationstation-de
│
├─ 4. postinstallhook (NexusOS)
│  ├─ Snapper: config automática
│  ├─ Snapper: snapshot inicial creado
│  ├─ Timeshift: config + daily timer
│  └─ Sudoers: permisos configurados
│
├─ 5. Btrfs snapshot
│
└─ 6. Comprimir: .img.tar.xz
```

---

## 🚀 Instalar NexusOS después del build

### En una PC nueva

```bash
# Arrancar desde USB live de Arch Linux
# Conectar a internet

# Instalar frzr
pacman -Sy frzr

# Instalar NexusOS desde archivo descargado
frzr-deploy nexusos-pro-1.0-cachyos.img

# O desde GitHub Releases directamente
frzr-deploy github:TU_USUARIO/nexusos
```

### En VirtualBox/VMware (testing)

```bash
# Crear VM: 50GB disk, 8GB RAM, Enable Nested VT-x
# Boot desde Arch Linux ISO
# Instalar frzr y deploy como arriba
```

---

## ⏱️ Tiempos estimados

| Método | Tiempo | Requisitos |
|--------|--------|-----------|
| GitHub Actions | 45-90 min | GitHub account |
| Docker local | 60-120 min | Docker + WSL2 |
| Servidor Linux | 30-60 min | Linux + root |

---

## 🔐 Variables necesarias para GitHub Actions

El workflow existente en `.github/workflows/main.yml` ya está configurado.
Solo necesita tu repo con permisos de `packages:write` y `contents:write`.

```yaml
# .github/workflows/main.yml ya tiene:
on:
  push:
    branches:
      - master
  workflow_dispatch:  # También permite trigger manual
```

Para trigger manual: GitHub → Actions → System image build → Run workflow

---

## 📊 Output esperado

Después del build exitoso:

```
output/
├─ nexusos-pro-1.0-cachyos.img.tar.xz    (~8-10 GB comprimido)
├─ build_info.txt                         (lista de paquetes instalados)
└─ sha256sum.txt                          (hash de verificación)

GitHub Releases:
├─ build_info.txt
├─ sha256sum.txt
└─ container.txt
```

La imagen `.img.tar.xz` se sube automáticamente como **OCI artifact** a GitHub Container Registry:
```
ghcr.io/TU_USUARIO/nexusos:1.0-cachyos
```

---

## 🆘 Troubleshooting

### Docker falla con btrfs

```
Error: cannot create btrfs filesystem
```

**Solución**: Usar GitHub Actions (no requiere btrfs local).

### WSL2 needs update

```
Error: WSL must be updated
```

```powershell
wsl --update
wsl --shutdown
# Reiniciar Docker Desktop
```

### Paquete AUR no encontrado

```
error: target not found: [paquete]
```

**Solución**: El paquete puede haber cambiado de nombre en AUR.
Verificar en: https://aur.archlinux.org/packages/[nombre]
Actualizar en `manifest` → `AUR_PACKAGES`.

---

**NexusOS Build Guide v1.0**  
*Sistema de build: ChimeraOS (Arch Linux + Docker)*
