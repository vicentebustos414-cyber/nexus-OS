"""
Windows Apps Launcher para NexusOS
Ejecutor visual para apps de Windows en Wine/Proton
"""

import customtkinter as ctk
from pathlib import Path
import json
import subprocess
import threading
import os

# Colores NexusOS
COLOR_CYAN = "#00d4ff"
COLOR_PURPLE = "#7c3aed"
COLOR_DARK = "#0a0e27"


class WindowsAppsManager:
    """Gestor de apps de Windows"""

    # Apps que funcionan bien con Wine/Proton
    COMPATIBLE_APPS = {
        "games": {
            "Valorant": {
                "name": "Valorant",
                "icon": "🎮",
                "notes": "Requiere anti-cheat bypass",
                "setup": "manual",
            },
            "CS:GO": {
                "name": "Counter-Strike: Global Offensive",
                "icon": "🎯",
                "notes": "Funciona perfectamente",
                "setup": "steam",
            },
            "Fortnite": {
                "name": "Fortnite",
                "icon": "🎮",
                "notes": "Via Epic Games Launcher",
                "setup": "manual",
            },
            "Minecraft": {
                "name": "Minecraft Java Edition",
                "icon": "⛏️",
                "notes": "Funciona nativamente también",
                "setup": "direct",
            },
            "Portal 2": {
                "name": "Portal 2",
                "icon": "🚪",
                "notes": "Funciona perfectamente",
                "setup": "steam",
            },
        },
        "apps": {
            "Discord": {
                "name": "Discord",
                "icon": "💬",
                "notes": "Chat + Voice (funciona bien)",
                "setup": "web",
            },
            "OBS": {
                "name": "OBS Studio",
                "icon": "📹",
                "notes": "Streaming (alternativa Linux)",
                "setup": "native",
            },
            "Photoshop": {
                "name": "Photoshop",
                "icon": "🎨",
                "notes": "Parcial (Gimp alternativa)",
                "setup": "manual",
            },
        },
    }

    def __init__(self):
        self.wine_prefix = Path.home() / ".wine"
        self.proton_dir = Path.home() / ".steam/root/compatibilitytools.d"
        self.installed_apps = self.load_installed_apps()

    def load_installed_apps(self):
        """Cargar apps instaladas"""
        config_file = Path.home() / ".nexusos" / "windows_apps.json"

        if config_file.exists():
            try:
                with open(config_file, "r") as f:
                    return json.load(f)
            except:
                return {}

        return {}

    def save_installed_apps(self):
        """Guardar apps instaladas"""
        config_file = Path.home() / ".nexusos" / "windows_apps.json"
        config_file.parent.mkdir(exist_ok=True)

        try:
            with open(config_file, "w") as f:
                json.dump(self.installed_apps, f, indent=2)
        except:
            pass

    def run_app(self, app_name, exe_path):
        """Ejecutar aplicación de Windows"""
        # Usar Proton si está disponible
        if self._has_proton():
            self._run_with_proton(exe_path)
        else:
            self._run_with_wine(exe_path)

    def _has_proton(self):
        """Verificar si Proton está disponible"""
        return (
            self.proton_dir.exists()
            or Path("/opt/proton").exists()
        )

    def _run_with_wine(self, exe_path):
        """Ejecutar con Wine"""
        env = os.environ.copy()
        env["WINEPREFIX"] = str(self.wine_prefix)

        try:
            subprocess.Popen(
                ["wine", str(exe_path)],
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception as e:
            print(f"Error ejecutando con Wine: {e}")

    def _run_with_proton(self, exe_path):
        """Ejecutar con Proton (Steam)"""
        try:
            subprocess.Popen(
                ["proton", "run", str(exe_path)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception as e:
            print(f"Error ejecutando con Proton: {e}")

    def is_app_installable(self, app_name):
        """Verificar si app es instalable"""
        return any(
            app_name in apps
            for apps in self.COMPATIBLE_APPS.values()
        )

    def get_app_info(self, app_name):
        """Obtener info de app"""
        for category, apps in self.COMPATIBLE_APPS.items():
            if app_name in apps:
                return apps[app_name]
        return None


class WindowsAppsFrame(ctk.CTkFrame):
    """Frame para ejecutar apps de Windows"""

    def __init__(self, parent):
        super().__init__(parent, fg_color=COLOR_DARK)

        self.manager = WindowsAppsManager()
        self.create_widgets()

    def create_widgets(self):
        """Crear interfaz"""

        # Header
        header = ctk.CTkFrame(self, fg_color=COLOR_DARK)
        header.pack(fill="x", padx=20, pady=10)

        title = ctk.CTkLabel(
            header,
            text="🪟 WINDOWS APPS",
            font=("Helvetica", 24, "bold"),
            text_color=COLOR_CYAN,
        )
        title.pack(side="left")

        info_label = ctk.CTkLabel(
            header,
            text="Ejecuta apps de Windows en NexusOS",
            font=("Helvetica", 11),
            text_color="#999",
        )
        info_label.pack(side="left", padx=20)

        # Tabs
        tab_frame = ctk.CTkFrame(self, fg_color=COLOR_DARK)
        tab_frame.pack(fill="x", padx=20, pady=10)

        self.games_btn = ctk.CTkButton(
            tab_frame,
            text="🎮 GAMES",
            command=self.show_games,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
            font=("Helvetica", 12, "bold"),
        )
        self.games_btn.pack(side="left", padx=5)

        self.apps_btn = ctk.CTkButton(
            tab_frame,
            text="💻 APPLICATIONS",
            command=self.show_apps,
            fg_color=COLOR_PURPLE,
            font=("Helvetica", 12),
        )
        self.apps_btn.pack(side="left", padx=5)

        self.upload_btn = ctk.CTkButton(
            tab_frame,
            text="📁 INSTALL CUSTOM",
            command=self.install_custom,
            fg_color="#666",
            font=("Helvetica", 12),
        )
        self.upload_btn.pack(side="left", padx=5)

        # Content area
        self.content_frame = ctk.CTkScrollableFrame(
            self, fg_color=COLOR_DARK
        )
        self.content_frame.pack(
            fill="both", expand=True, padx=20, pady=10
        )

        self.show_games()

    def show_games(self):
        """Mostrar games compatibles"""
        self.clear_content()

        for game_id, game_info in (
            self.manager.COMPATIBLE_APPS["games"].items()
        ):
            self.create_app_card(game_id, game_info, "games")

    def show_apps(self):
        """Mostrar apps compatibles"""
        self.clear_content()

        for app_id, app_info in (
            self.manager.COMPATIBLE_APPS["apps"].items()
        ):
            self.create_app_card(app_id, app_info, "apps")

    def create_app_card(self, app_id, app_info, category):
        """Crear card para una app"""
        card = ctk.CTkFrame(self.content_frame, fg_color="#1a1a2e")
        card.pack(fill="x", padx=5, pady=5)

        # Info
        info_frame = ctk.CTkFrame(card, fg_color="#1a1a2e")
        info_frame.pack(side="left", fill="both", expand=True, padx=10, pady=10)

        # Icon + Name
        title_frame = ctk.CTkFrame(info_frame, fg_color="#1a1a2e")
        title_frame.pack(fill="x")

        icon_label = ctk.CTkLabel(
            title_frame,
            text=app_info.get("icon", "📦"),
            font=("Helvetica", 20),
        )
        icon_label.pack(side="left", padx=5)

        name_label = ctk.CTkLabel(
            title_frame,
            text=app_info["name"],
            font=("Helvetica", 13, "bold"),
            text_color="white",
        )
        name_label.pack(side="left", padx=5)

        # Notes
        notes_label = ctk.CTkLabel(
            info_frame,
            text=f"ℹ️ {app_info.get('notes', '')}",
            font=("Helvetica", 10),
            text_color="#999",
        )
        notes_label.pack(anchor="w", padx=15, pady=2)

        # Buttons
        btn_frame = ctk.CTkFrame(card, fg_color="#1a1a2e")
        btn_frame.pack(side="right", padx=10, pady=10)

        if app_id in self.manager.installed_apps:
            # Run button
            run_btn = ctk.CTkButton(
                btn_frame,
                text="▶️ RUN",
                command=lambda: self.run_app(app_id),
                fg_color=COLOR_CYAN,
                text_color=COLOR_DARK,
                font=("Helvetica", 11, "bold"),
            )
            run_btn.pack(side="left", padx=3)

            # Uninstall button
            uninstall_btn = ctk.CTkButton(
                btn_frame,
                text="🗑️ UNINSTALL",
                command=lambda: self.uninstall_app(app_id),
                fg_color="#cc3333",
                font=("Helvetica", 10),
            )
            uninstall_btn.pack(side="left", padx=3)
        else:
            # Install button
            install_btn = ctk.CTkButton(
                btn_frame,
                text="⬇️ INSTALL",
                command=lambda: self.install_app(app_id),
                fg_color=COLOR_PURPLE,
                font=("Helvetica", 11, "bold"),
            )
            install_btn.pack(side="left", padx=3)

            # Help button
            help_btn = ctk.CTkButton(
                btn_frame,
                text="❓",
                command=lambda: self.show_help(app_id),
                fg_color="#555",
                font=("Helvetica", 11),
                width=30,
            )
            help_btn.pack(side="left", padx=3)

    def clear_content(self):
        """Limpiar contenido"""
        for widget in self.content_frame.winfo_children():
            widget.destroy()

    def install_app(self, app_id):
        """Instalar app"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Install Windows App")
        dialog.geometry("400x300")

        label = ctk.CTkLabel(
            dialog,
            text=f"Installing {app_id}...",
            font=("Helvetica", 14),
        )
        label.pack(pady=20)

        progress = ctk.CTkProgressBar(dialog)
        progress.pack(fill="x", padx=20, pady=10)

        # Simular instalación
        def install_thread():
            for i in range(0, 101, 10):
                progress.set(i / 100)
                dialog.update()
                __import__("time").sleep(0.5)

            self.manager.installed_apps[app_id] = True
            self.manager.save_installed_apps()

            dialog.destroy()
            self.show_games()  # Refresh

        thread = threading.Thread(target=install_thread, daemon=True)
        thread.start()

    def run_app(self, app_id):
        """Ejecutar app"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Running...")
        dialog.geometry("300x100")

        label = ctk.CTkLabel(
            dialog,
            text=f"🪟 {app_id} is running...",
            font=("Helvetica", 12),
        )
        label.pack(pady=20)

        # En versión real: ejecutar la app
        # self.manager.run_app(app_id, exe_path)

        dialog.after(2000, dialog.destroy)

    def uninstall_app(self, app_id):
        """Desinstalar app"""
        if app_id in self.manager.installed_apps:
            del self.manager.installed_apps[app_id]
            self.manager.save_installed_apps()
            self.show_games()

    def install_custom(self):
        """Instalar app personalizada"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Install Custom App")
        dialog.geometry("400x250")

        label = ctk.CTkLabel(
            dialog,
            text="Selecciona el .exe de Windows",
            font=("Helvetica", 12),
        )
        label.pack(pady=10)

        path_entry = ctk.CTkEntry(dialog)
        path_entry.pack(fill="x", padx=20, pady=5)

        name_entry = ctk.CTkEntry(dialog)
        name_entry.pack(fill="x", padx=20, pady=5)
        name_entry.insert(0, "App Name")

        def install():
            path = path_entry.get()
            name = name_entry.get()

            if path and name:
                self.manager.installed_apps[name] = {
                    "path": path,
                    "type": "custom",
                }
                self.manager.save_installed_apps()
                dialog.destroy()
                self.show_games()

        btn = ctk.CTkButton(
            dialog,
            text="INSTALL",
            command=install,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
        )
        btn.pack(pady=10)

    def show_help(self, app_id):
        """Mostrar ayuda de instalación"""
        app_info = self.manager.get_app_info(app_id)

        dialog = ctk.CTkToplevel(self)
        dialog.title(f"{app_id} - Installation Help")
        dialog.geometry("400x300")

        help_text = ctk.CTkLabel(
            dialog,
            text=f"""
{app_id}

Setup Method: {app_info.get('setup', 'manual')}

{app_info.get('notes', '')}

INSTALLATION:
1. Get the Windows installer
2. Click INSTALL
3. Follow the setup wizard
4. Click RUN to launch

COMPATIBILITY:
Wine/Proton enabled
DirectX → Vulkan translation
Controller support ready
            """,
            justify="left",
            font=("Courier", 10),
        )
        help_text.pack(fill="both", expand=True, padx=10, pady=10)
