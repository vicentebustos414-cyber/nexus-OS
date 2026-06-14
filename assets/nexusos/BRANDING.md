# 🎮 NexusOS - Branding & Customization Guide

## Overview
NexusOS es tu Gaming OS personalizado basado en ChimeraOS, con branding único y emuladores integrados.

## Color Palette

### Primary Colors
- **Cyan (Primary)**: `#00d4ff` - Energía y velocidad
- **Purple (Accent)**: `#7c3aed` - Potencia y gaming
- **Dark Blue (Background)**: `#0a0e27` - Fondo elegante
- **Darker Purple (Secondary)**: `#1a0033` - Profundidad

### Usage
- Cyan: UI elements, text highlights, borders
- Purple: Gradients, accents, hover states
- Dark Blue: Main background
- Dark Purple: Secondary backgrounds, depth

---

## Branding Assets

### Logo
- **File**: `nexusos-logo.svg`
- **Usage**: Boot splash, GNOME shell, applications
- **Dimensions**: Scalable (SVG)
- **Concept**: Hexagonal nexus core with radiating energy lines

### Wallpaper
- **File**: `nexusos-background.svg`
- **Resolution**: 1920x1080 (scalable SVG)
- **Features**: 
  - Grid pattern background
  - Diagonal accent lines
  - NexusOS branding at bottom
  - Subtle glow effects

---

## Configuration Files

### GNOME Settings (dconf)
Located in: `rootfs/etc/dconf/db/local.d/`

1. **01-background** - Wallpaper and colors
   ```
   picture-uri='file:///usr/share/backgrounds/nexusos/nexusos-background.svg'
   primary-color='0a0e27'
   secondary-color='1a0033'
   ```

2. **02-nexusos-theme** - GNOME theme and dark mode
   ```
   color-scheme='prefer-dark'
   gtk-theme='Adwaita-dark'
   ```

---

## System Configuration

### Version: 1.0
### System Name: nexusos
### Display Name: NexusOS
### Username: gamer
### Total Size: 13GB

### Installed Emulators
- RetroArch + 15 cores (NES, SNES, Genesis, N64, PSX, etc.)
- ScummVM (Point-and-click adventures)
- Mednafen (Multi-system)
- Citra Canary (Nintendo 3DS)
- Ryujinx (Nintendo Switch)
- PCSX2 (PlayStation 2)
- EmulationStation DE (Frontend)

### Gaming Tools
- Steam (default)
- Proton (Windows games)
- Boxtron (DOS games)
- Gamescope (compositing window manager)
- MangoHUD (performance overlay)

---

## How to Customize Further

### 1. Change Wallpaper
Edit: `rootfs/etc/dconf/db/local.d/01-background`
```
picture-uri='file:///usr/share/backgrounds/nexusos/your-image.png'
```

### 2. Add Custom Icons
Place icon theme in: `rootfs/usr/share/icons/`
Reference in dconf:
```
icon-theme='your-icon-theme'
```

### 3. Modify Colors
Edit: `rootfs/etc/dconf/db/local.d/02-nexusos-theme`
Add custom color schemes via GSSettings

### 4. Add Custom Fonts
Place fonts in: `rootfs/usr/share/fonts/`
Install with: `fc-cache -fv`

---

## Build Instructions

### On Linux (with Docker)
```bash
cd ChimeraOS
./build-image.sh
```

### Output
- ISO: `output/nexusos-1.0-x86_64.iso`
- Ready to boot on USB or VM

---

## Further Customization Ideas

- [ ] Create custom GNOME Shell theme
- [ ] Add boot splash screen with NexusOS logo
- [ ] Create custom cursor theme
- [ ] Design EmulationStation custom theme
- [ ] Add startup animation
- [ ] Create custom application launcher
- [ ] Design system tray icons

---

**Created**: 2026-06-14
**Based on**: ChimeraOS + Arch Linux
**License**: Check individual component licenses
