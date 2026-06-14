"""
Gaming Hub para NexusOS
Gestor de juegos con interfaz visual
"""

import customtkinter as ctk
from PIL import Image, ImageDraw
import os
import json
from pathlib import Path
import subprocess
import threading

# Colores NexusOS
COLOR_CYAN = "#00d4ff"
COLOR_PURPLE = "#7c3aed"
COLOR_DARK = "#0a0e27"


class GameEntry:
    """Representa un juego"""

    def __init__(self, name, path, emulator, cover_path=None):
        self.name = name
        self.path = path
        self.emulator = emulator
        self.cover_path = cover_path or self._get_default_cover()

    def _get_default_cover(self):
        """Generar cover placeholder"""
        img = Image.new('RGB', (200, 280), color=COLOR_PURPLE)
        draw = ImageDraw.Draw(img)
        draw.text((10, 130), self.name[:20], fill=COLOR_CYAN)
        return img

    def to_dict(self):
        return {
            'name': self.name,
            'path': self.path,
            'emulator': self.emulator,
            'cover_path': self.cover_path
        }


class GameLibrary:
    """Gestor de librería de juegos"""

    EMULATOR_MAP = {
        '.nes': 'retroarch',
        '.snes': 'retroarch',
        '.n64': 'retroarch',
        '.gba': 'retroarch',
        '.gbc': 'retroarch',
        '.z64': 'mupen64plus',
        '.iso': 'pcsx2',
        '.bin': 'pcsx2',
        '.nso': 'ryujinx',
        '.xci': 'ryujinx',
        '.nds': 'desmume',
        '.3ds': 'citra',
        '.cdi': 'mednafen',
    }

    def __init__(self, roms_path="/home/gamer/Roms"):
        self.roms_path = Path(roms_path)
        self.games = []
        self.config_dir = Path.home() / ".nexusos"
        self.config_dir.mkdir(exist_ok=True)
        self.library_file = self.config_dir / "library.json"
        self.load_library()

    def scan_roms(self):
        """Escanear carpeta de ROMs y detectar juegos"""
        self.games = []

        if not self.roms_path.exists():
            return []

        # Buscar archivos de juegos recursivamente
        for file_path in self.roms_path.rglob('*'):
            if file_path.is_file():
                ext = file_path.suffix.lower()
                if ext in self.EMULATOR_MAP:
                    game = GameEntry(
                        name=file_path.stem,
                        path=str(file_path),
                        emulator=self.EMULATOR_MAP[ext]
                    )
                    self.games.append(game)

        self.save_library()
        return self.games

    def load_library(self):
        """Cargar librería guardada"""
        if self.library_file.exists():
            try:
                with open(self.library_file, 'r') as f:
                    data = json.load(f)
                    self.games = [
                        GameEntry(**game) for game in data.get('games', [])
                    ]
            except:
                self.games = []

    def save_library(self):
        """Guardar librería"""
        try:
            with open(self.library_file, 'w') as f:
                json.dump(
                    {'games': [g.to_dict() for g in self.games]},
                    f,
                    indent=2
                )
        except:
            pass

    def get_recent_games(self, count=6):
        """Obtener últimos juegos jugados"""
        # En versión real: leer del historial
        return self.games[-count:]

    def get_games_by_emulator(self, emulator):
        """Obtener juegos de un emulador específico"""
        return [g for g in self.games if g.emulator == emulator]


