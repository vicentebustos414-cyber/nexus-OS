# 🎮 NexusOS v1.0 - Quick Start Guide

## 🚀 Tu Sistema Está Listo

NexusOS ahora tiene **3 sistemas automáticos de protección** para que NUNCA pierdas tu setup:

```
📸 Snapshots (Snapper)    → Rollback en minutos
💾 Backups (Timeshift)    → Restauración en horas  
🎮 Driver Manager         → Drivers automáticos
```

---

## 🎯 **Primeros Pasos (5 minutos)**

### **1. Abre el Control Center**
```bash
# Desde aplicaciones
NexusOS Control Center

# O desde terminal
python ~/tools/linux/nexusos-gui/main.py
```

### **2. Haz clic en 💾 System Recovery**
```
Sidebar → [💾 System Recovery]
├─ 📸 SNAPSHOTS
│  └─ Ver snapshots existentes (ya hay uno)
│
└─ 📁 BACKUPS
   └─ Ver backups (se crean automáticamente)
```

### **3. Crea un Snapshot de tu setup**
```
💾 System Recovery → 📸 SNAPSHOTS
[+ CREAR SNAPSHOT]
  Descripción: "Gaming Setup Inicial"
  [CREAR]
  
→ ✅ Listo en segundos
```

---

## 🎮 **Ahora Tienes 3 Capas de Protección**

### **Capa 1: Snapshots** (Para problemas rápidos)
```
Instalas un juego malo
  ↓
Abre Control Center → System Recovery → Snapshots
  ↓
Click [↩️ RESTORE] en tu snapshot
  ↓
⏱️ 2-5 minutos → Sistema fijo
```

### **Capa 2: Backups** (Para desastres)
```
Sistema completamente roto
  ↓
Boot desde recovery media
  ↓
Selecciona backup reciente
  ↓
⏱️ 60-120 minutos → Exactamente igual a antes
```

### **Capa 3: Drivers** (Para compatibilidad)
```
Primera vez o GPU nueva:
  
sudo bash ~/tools/linux/driver-manager.sh
  ↓
Sistema detecta tu GPU
  ↓
Instala automáticamente:
  ✓ Drivers
  ✓ Vulkan
  ✓ Wine/Proton
  ↓
⏱️ 10 minutos → Ready to game
```

---

## 📅 **Automatismo**

### **Ya está configurado:**
```
✅ Snapshots: Cada día automático
✅ Backups: Cada noche 02:00 AM
✅ Cleanup: Automático (mantiene últimos)
✅ Drivers: Auto-detect en boot (si es primera vez)
```

### **No tienes que hacer nada:**
```
Los backups se crean solos cada noche
Los snapshots se crean solos cada día
Los drivers se instalan automáticamente
```

---

## 💻 **Comandos Útiles**

### **Ver snapshots**
```bash
snapper -c root list
```

### **Crear snapshot manual**
```bash
snapper -c root create -d "Antes de instalar X"
```

### **Ver backups**
```bash
sudo timeshift --list
```

### **Crear backup manual**
```bash
sudo timeshift --create --comments "Antes del viaje"
```

### **Instalar drivers automáticamente**
```bash
sudo bash ~/tools/linux/driver-manager.sh
```

---

## 🆘 **Si algo sale mal**

### **Opción 1: Restaurar desde Snapshot** (Rápido)
```
1. Abre Control Center → System Recovery
2. Selecciona snapshot anterior
3. Click [↩️ RESTORE]
4. Espera 2-5 minutos
5. ✅ Listo
```

### **Opción 2: Restaurar desde GRUB Menu** (Sin GUI)
```
1. Reinicia NexusOS
2. En GRUB menu → "Snapshots" o "Advanced"
3. Selecciona snapshot que quieras
4. Boot
5. ✅ Listo
```

### **Opción 3: Restaurar desde Backup** (Completo)
```
1. Boot desde NexusOS recovery media
2. Selecciona timeshift recovery
3. Elige backup que quieras restaurar
4. Espera 1-2 horas
5. ✅ Sistema exactamente como estaba
```

---

## 🎓 **Aprender Más**

### **Guía Completa:**
```
Documentación → SYSTEM_RECOVERY_GUIDE.md
```

### **Cómo fue integrado:**
```
Documentación → INTEGRATION_SUMMARY.md
```

### **Scripting:**
```
Código → tools/linux/driver-manager.sh
Código → tools/linux/nexusos-installer-btrfs.sh
Código → tools/linux/timeshift-setup.sh
```

---

## ✅ **Checklist: ¿Todo OK?**

```
[ ] Control Center abre sin errores
[ ] Botón 💾 System Recovery aparece en sidebar
[ ] Veo snapshots en la pestaña de snapshots
[ ] Puedo crear snapshot manual (sin errores)
[ ] Ver está ocupado (~100MB por snapshot)
[ ] Timeshift muestra backups en la pestaña
[ ] Próximo backup programado (hoy 02:00 AM)
[ ] Puedo crear backup manual
[ ] Driver Manager script existe y es executable
```

---

## 🎮 **Ya Puedes**

```
✅ Instalar cualquier juego sin miedo
✅ Experimentar con configuraciones
✅ Actualizar Linux sin pánico
✅ Romper sistema sin perder nada
✅ Recuperar en minutos si falla algo
✅ Tener backups diarios automáticos
✅ Drivers siempre optimizados
```

---

## 🚀 **Siguientes Pasos**

1. **Prueba el Gaming Hub:**
   - Abre ROMs de emuladores
   - Instala juegos Steam
   - Juega tranquilo (ahora tienes snapshots)

2. **Prueba Windows Apps:**
   - Instala apps de Windows
   - Funciona con Wine/Proton
   - Recuperable si falla

3. **Crea tu Snapshot de Reference:**
   - Instala tus juegos favoritos
   - Configura todo como te gusta
   - Crea snapshot de "Gaming Ready"
   - Ahora puedes experimentar desde aquí

4. **Monitorea tus Backups:**
   - Control Center → System Recovery → Backups
   - Verifica que se crean cada noche
   - Tu data está segura

---

## 📞 **Soporte**

### **Sistema Recovery no aparece:**
```bash
# Verificar que Snapper está instalado
snapper --version

# Verificar que Timeshift está instalado
timeshift --version

# Si alguno falla, instalar:
sudo bash ~/tools/linux/nexusos-full-setup.sh
```

### **Drivers no se instalan:**
```bash
# Ejecutar manualmente
sudo bash ~/tools/linux/driver-manager.sh

# Ver GPU detectada
lspci | grep VGA

# Ver si ya están instalados
nvidia-smi          # Si tienes Nvidia
vulkaninfo          # Ver Vulkan status
```

### **Backup/Snapshot no se crea:**
```bash
# Verificar permisos
sudo -l | grep snapper
sudo -l | grep timeshift

# Verificar espacio disco
df -h

# Ver logs
journalctl -u snapper-timeline -f
tail -f /var/log/timeshift-backup.log
```

---

## 🎉 **¡Listo!**

Tienes un **Sistema Linux Gaming Profesional** con:
- ✅ 3 capas de protección automática
- ✅ Recovery en minutos
- ✅ Drivers optimizados
- ✅ 100% GUI (sin terminal obligatorio)
- ✅ En español
- ✅ Para principiantes

**Ahora a disfrutar gaming sin miedo.** 🚀

---

**NexusOS v1.0 Quick Start**  
*Última actualización: 2026-06-14*
