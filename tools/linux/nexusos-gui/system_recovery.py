"""
System Recovery GUI para NexusOS
Gestión de Snapshots (Snapper) y Backups (Timeshift)
"""

import customtkinter as ctk
from pathlib import Path
import subprocess
import threading
import json
from datetime import datetime
import os

# Colores NexusOS
COLOR_CYAN = "#00d4ff"
COLOR_PURPLE = "#7c3aed"
COLOR_DARK = "#0a0e27"
COLOR_SUCCESS = "#10b981"
COLOR_WARNING = "#f59e0b"
COLOR_ERROR = "#ef4444"


class SystemRecoveryManager:
    """Gestor de recuperación de sistema (Snapper + Timeshift)"""

    def __init__(self):
        self.snapshots = []
        self.backups = []
        self.load_snapshots()
        self.load_backups()

    def load_snapshots(self):
        """Cargar snapshots de Snapper"""
        try:
            result = subprocess.run(
                ["snapper", "-c", "root", "list", "-t", "single", "--json-output"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                data = json.loads(result.stdout)
                self.snapshots = data.get("snapshots", [])
            else:
                self.snapshots = []
        except Exception as e:
            print(f"Error loading snapshots: {e}")
            self.snapshots = []

    def load_backups(self):
        """Cargar backups de Timeshift"""
        try:
            result = subprocess.run(
                ["timeshift", "--list", "--json"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                data = json.loads(result.stdout)
                self.backups = data.get("snapshots", [])
            else:
                self.backups = []
        except Exception as e:
            print(f"Error loading backups: {e}")
            self.backups = []

    def create_snapshot(self, description):
        """Crear snapshot manual"""
        try:
            subprocess.run(
                ["snapper", "-c", "root", "create", "-d", description],
                check=True,
                timeout=30
            )
            self.load_snapshots()
            return True, "Snapshot creado exitosamente"
        except Exception as e:
            return False, str(e)

    def create_backup(self, description):
        """Crear backup manual con Timeshift"""
        try:
            subprocess.run(
                ["timeshift", "--create", "--comments", description],
                check=True,
                timeout=300  # 5 minutos máximo
            )
            self.load_backups()
            return True, "Backup creado exitosamente"
        except Exception as e:
            return False, str(e)

    def restore_snapshot(self, snapshot_num):
        """Restaurar snapshot de Snapper"""
        try:
            # Guardar snapshot actual primero
            subprocess.run(
                ["snapper", "-c", "root", "create", "-d", "Before Restore"],
                check=True
            )

            # Restaurar
            subprocess.run(
                ["snapper", "-c", "root", "undochange", str(snapshot_num) + "..0"],
                check=True,
                timeout=120
            )
            self.load_snapshots()
            return True, f"Sistema restaurado a snapshot #{snapshot_num}"
        except Exception as e:
            return False, str(e)

    def restore_backup(self, backup_path):
        """Restaurar backup de Timeshift"""
        try:
            subprocess.run(
                ["timeshift", "--restore", "--snapshot", backup_path],
                check=True,
                timeout=600
            )
            self.load_backups()
            return True, "Sistema restaurado desde backup"
        except Exception as e:
            return False, str(e)

    def delete_snapshot(self, snapshot_num):
        """Eliminar snapshot"""
        try:
            subprocess.run(
                ["snapper", "-c", "root", "delete", str(snapshot_num)],
                check=True
            )
            self.load_snapshots()
            return True, f"Snapshot #{snapshot_num} eliminado"
        except Exception as e:
            return False, str(e)

    def delete_backup(self, backup_path):
        """Eliminar backup"""
        try:
            subprocess.run(
                ["timeshift", "--delete", "--snapshot", backup_path],
                check=True
            )
            self.load_backups()
            return True, "Backup eliminado"
        except Exception as e:
            return False, str(e)

    def get_disk_usage(self):
        """Obtener uso de disco de snapshots"""
        try:
            result = subprocess.run(
                ["btrfs", "filesystem", "usage", "/"],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.stdout if result.returncode == 0 else "No disponible"
        except:
            return "No disponible"


class SystemRecoveryFrame(ctk.CTkFrame):
    """Frame principal de recuperación de sistema"""

    def __init__(self, parent):
        super().__init__(parent, fg_color=COLOR_DARK)

        self.manager = SystemRecoveryManager()
        self.create_widgets()
        self.refresh_data()

    def create_widgets(self):
        """Crear interfaz"""

        # Header
        header = ctk.CTkFrame(self, fg_color=COLOR_DARK)
        header.pack(fill="x", padx=20, pady=10)

        title = ctk.CTkLabel(
            header,
            text="💾 SYSTEM RECOVERY",
            font=("Helvetica", 24, "bold"),
            text_color=COLOR_CYAN,
        )
        title.pack(side="left")

        info_label = ctk.CTkLabel(
            header,
            text="Snapshots del sistema y backups automáticos",
            font=("Helvetica", 11),
            text_color="#999",
        )
        info_label.pack(side="left", padx=20)

        # Tabs
        tab_frame = ctk.CTkFrame(self, fg_color=COLOR_DARK)
        tab_frame.pack(fill="x", padx=20, pady=10)

        self.snapshots_btn = ctk.CTkButton(
            tab_frame,
            text="📸 SNAPSHOTS (Snapper)",
            command=self.show_snapshots,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
            font=("Helvetica", 12, "bold"),
        )
        self.snapshots_btn.pack(side="left", padx=5)

        self.backups_btn = ctk.CTkButton(
            tab_frame,
            text="📁 BACKUPS (Timeshift)",
            command=self.show_backups,
            fg_color=COLOR_PURPLE,
            font=("Helvetica", 12),
        )
        self.backups_btn.pack(side="left", padx=5)

        # Content area
        self.content_frame = ctk.CTkScrollableFrame(
            self, fg_color=COLOR_DARK
        )
        self.content_frame.pack(
            fill="both", expand=True, padx=20, pady=10
        )

        self.show_snapshots()

    def show_snapshots(self):
        """Mostrar snapshots de Snapper"""
        self.clear_content()
        self.snapshots_btn.configure(fg_color=COLOR_CYAN, text_color=COLOR_DARK)
        self.backups_btn.configure(fg_color=COLOR_PURPLE, text_color="white")

        # Button crear snapshot
        btn_frame = ctk.CTkFrame(self.content_frame, fg_color=COLOR_DARK)
        btn_frame.pack(fill="x", padx=5, pady=10)

        create_btn = ctk.CTkButton(
            btn_frame,
            text="+ CREAR SNAPSHOT",
            command=self.create_snapshot_dialog,
            fg_color=COLOR_SUCCESS,
            text_color="white",
            font=("Helvetica", 12, "bold"),
        )
        create_btn.pack(side="left", padx=5)

        refresh_btn = ctk.CTkButton(
            btn_frame,
            text="🔄 REFRESCAR",
            command=self.refresh_snapshots,
            fg_color="#555",
            font=("Helvetica", 11),
        )
        refresh_btn.pack(side="left", padx=5)

        # Info
        info_label = ctk.CTkLabel(
            self.content_frame,
            text=f"Total: {len(self.manager.snapshots)} snapshots",
            font=("Helvetica", 10),
            text_color="#999",
        )
        info_label.pack(anchor="w", padx=10, pady=5)

        # Snapshots list
        if not self.manager.snapshots:
            empty_label = ctk.CTkLabel(
                self.content_frame,
                text="No hay snapshots. Crea uno con el botón arriba.",
                font=("Helvetica", 11),
                text_color="#666",
            )
            empty_label.pack(pady=20)
        else:
            for snap in self.manager.snapshots[::-1]:  # Inverso para mostrar últimos primero
                self.create_snapshot_card(snap)

    def show_backups(self):
        """Mostrar backups de Timeshift"""
        self.clear_content()
        self.snapshots_btn.configure(fg_color="#555", text_color="white")
        self.backups_btn.configure(fg_color=COLOR_PURPLE, text_color="white")

        # Button crear backup
        btn_frame = ctk.CTkFrame(self.content_frame, fg_color=COLOR_DARK)
        btn_frame.pack(fill="x", padx=5, pady=10)

        create_btn = ctk.CTkButton(
            btn_frame,
            text="+ CREAR BACKUP",
            command=self.create_backup_dialog,
            fg_color=COLOR_SUCCESS,
            text_color="white",
            font=("Helvetica", 12, "bold"),
        )
        create_btn.pack(side="left", padx=5)

        refresh_btn = ctk.CTkButton(
            btn_frame,
            text="🔄 REFRESCAR",
            command=self.refresh_backups,
            fg_color="#555",
            font=("Helvetica", 11),
        )
        refresh_btn.pack(side="left", padx=5)

        # Info
        info_label = ctk.CTkLabel(
            self.content_frame,
            text=f"Total: {len(self.manager.backups)} backups",
            font=("Helvetica", 10),
            text_color="#999",
        )
        info_label.pack(anchor="w", padx=10, pady=5)

        # Backups list
        if not self.manager.backups:
            empty_label = ctk.CTkLabel(
                self.content_frame,
                text="No hay backups. El primero se creará automáticamente mañana.",
                font=("Helvetica", 11),
                text_color="#666",
            )
            empty_label.pack(pady=20)
        else:
            for backup in self.manager.backups[::-1]:
                self.create_backup_card(backup)

    def create_snapshot_card(self, snapshot):
        """Crear card para un snapshot"""
        card = ctk.CTkFrame(self.content_frame, fg_color="#1a1a2e")
        card.pack(fill="x", padx=5, pady=5)

        # Info
        info_frame = ctk.CTkFrame(card, fg_color="#1a1a2e")
        info_frame.pack(side="left", fill="both", expand=True, padx=10, pady=10)

        # ID + Descripción
        title_frame = ctk.CTkFrame(info_frame, fg_color="#1a1a2e")
        title_frame.pack(fill="x")

        snap_id = snapshot.get("number", "?")
        snap_desc = snapshot.get("description", "Sin descripción")

        id_label = ctk.CTkLabel(
            title_frame,
            text=f"#{snap_id}",
            font=("Helvetica", 13, "bold"),
            text_color=COLOR_CYAN,
        )
        id_label.pack(side="left", padx=5)

        desc_label = ctk.CTkLabel(
            title_frame,
            text=snap_desc,
            font=("Helvetica", 12),
            text_color="white",
        )
        desc_label.pack(side="left", padx=5)

        # Fecha
        snap_time = snapshot.get("date", "")
        time_label = ctk.CTkLabel(
            info_frame,
            text=f"📅 {snap_time}",
            font=("Helvetica", 9),
            text_color="#999",
        )
        time_label.pack(anchor="w", padx=15, pady=2)

        # Buttons
        btn_frame = ctk.CTkFrame(card, fg_color="#1a1a2e")
        btn_frame.pack(side="right", padx=10, pady=10)

        restore_btn = ctk.CTkButton(
            btn_frame,
            text="↩️ RESTORE",
            command=lambda: self.restore_snapshot_dialog(snap_id),
            fg_color=COLOR_WARNING,
            text_color="white",
            font=("Helvetica", 10, "bold"),
        )
        restore_btn.pack(side="left", padx=3)

        delete_btn = ctk.CTkButton(
            btn_frame,
            text="🗑️ DELETE",
            command=lambda: self.delete_snapshot(snap_id),
            fg_color=COLOR_ERROR,
            font=("Helvetica", 10),
        )
        delete_btn.pack(side="left", padx=3)

    def create_backup_card(self, backup):
        """Crear card para un backup"""
        card = ctk.CTkFrame(self.content_frame, fg_color="#1a1a2e")
        card.pack(fill="x", padx=5, pady=5)

        # Info
        info_frame = ctk.CTkFrame(card, fg_color="#1a1a2e")
        info_frame.pack(side="left", fill="both", expand=True, padx=10, pady=10)

        # Nombre + Descripción
        title_frame = ctk.CTkFrame(info_frame, fg_color="#1a1a2e")
        title_frame.pack(fill="x")

        backup_name = backup.get("name", "Backup")
        backup_desc = backup.get("comments", "")

        name_label = ctk.CTkLabel(
            title_frame,
            text=backup_name,
            font=("Helvetica", 12, "bold"),
            text_color=COLOR_CYAN,
        )
        name_label.pack(side="left", padx=5)

        if backup_desc:
            desc_label = ctk.CTkLabel(
                title_frame,
                text=f"({backup_desc})",
                font=("Helvetica", 10),
                text_color="#999",
            )
            desc_label.pack(side="left", padx=5)

        # Tamaño
        backup_size = backup.get("size", "~2GB")
        size_label = ctk.CTkLabel(
            info_frame,
            text=f"💾 {backup_size}",
            font=("Helvetica", 9),
            text_color="#999",
        )
        size_label.pack(anchor="w", padx=15, pady=2)

        # Buttons
        btn_frame = ctk.CTkFrame(card, fg_color="#1a1a2e")
        btn_frame.pack(side="right", padx=10, pady=10)

        restore_btn = ctk.CTkButton(
            btn_frame,
            text="↩️ RESTORE",
            command=lambda: self.restore_backup_dialog(backup_name),
            fg_color=COLOR_WARNING,
            text_color="white",
            font=("Helvetica", 10, "bold"),
        )
        restore_btn.pack(side="left", padx=3)

        delete_btn = ctk.CTkButton(
            btn_frame,
            text="🗑️ DELETE",
            command=lambda: self.delete_backup(backup_name),
            fg_color=COLOR_ERROR,
            font=("Helvetica", 10),
        )
        delete_btn.pack(side="left", padx=3)

    def create_snapshot_dialog(self):
        """Diálogo para crear snapshot"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Crear Snapshot")
        dialog.geometry("400x250")

        label = ctk.CTkLabel(
            dialog,
            text="Descripción del snapshot",
            font=("Helvetica", 12),
        )
        label.pack(pady=10)

        entry = ctk.CTkEntry(dialog, placeholder_text="Ej: Antes de instalar Steam")
        entry.pack(fill="x", padx=20, pady=5)

        def create():
            desc = entry.get() or "Manual snapshot"
            success, msg = self.manager.create_snapshot(desc)
            self.refresh_snapshots()
            dialog.destroy()

            # Mostrar resultado
            self.show_message(msg if success else f"Error: {msg}", success)

        btn = ctk.CTkButton(
            dialog,
            text="CREAR",
            command=create,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
        )
        btn.pack(pady=10)

    def create_backup_dialog(self):
        """Diálogo para crear backup"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Crear Backup")
        dialog.geometry("400x250")

        label = ctk.CTkLabel(
            dialog,
            text="Descripción del backup",
            font=("Helvetica", 12),
        )
        label.pack(pady=10)

        entry = ctk.CTkEntry(dialog, placeholder_text="Ej: Antes de jugar Elden Ring")
        entry.pack(fill="x", padx=20, pady=5)

        def create():
            desc = entry.get() or "Manual backup"
            success, msg = self.manager.create_backup(desc)
            self.refresh_backups()
            dialog.destroy()
            self.show_message(msg if success else f"Error: {msg}", success)

        btn = ctk.CTkButton(
            dialog,
            text="CREAR",
            command=create,
            fg_color=COLOR_CYAN,
            text_color=COLOR_DARK,
        )
        btn.pack(pady=10)

    def restore_snapshot_dialog(self, snap_id):
        """Confirmar restauración de snapshot"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Restaurar Snapshot")
        dialog.geometry("400x200")

        label = ctk.CTkLabel(
            dialog,
            text=f"¿Restaurar snapshot #{snap_id}?\n\nEl sistema volverá a ese punto.",
            font=("Helvetica", 11),
        )
        label.pack(pady=20)

        btn_frame = ctk.CTkFrame(dialog, fg_color=dialog.cget("fg_color"))
        btn_frame.pack(pady=10)

        def restore():
            success, msg = self.manager.restore_snapshot(snap_id)
            dialog.destroy()
            self.show_message(msg if success else f"Error: {msg}", success)

        yes_btn = ctk.CTkButton(
            btn_frame,
            text="SÍ, RESTAURAR",
            command=restore,
            fg_color=COLOR_WARNING,
            text_color="white",
        )
        yes_btn.pack(side="left", padx=5)

        no_btn = ctk.CTkButton(
            btn_frame,
            text="Cancelar",
            command=dialog.destroy,
            fg_color="#555",
        )
        no_btn.pack(side="left", padx=5)

    def restore_backup_dialog(self, backup_name):
        """Confirmar restauración de backup"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Restaurar Backup")
        dialog.geometry("400x200")

        label = ctk.CTkLabel(
            dialog,
            text=f"¿Restaurar backup {backup_name}?\n\nEl sistema volverá completamente a ese punto.",
            font=("Helvetica", 11),
        )
        label.pack(pady=20)

        btn_frame = ctk.CTkFrame(dialog, fg_color=dialog.cget("fg_color"))
        btn_frame.pack(pady=10)

        def restore():
            success, msg = self.manager.restore_backup(backup_name)
            dialog.destroy()
            self.show_message(msg if success else f"Error: {msg}", success)

        yes_btn = ctk.CTkButton(
            btn_frame,
            text="SÍ, RESTAURAR",
            command=restore,
            fg_color=COLOR_WARNING,
            text_color="white",
        )
        yes_btn.pack(side="left", padx=5)

        no_btn = ctk.CTkButton(
            btn_frame,
            text="Cancelar",
            command=dialog.destroy,
            fg_color="#555",
        )
        no_btn.pack(side="left", padx=5)

    def delete_snapshot(self, snap_id):
        """Eliminar snapshot"""
        success, msg = self.manager.delete_snapshot(snap_id)
        self.refresh_snapshots()
        self.show_message(msg if success else f"Error: {msg}", success)

    def delete_backup(self, backup_name):
        """Eliminar backup"""
        success, msg = self.manager.delete_backup(backup_name)
        self.refresh_backups()
        self.show_message(msg if success else f"Error: {msg}", success)

    def refresh_snapshots(self):
        """Actualizar snapshots"""
        self.manager.load_snapshots()
        self.show_snapshots()

    def refresh_backups(self):
        """Actualizar backups"""
        self.manager.load_backups()
        self.show_backups()

    def refresh_data(self):
        """Actualizar datos periódicamente"""
        self.manager.load_snapshots()
        self.manager.load_backups()
        self.after(30000, self.refresh_data)  # Cada 30 segundos

    def clear_content(self):
        """Limpiar contenido"""
        for widget in self.content_frame.winfo_children():
            widget.destroy()

    def show_message(self, msg, success):
        """Mostrar mensaje"""
        dialog = ctk.CTkToplevel(self)
        dialog.title("Resultado")
        dialog.geometry("300x100")

        color = COLOR_SUCCESS if success else COLOR_ERROR
        label = ctk.CTkLabel(
            dialog,
            text=msg,
            font=("Helvetica", 11),
            text_color=color,
        )
        label.pack(pady=20)

        ok_btn = ctk.CTkButton(
            dialog,
            text="OK",
            command=dialog.destroy,
            fg_color=color,
            text_color="white",
        )
        ok_btn.pack(pady=5)

        dialog.after(5000, dialog.destroy)  # Auto-close después de 5s
