"""
NexusOS Control Center - GUI Principal
Interfaz gráfica para principiantes sin experiencia Linux
"""

import customtkinter as ctk
from PIL import Image, ImageDraw, ImageFont
import psutil
import threading
import time
from pathlib import Path

# Importar módulos NexusOS
try:
    from system_recovery import SystemRecoveryFrame
except ImportError:
    SystemRecoveryFrame = None

# Configuración
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

# Colores NexusOS
COLOR_CYAN = "#00d4ff"
COLOR_PURPLE = "#7c3aed"
COLOR_DARK = "#0a0e27"


class NexusOSControlCenter:
    """Control Center principal de NexusOS"""

    def __init__(self, root):
        self.root = root
        self.root.title("NexusOS Control Center v1.0")
        self.root.geometry("1280x720")
        self.root.resizable(False, False)

        # Configurar apariencia
        self.setup_ui()
        self.setup_monitoring()

    def setup_ui(self):
        """Crear interfaz principal"""

        # Main Container
        main_container = ctk.CTkFrame(
            self.root, fg_color=COLOR_DARK
        )
        main_container.pack(fill="both", expand=True)

        # ═══════════════════════════════════════════════════════════
        # TOP BAR - Logo, Clock, System Status
        # ═══════════════════════════════════════════════════════════

        top_bar = ctk.CTkFrame(
            main_container, fg_color=COLOR_PURPLE, height=60
        )
        top_bar.pack(fill="x", padx=0, pady=0)
        top_bar.pack_propagate(False)

        # Logo
        logo_label = ctk.CTkLabel(
            top_bar,
            text="🎮 NEXUSOS v1.0",
            font=("Helvetica", 24, "bold"),
            text_color=COLOR_CYAN,
        )
        logo_label.pack(side="left", padx=20, pady=10)

        # System Status (CPU, GPU, Temp)
        self.status_label = ctk.CTkLabel(
            top_bar,
            text="CPU: --% | GPU: --% | TEMP: --°C",
            font=("Helvetica", 12),
            text_color="white",
        )
        self.status_label.pack(side="right", padx=20, pady=10)

        # ═══════════════════════════════════════════════════════════
        # MAIN CONTENT - Sidebar + Content Area
        # ═══════════════════════════════════════════════════════════

        content_container = ctk.CTkFrame(main_container, fg_color=COLOR_DARK)
        content_container.pack(fill="both", expand=True, padx=0, pady=0)

        # SIDEBAR
        self.sidebar = ctk.CTkFrame(
            content_container, width=200, fg_color="#1a1a2e"
        )
        self.sidebar.pack(side="left", fill="y", padx=0, pady=0)
        self.sidebar.pack_propagate(False)

        # Botones Sidebar
        self.create_sidebar_buttons()

        # MAIN AREA
        self.main_area = ctk.CTkFrame(content_container, fg_color=COLOR_DARK)
        self.main_area.pack(side="right", fill="both", expand=True, padx=20, pady=20)

        # Frame para contenido dinámico
        self.content_frame = None
        self.show_gaming_hub()

    def create_sidebar_buttons(self):
        """Crear botones de navegación"""

        buttons = [
            ("🎮 Gaming Hub", self.show_gaming_hub),
            ("⚡ Optimizations", self.show_optimizations),
            ("📊 Monitor", self.show_monitor),
            ("💾 System Recovery", self.show_recovery),
            ("⚙️ Settings", self.show_settings),
            ("❓ Help", self.show_help),
        ]

        for btn_text, cmd in buttons:
            btn = ctk.CTkButton(
                self.sidebar,
                text=btn_text,
                command=cmd,
                fg_color=COLOR_PURPLE,
                hover_color=COLOR_CYAN,
                text_color="white",
                font=("Helvetica", 14),
                height=50,
            )
            btn.pack(fill="x", padx=10, pady=5)

        # Separator
        sep = ctk.CTkFrame(self.sidebar, fg_color="#333")
        sep.pack(fill="x", padx=10, pady=10, ipady=1)

        # Reset Button (rojo)
        reset_btn = ctk.CTkButton(
            self.sidebar,
            text="🔄 Reset System",
            command=self.reset_system,
            fg_color="#cc3333",
            hover_color="#ff4444",
            font=("Helvetica", 12),
            height=40,
        )
        reset_btn.pack(fill="x", padx=10, pady=5)

    def clear_content(self):
        """Limpiar área principal"""
        if self.content_frame:
            self.content_frame.destroy()

    # ═════════════════════════════════════════════════════════════
    # VIEWS (Vistas diferentes)
    # ═════════════════════════════════════════════════════════════

    def show_gaming_hub(self):
        """Mostrar Gaming Hub"""
        self.clear_content()

        self.content_frame = ctk.CTkFrame(self.main_area, fg_color=COLOR_DARK)
        self.content_frame.pack(fill="both", expand=True)

        # Título
        title = ctk.CTkLabel(
            self.content_frame,
            text="🎮 GAMING HUB",
            font=("Helvetica", 28, "bold"),
            text_color=COLOR_CYAN,
        )
        title.pack(pady=10)

        # Botones de acción
        action_frame = ctk.CTkFrame(self.content_frame, fg_color=COLOR_DARK)
        action_frame.pack(fill="x", pady=10)

        load_btn = ctk.CTkButton(
            action_frame,
            text="📁 LOAD ROMs",
            command=self.load_roms,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
            font=("Helvetica", 14, "bold"),
        )
        load_btn.pack(side="left", padx=5)

        config_btn = ctk.CTkButton(
            action_frame,
            text="⚙️ CONFIGURE",
            command=self.configure_emulator,
            fg_color=COLOR_PURPLE,
        )
        config_btn.pack(side="left", padx=5)

        # Lista de juegos (placeholder)
        games_frame = ctk.CTkFrame(self.content_frame, fg_color="#1a1a2e")
        games_frame.pack(fill="both", expand=True, pady=10)

        games_label = ctk.CTkLabel(
            games_frame,
            text="No games loaded. Click 'LOAD ROMs' to add games.",
            font=("Helvetica", 14),
            text_color="#999",
        )
        games_label.pack(expand=True)

    def show_optimizations(self):
        """Mostrar panel de optimizaciones"""
        self.clear_content()

        self.content_frame = ctk.CTkFrame(self.main_area, fg_color=COLOR_DARK)
        self.content_frame.pack(fill="both", expand=True)

        title = ctk.CTkLabel(
            self.content_frame,
            text="⚡ OPTIMIZATIONS",
            font=("Helvetica", 28, "bold"),
            text_color=COLOR_CYAN,
        )
        title.pack(pady=10)

        # Selector de modo
        mode_frame = ctk.CTkFrame(self.content_frame, fg_color=COLOR_DARK)
        mode_frame.pack(fill="x", pady=10)

        ctk.CTkLabel(
            mode_frame, text="MODE:", font=("Helvetica", 14)
        ).pack(side="left", padx=5)

        self.mode_var = ctk.StringVar(value="gaming")
        for mode in ["gaming", "balanced", "powersave"]:
            rb = ctk.CTkRadioButton(
                mode_frame,
                text=mode.capitalize(),
                variable=self.mode_var,
                value=mode,
                command=self.apply_mode,
            )
            rb.pack(side="left", padx=10)

        # Tweaks
        tweaks_frame = ctk.CTkFrame(self.content_frame, fg_color="#1a1a2e")
        tweaks_frame.pack(fill="both", expand=True, pady=10)

        tweaks = [
            "CPU Performance Mode",
            "GPU Scheduling",
            "Game Mode",
            "Audio Optimization",
            "Network Tuning",
        ]

        for tweak in tweaks:
            chk = ctk.CTkCheckBox(
                tweaks_frame,
                text=tweak,
                font=("Helvetica", 12),
            )
            chk.pack(anchor="w", padx=10, pady=5)

    def show_monitor(self):
        """Mostrar monitor de sistema"""
        self.clear_content()

        self.content_frame = ctk.CTkFrame(self.main_area, fg_color=COLOR_DARK)
        self.content_frame.pack(fill="both", expand=True)

        title = ctk.CTkLabel(
            self.content_frame,
            text="📊 SYSTEM MONITOR",
            font=("Helvetica", 28, "bold"),
            text_color=COLOR_CYAN,
        )
        title.pack(pady=10)

        # Gauges
        self.cpu_gauge = self.create_gauge(self.content_frame, "CPU", "%")
        self.gpu_gauge = self.create_gauge(self.content_frame, "GPU", "%")
        self.mem_gauge = self.create_gauge(self.content_frame, "MEMORY", "%")
        self.temp_gauge = self.create_gauge(self.content_frame, "CPU TEMP", "°C")

    def create_gauge(self, parent, label, unit):
        """Crear un gauge de métrica"""
        frame = ctk.CTkFrame(parent, fg_color=COLOR_DARK)
        frame.pack(fill="x", pady=5)

        ctk.CTkLabel(
            frame, text=label, font=("Helvetica", 12)
        ).pack(side="left", padx=10, anchor="w")

        gauge = ctk.CTkProgressBar(frame)
        gauge.pack(side="left", fill="x", expand=True, padx=10)

        value_label = ctk.CTkLabel(
            frame, text="0%", font=("Helvetica", 11), width=50
        )
        value_label.pack(side="right", padx=10)

        return gauge, value_label

    def show_recovery(self):
        """Mostrar System Recovery (Snapshots + Backups)"""
        self.clear_content()

        self.content_frame = ctk.CTkFrame(self.main_area, fg_color=COLOR_DARK)
        self.content_frame.pack(fill="both", expand=True)

        if SystemRecoveryFrame is None:
            # Si no se puede importar, mostrar mensaje de error
            error_label = ctk.CTkLabel(
                self.content_frame,
                text="❌ System Recovery no disponible\n\nAsegúrate de que snapper y timeshift estén instalados.",
                font=("Helvetica", 14),
                text_color="#ff4444",
            )
            error_label.pack(expand=True)
        else:
            # Mostrar GUI de recuperación del sistema
            recovery_frame = SystemRecoveryFrame(self.content_frame)
            recovery_frame.pack(fill="both", expand=True)

    def show_settings(self):
        """Mostrar configuración"""
        self.clear_content()

        self.content_frame = ctk.CTkFrame(self.main_area, fg_color=COLOR_DARK)
        self.content_frame.pack(fill="both", expand=True)

        title = ctk.CTkLabel(
            self.content_frame,
            text="⚙️ SETTINGS",
            font=("Helvetica", 28, "bold"),
            text_color=COLOR_CYAN,
        )
        title.pack(pady=10)

        settings_frame = ctk.CTkFrame(self.content_frame, fg_color="#1a1a2e")
        settings_frame.pack(fill="x", padx=10, pady=10)

        # Language
        lang_frame = ctk.CTkFrame(settings_frame, fg_color="#1a1a2e")
        lang_frame.pack(fill="x", padx=10, pady=10)
        ctk.CTkLabel(lang_frame, text="Language:", font=("Helvetica", 12)).pack(
            side="left"
        )
        lang_combo = ctk.CTkComboBox(
            lang_frame, values=["Español", "English", "Português"]
        )
        lang_combo.pack(side="right", fill="x", expand=True)

        # Resolution
        res_frame = ctk.CTkFrame(settings_frame, fg_color="#1a1a2e")
        res_frame.pack(fill="x", padx=10, pady=10)
        ctk.CTkLabel(res_frame, text="Resolution:", font=("Helvetica", 12)).pack(
            side="left"
        )
        res_combo = ctk.CTkComboBox(
            res_frame,
            values=["1920x1080", "1366x768", "1600x900", "2560x1440"],
        )
        res_combo.pack(side="right", fill="x", expand=True)

    def show_help(self):
        """Mostrar ayuda"""
        self.clear_content()

        self.content_frame = ctk.CTkFrame(self.main_area, fg_color=COLOR_DARK)
        self.content_frame.pack(fill="both", expand=True)

        title = ctk.CTkLabel(
            self.content_frame,
            text="❓ HELP & SUPPORT",
            font=("Helvetica", 28, "bold"),
            text_color=COLOR_CYAN,
        )
        title.pack(pady=10)

        help_text = ctk.CTkLabel(
            self.content_frame,
            text="""
FAQ:
• ¿Cómo instalo juegos? - Click en "LOAD ROMs"
• ¿Qué emuladores hay? - RetroArch, PCSX2, Ryujinx, Citra
• ¿Cómo optimizo? - Usa la pestaña "Optimizations"

CONTACTO:
📧 Email: help@nexusos.local
💬 Discord: nexusos community
🌐 Wiki: wiki.nexusos.local
            """,
            justify="left",
            font=("Helvetica", 12),
        )
        help_text.pack(fill="both", expand=True, padx=20, pady=20)

    # ═════════════════════════════════════════════════════════════
    # ACCIONES
    # ═════════════════════════════════════════════════════════════

    def load_roms(self):
        """Cargar ROMs"""
        print("Loading ROMs...")

    def configure_emulator(self):
        """Configurar emulador"""
        print("Configuring emulator...")

    def apply_mode(self):
        """Aplicar modo de optimización"""
        mode = self.mode_var.get()
        print(f"Applying {mode} mode...")

    def reset_system(self):
        """Reset del sistema"""
        print("Resetting system...")

    def setup_monitoring(self):
        """Monitoreo de sistema en background"""

        def monitor():
            while True:
                try:
                    cpu = psutil.cpu_percent(interval=0.1)
                    mem = psutil.virtual_memory().percent
                    temp = 50  # placeholder

                    # Actualizar label
                    self.status_label.configure(
                        text=f"CPU: {cpu:.0f}% | MEM: {mem:.0f}%  | TEMP: {temp:.0f}°C"
                    )

                    time.sleep(1)
                except Exception as e:
                    print(f"Monitor error: {e}")

        thread = threading.Thread(target=monitor, daemon=True)
        thread.start()


def main():
    """Punto de entrada"""
    root = ctk.CTk()
    app = NexusOSControlCenter(root)
    root.mainloop()


if __name__ == "__main__":
    main()