class GamingHubFrame(ctk.CTkFrame):
    """Frame principal de Gaming Hub"""

    def __init__(self, parent):
        super().__init__(parent, fg_color=COLOR_DARK)

        self.library = GameLibrary()

        self.create_widgets()
        self.load_games()

    def create_widgets(self):
        """Crear widgets de UI"""

        # Header
        header = ctk.CTkFrame(self, fg_color=COLOR_DARK)
        header.pack(fill="x", padx=20, pady=10)

        title = ctk.CTkLabel(
            header,
            text="🎮 GAMING HUB",
            font=("Helvetica", 24, "bold"),
            text_color=COLOR_CYAN
        )
        title.pack(side="left")

        # Botones de acción
        action_frame = ctk.CTkFrame(header, fg_color=COLOR_DARK)
        action_frame.pack(side="right")

        self.load_btn = ctk.CTkButton(
            action_frame,
            text="📁 LOAD ROMs",
            command=self.load_roms_dialog,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
            font=("Helvetica", 12, "bold")
        )
        self.load_btn.pack(side="left", padx=5)

        config_btn = ctk.CTkButton(
            action_frame,
            text="⚙️ SETTINGS",
            command=self.settings_dialog,
            fg_color=COLOR_PURPLE,
            font=("Helvetica", 12)
        )
        config_btn.pack(side="left", padx=5)

        # Filtro por emulador
        filter_frame = ctk.CTkFrame(self, fg_color=COLOR_DARK)
        filter_frame.pack(fill="x", padx=20, pady=5)

        ctk.CTkLabel(
            filter_frame,
            text="EMULATOR:",
            font=("Helvetica", 11)
        ).pack(side="left", padx=5)

        self.filter_var = ctk.StringVar(value="all")
        for emu in ["all", "retroarch", "pcsx2", "ryujinx", "citra"]:
            rb = ctk.CTkRadioButton(
                filter_frame,
                text=emu,
                variable=self.filter_var,
                value=emu,
                command=self.apply_filter
            )
            rb.pack(side="left", padx=5)

        # Content area
        content = ctk.CTkScrollableFrame(self, fg_color=COLOR_DARK)
        content.pack(fill="both", expand=True, padx=20, pady=10)

        # Game cards container
        self.games_grid = ctk.CTkFrame(content, fg_color=COLOR_DARK)
        self.games_grid.pack(fill="both", expand=True)

        self.game_cards = []

    def load_games(self):
        """Cargar y mostrar juegos"""
        # Limpiar
        for card in self.game_cards:
            card.destroy()
        self.game_cards = []

        games = self.library.get_recent_games()

        if not games:
            empty_label = ctk.CTkLabel(
                self.games_grid,
                text="📁 Click 'LOAD ROMs' para agregar juegos",
                font=("Helvetica", 14),
                text_color="#999"
            )
            empty_label.pack(expand=True)
            return

        # Mostrar en grid
        for i, game in enumerate(games):
            row = i // 3
            col = i % 3

            card = self.create_game_card(self.games_grid, game)
            card.grid(row=row, column=col, padx=10, pady=10, sticky="n")
            self.game_cards.append(card)

    def create_game_card(self, parent, game):
        """Crear card visual para un juego"""
        card = ctk.CTkFrame(parent, fg_color="#1a1a2e", width=200)

        # Cover image placeholder
        cover_label = ctk.CTkLabel(
            card,
            text=game.name[:15],
            text_color=COLOR_CYAN,
            font=("Helvetica", 12, "bold"),
            width=200,
            height=150
        )
        cover_label.pack(padx=5, pady=5, fill="both", expand=True)

        # Game name
        name_label = ctk.CTkLabel(
            card,
            text=game.name,
            font=("Helvetica", 10),
            text_color="white"
        )
        name_label.pack(padx=5, pady=2, fill="x")

        # Emulator
        emu_label = ctk.CTkLabel(
            card,
            text=f"📀 {game.emulator}",
            font=("Helvetica", 9),
            text_color="#999"
        )
        emu_label.pack(padx=5, pady=2)

        # Buttons
        btn_frame = ctk.CTkFrame(card, fg_color="#1a1a2e")
        btn_frame.pack(fill="x", padx=5, pady=5)

        play_btn = ctk.CTkButton(
            btn_frame,
            text="▶️ PLAY",
            command=lambda: self.play_game(game),
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
            font=("Helvetica", 10, "bold"),
            height=30
        )
        play_btn.pack(fill="x", pady=2)

        delete_btn = ctk.CTkButton(
            btn_frame,
            text="🗑️ DELETE",
            command=lambda: self.delete_game(game),
            fg_color="#cc3333",
            font=("Helvetica", 10),
            height=25
        )
        delete_btn.pack(fill="x")

        return card

    def play_game(self, game):
        """Ejecutar juego"""
        print(f"Playing {game.name} with {game.emulator}")

        # En versión real: lanzar emulador
        # subprocess.Popen([game.emulator, game.path])

        # Por ahora: mostrar mensaje
        dialog = ctk.CTkToplevel(self)
        dialog.title("Launching...")
        dialog.geometry("300x150")

        label = ctk.CTkLabel(
            dialog,
            text=f"🎮 Launching {game.name}...",
            font=("Helvetica", 14)
        )
        label.pack(expand=True)

    def delete_game(self, game):
        """Eliminar juego de librería"""
        self.library.games.remove(game)
        self.library.save_library()
        self.load_games()

    def load_roms_dialog(self):
        """Diálogo para cargar ROMs"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Load ROMs")
        dialog.geometry("400x200")

        label = ctk.CTkLabel(
            dialog,
            text="Selecciona carpeta de ROMs",
            font=("Helvetica", 12)
        )
        label.pack(pady=10)

        path_entry = ctk.CTkEntry(dialog)
        path_entry.pack(fill="x", padx=10, pady=5)
        path_entry.insert(0, str(self.library.roms_path))

        def scan():
            path = Path(path_entry.get())
            if path.exists():
                self.library.roms_path = path
                self.library.scan_roms()
                self.load_games()
                dialog.destroy()

        btn = ctk.CTkButton(
            dialog,
            text="SCAN",
            command=scan,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK
        )
        btn.pack(pady=10)

    def settings_dialog(self):
        """Diálogo de configuración"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Settings")
        dialog.geometry("400x300")

        # Placeholder
        label = ctk.CTkLabel(
            dialog,
            text="⚙️ Emulator Settings",
            font=("Helvetica", 14)
        )
        label.pack(pady=20)

    def apply_filter(self):
        """Aplicar filtro de emulador"""
        print(f"Filter: {self.filter_var.get()}")
        # En versión real: filtrar juegos
