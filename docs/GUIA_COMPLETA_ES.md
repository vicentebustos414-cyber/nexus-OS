# 📖 NexusOS - Guía Completa para Principiantes

## 🎮 ¿Qué es NexusOS?

NexusOS es un **sistema operativo gaming portátil** que cabe en un USB. Puedes:

✅ Jugar cientos de juegos clásicos  
✅ Usar en cualquier PC sin instalarlo  
✅ Llevar tus juegos a todas partes  
✅ Sin necesidad de abrir terminal  

---

## 📋 TABLA DE CONTENIDOS

1. [Instalación](#instalación)
2. [Primeros Pasos](#primeros-pasos)
3. [Agregar Juegos](#agregar-juegos)
4. [Jugar](#jugar)
5. [Optimizar Rendimiento](#optimizar-rendimiento)
6. [Troubleshooting](#troubleshooting)

---

## 🔧 Instalación

### Paso 1: Descargar el Instalador

1. Ve a **nexusos.com/download**
2. Descarga **NexusOS_Installer.exe** (~50MB)
3. Guárdalo en tu escritorio

### Paso 2: Ejecutar Instalador

1. **Conecta un USB vacío** (8GB mínimo)
2. **Doble-click** en `NexusOS_Installer.exe`
3. **Selecciona tu USB** en la ventana

```
┌─────────────────────────────────┐
│  Seleccionar USB                │
├─────────────────────────────────┤
│                                 │
│  ☑ G: (8GB Kingston)  ← SELECCIONA│
│  ☐ H: (16GB SanDisk)           │
│                                 │
│  [CONTINUAR]                    │
└─────────────────────────────────┘
```

4. **Espera ~5 minutos** (progreso visible)
5. **¡Listo!** Verás mensaje de éxito

### Paso 3: Arrancar desde USB

```
1. Apagar PC completamente

2. Conectar el USB con NexusOS

3. Encender PC

4. Presionar:
   - F12 en Dell/HP
   - ESC en ASUS
   - DEL en otros
   (Aparece al encender, rápido!)

5. Seleccionar USB en el menú

6. NexusOS cargará en 10-15 segundos
```

**Resultado: ¡NexusOS en tu pantalla!**

---

## 🎯 Primeros Pasos

### Setup Inicial (Primera vez)

Cuando arranques por primera vez, verás un **Setup Wizard**:

```
STEP 1: IDIOMA
────────────
☑ Español
○ English
○ Português

→ Selecciona Español, [SIGUIENTE]
```

```
STEP 2: WIFI
────────────
¿Conectar a internet?

Redes disponibles:
1. TuRed5G
2. Vecino_WiFi
3. Oficina_Guest

→ Selecciona tu red, ingresa contraseña
```

```
STEP 3: CONFIGURAR USUARIO
────────────────────────────
Usuario por defecto: "gamer"

¿Cambiar? No (mantener "gamer")
```

```
STEP 4: RESOLUCIÓN
────────────────────
☑ 1920x1080 (Full HD) - RECOMENDADO
○ 1366x768
○ 2560x1440
```

```
STEP 5: EMULADORES
────────────────────
¿Instalar todos?

☑ RetroArch (NES, SNES, Genesis, etc)
☑ PCSX2 (PlayStation 2)
☑ Ryujinx (Nintendo Switch)
☑ Citra (Nintendo 3DS)

→ Selecciona [SÍ, INSTALAR TODO]
```

```
STEP 6: CARPETA DE JUEGOS
─────────────────────────
¿Dónde guardar ROMs?

1) /home/gamer/Roms ← RECOMENDADO
2) /media/usb/ (segunda USB)
3) Otro

→ Selecciona 1
```

```
STEP 7: PRIVACIDAD
────────────────────
¿Enviar datos para mejorar?

☑ Sí, ayudar a mejorar NexusOS
○ No

→ Selecciona lo que prefieras
```

```
STEP 8: FINALIZAR
───────────────────
✓ Todo configurado

→ [EMPEZAR]
```

**¡Listo! Ya está todo listo.**

---

## 📁 Agregar Juegos

### Opción 1: Con Control Center (Más Fácil)

```
1. Abre "NexusOS Control Center" (icono en escritorio)

2. Ve a la pestaña "🎮 Gaming Hub"

3. Haz click en "📁 LOAD ROMs"

4. Selecciona la carpeta con tus juegos

5. Automáticamente detecta y organiza

6. ¡Los juegos aparecen en la pantalla!
```

### Opción 2: Con Script (Más Control)

```
Si tienes juegos en una carpeta:

1. Abre Terminal (Ctrl+Alt+T)

2. Escribe:
   chmod +x ~/import-roms.sh
   ~/import-roms.sh /ruta/a/tus/juegos

3. El script:
   - Detecta todos los juegos
   - Muestra un resumen
   - Pregunta si copiar
   - ¡Listos!
```

---

## 🎮 Jugar

### Encontrar un Juego

```
Control Center → Gaming Hub

┌──────────────────────────────┐
│  🎮 GAMING HUB               │
├──────────────────────────────┤
│                              │
│  Super Mario Bros     Zelda   │
│  [▶️ PLAY] [🗑️]    [▶️] [🗑️] │
│                              │
│  Pokémon Red       Kirby     │
│  [▶️ PLAY] [🗑️]    [▶️] [🗑️] │
│                              │
└──────────────────────────────┘
```

### Presionar [▶️ PLAY]

```
¡Automáticamente:

1. Detecta el emulador correcto
2. Aplica optimizaciones de gaming
3. Carga el juego
4. ¡A jugar!

Controles:
- Teclado: WASD + Z, X para botones
- Mando: Conecta cualquier mando USB
- ESC: Salir del juego
```

---

## ⚡ Optimizar Rendimiento

### Control Panel de Optimizaciones

```
Control Center → Optimizations

┌──────────────────────────────┐
│  ⚡ OPTIMIZATIONS            │
├──────────────────────────────┤
│                              │
│ Modo:                        │
│ ◉ Gaming (Máximo)            │
│ ○ Balanced (Normal)          │
│ ○ Power Saving               │
│                              │
│ Tweaks Activos:              │
│ ☑ CPU Performance            │
│ ☑ GPU Scheduling             │
│ ☑ Game Mode                  │
│                              │
│ Presets:                     │
│ [Competitive][Creative]      │
│                              │
└──────────────────────────────┘
```

### Aumentar FPS

Para juegos que van lentos:

```
1. Abre Control Center

2. Ve a Optimizations

3. Selecciona "Gaming" mode

4. Marca todos los checkboxes

5. Presiona "Apply Preset: Competitive"

6. Resultado: +30-50 FPS extra
```

---

## 📊 Monitor de Sistema

### Ver Rendimiento en Vivo

```
Control Center → Monitor

┌──────────────────────────────┐
│  📊 SYSTEM MONITOR           │
├──────────────────────────────┤
│                              │
│ CPU:  ████████░░ 82%         │
│ GPU:  ██████░░░░ 60%         │
│ RAM:  ███████░░░ 70% (7.2GB) │
│ TEMP: ████████░░ 82°C        │
│                              │
│ HISTORY (últimas 2 min):     │
│ CPU:  ▁▂▃▅▆█▆▅▄▃▂▁...        │
│                              │
└──────────────────────────────┘
```

**Interpreta los colores:**

- 🟢 Verde (< 70%): Perfecto
- 🟡 Amarillo (70-90%): Normal
- 🔴 Rojo (> 90%): Cuidado (puede ralentizar)

---

## ❌ Troubleshooting

### "El juego no carga"

```
1. Verifica que esté en la carpeta correcta

2. Prueba con otro juego

3. Si no funciona ninguno:
   - Abre Control Center
   - Ve a Help → Report Bug
   - Describe qué pasa

4. O escribe en Discord: nexusos community
```

### "Muy lento/Lag"

```
1. Abre Control Center

2. Ve a Optimizations

3. Selecciona modo "Gaming"

4. Presiona "Competitive Preset"

5. Si sigue lento:
   - Reduce resolución en settings
   - O usa emulador diferente
```

### "Mi USB no arranca"

```
1. Verifica que esté en BIOS order primero
   (Aprende a entrar al BIOS con F2/DEL)

2. Si nada funciona:
   - Reinstala con el instalador
   - USA USB 3.0 (no USB 2.0 viejo)

3. Contacta soporte: help@nexusos.local
```

### "¿Cómo revertir cambios?"

```
Si algo se rompió:

1. Abre Terminal (Ctrl+Alt+T)

2. Escribe:
   chmod +x ~/system-reset.sh
   ~/system-reset.sh

3. Confirmación → Espera 2 minutos

4. Sistema limpio = como nuevo
```

---

## 🎓 Tips Avanzados

### Crear Accesos Directos a Favoritos

```
En Gaming Hub:
- Marca tus juegos favoritos (⭐)
- Aparecen en "FAVORITES"
- Click = juego en 1 segundo
```

### Usar Tus Propios Controles

```
Control Center → Settings → Controllers

Mapea los botones de tu mando:
- Define botones
- Prueba con un juego
- Guarda perfil personalizado
```

### Configurar Emuladores Específicos

```
Control Center → Settings → Emulators

Para CADA emulador:
- Gráficos (Calidad vs FPS)
- Audio (Volumen, reverberación)
- Controles
- Compatibilidad
```

---

## 📞 Contacto y Comunidad

**Si necesitas ayuda:**

- 📧 **Email**: help@nexusos.local
- 💬 **Discord**: /join nexusos
- 🌐 **Wiki**: wiki.nexusos.local
- 📱 **Reddit**: r/nexusos

**Reportar bugs:**

```
Control Center → Help → Report Bug

O sube a: github.com/nexusos/issues
```

---

## 🎉 ¡Listo!

Ya sabes todo lo básico. A partir de ahora:

1. **Carga tus juegos** (Import ROMs)
2. **Optimiza rendimiento** (Gaming Mode)
3. **Disfruta** (¡A jugar! 🎮)

Si algo no funciona, NO TE PREOCUPES:
- Presiona [RESET SYSTEM] → Vuelve a estado limpio
- Contacta comunidad → Te ayudamos

---

## 🚀 Próximos Pasos

Una vez domines lo básico:

- [ ] Agregar 10+ juegos a tu librería
- [ ] Probar diferentes presets de optimización
- [ ] Mapear tu mando personalizado
- [ ] Explorar configuraciones avanzadas de emuladores
- [ ] Unirte a la comunidad Discord

---

**NexusOS v1.0 - Gaming para todos, sin complicaciones** 🎮✨

*Última actualización: 2026-06-14*
