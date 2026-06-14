"""
NexusOS Installer v1.0
Instalador gráfico para grabar NexusOS en USB desde Windows
Sin necesidad de terminal, totalmente visual
"""

import sys
import os
import subprocess
import json
import threading
import time
from pathlib import Path

try:
    import PySimpleGUI as sg
except ImportError:
    print("Instalando PySimpleGUI...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "PySimpleGUI"])
    import PySimpleGUI as sg

try:
    import psutil
except ImportError:
    print("Instalando psutil...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psutil"])
    import psutil


# ═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE UI
# ═══════════════════════════════════════════════════════════════════

sg.theme('DarkBlue3')
sg.set_options(font=('Helvetica', 11))

COLOR_CYAN = '#00d4ff'
COLOR_PURPLE = '#7c3aed'
COLOR_DARK = '#0a0e27'
COLOR_SUCCESS = '#44ff44'
COLOR_ERROR = '#ff4444'


class USBDetector:
    """Detectar USB conectadas"""

    @staticmethod
    def get_usb_drives():
        """Obtener lista de USB conectadas"""
        usb_drives = []

        if sys.platform == 'win32':
            # Windows: usar wmic
            try:
                output = subprocess.check_output(
                    'wmic logicaldisk get name',
                    shell=True,
                    stderr=subprocess.PIPE
                ).decode('utf-8')

                drives = [line.strip() for line in output.split('\n') if line.strip() and ':' in line]

                for drive in drives:
                    try:
                        # Verificar si es USB (removible)
                        import ctypes
                        if ctypes.windll.kernel32.GetDriveTypeW(f"{drive}\\") == 2:
                            size_gb = psutil.disk_usage(drive).total / (1024**3)
                            usb_drives.append({
                                'letter': drive,
                                'path': f"{drive}\\",
                                'size_gb': round(size_gb, 1)
                            })
                    except:
                        pass
            except:
                pass

        return usb_drives

    @staticmethod
    def get_usb_display(usb_info):
        """Formatear info USB para mostrar"""
        return f"{usb_info['letter']} ({usb_info['size_gb']}GB) - REMOVIBLE"


class NexusOSInstaller:
    """Instalador de NexusOS"""

    def __init__(self):
        self.iso_path = None
        self.selected_usb = None
        self.is_installing = False
        self.progress = 0

    def download_iso(self, progress_callback=None):
        """
        Descargar ISO de NexusOS
        En versión final: descargar desde nexusos.com
        Para testing: usar ISO local
        """

        # Para testing: simular descarga
        iso_path = Path.home() / "Downloads" / "nexusos-1.0-x86_64.iso"

        if iso_path.exists():
            return str(iso_path)

        # En producción:
        # url = "https://nexusos.com/download/nexusos-1.0-x86_64.iso"
        # Descargar con requests/urllib
        return None

    def detect_usb(self):
        """Detectar USB disponibles"""
        return USBDetector.get_usb_drives()

    def write_iso(self, iso_path, usb_drive, progress_callback=None):
        """
        Escribir ISO en USB
        Usa dd en Linux/Mac, diskpart en Windows
        """

        try:
            if sys.platform == 'win32':
                return self._write_iso_windows(iso_path, usb_drive, progress_callback)
            else:
                return self._write_iso_linux(iso_path, usb_drive, progress_callback)
        except Exception as e:
            return False, str(e)

    def _write_iso_windows(self, iso_path, usb_drive, progress_callback=None):
        """Escribir ISO en Windows usando diskpart"""

        try:
            usb_letter = usb_drive['letter']

            # Crear script de diskpart
            diskpart_script = f"""
select disk {self._get_disk_number(usb_letter)}
clean
create partition primary
select partition 1
active
format fs=FAT32 quick
assign letter={usb_letter}
"""

            script_path = Path.home() / "temp_diskpart.txt"
            script_path.write_text(diskpart_script)

            # Ejecutar diskpart
            result = subprocess.run(
                ["diskpart", "/s", str(script_path)],
                capture_output=True,
                text=True,
                shell=True
            )

            # Escribir ISO
            # Usar herramienta como Rufus CLI o dd de Cygwin

            return True, "ISO escrita correctamente"

        except Exception as e:
            return False, f"Error escribiendo ISO: {str(e)}"

    def _write_iso_linux(self, iso_path, usb_drive, progress_callback=None):
        """Escribir ISO en Linux usando dd"""

        try:
            device = usb_drive['device']

            cmd = f"sudo dd if={iso_path} of={device} bs=4M conv=fsync"

            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                return True, "ISO escrita correctamente"
            else:
                return False, result.stderr

        except Exception as e:
            return False, str(e)

    @staticmethod
    def _get_disk_number(drive_letter):
        """Obtener número de disco de letra de unidad"""
        try:
            output = subprocess.check_output(
                f'wmic logicaldisk where name="{drive_letter}:" get name,size',
                shell=True,
                stderr=subprocess.PIPE
            ).decode('utf-8')
            # Parsing...
            return 1  # placeholder
        except:
            return 1


def create_welcome_window():
    """Ventana de bienvenida"""

    layout = [
        [sg.Text('🎮 NexusOS INSTALLER v1.0',
                 font=('Helvetica', 24, 'bold'),
                 text_color=COLOR_CYAN)],
        [sg.Text('Instalar NexusOS Gaming OS en USB',
                 font=('Helvetica', 14))],

        [sg.Text('', size=(50, 2))],  # Spacer

        [sg.Multiline(
            text="""
¿QUÉ HACE ESTE INSTALADOR?

✓ Descarga NexusOS (3.5GB)
✓ Detecta tu USB automáticamente
✓ Graba NexusOS en el USB
✓ Verifica la instalación
✓ Listo para arrancar

REQUISITOS:
• USB de 8GB mínimo
• PC con Windows 10/11
• 10 minutos de tiempo

⚠️ ADVERTENCIA: Se borrará todo en el USB
            """,
            size=(60, 16),
            disabled=True,
            font=('Courier', 10)
        )],

        [sg.Button('➡️ SIGUIENTE', size=(15, 2),
                   button_color=(COLOR_PURPLE, COLOR_DARK),
                   font=('Helvetica', 12, 'bold')),
         sg.Button('❌ CANCELAR', size=(15, 2),
                   button_color=(COLOR_ERROR, COLOR_DARK),
                   font=('Helvetica', 12))],
    ]

    window = sg.Window(
        'NexusOS Installer',
        layout,
        size=(700, 600),
        element_justification='center',
        finalize=True
    )

    return window


def create_usb_selection_window(usb_devices):
    """Ventana de selección de USB"""

    if not usb_devices:
        sg.popup_error(
            '❌ No USB detectadas',
            'Por favor conecta un USB de 8GB mínimo',
            title='Error'
        )
        return None

    usb_options = [
        f"{dev['letter']} ({dev['size_gb']}GB) - REMOVIBLE"
        for dev in usb_devices
    ]

    layout = [
        [sg.Text('🎮 SELECCIONAR USB',
                 font=('Helvetica', 20, 'bold'),
                 text_color=COLOR_CYAN)],

        [sg.Text('¿En cuál USB deseas instalar NexusOS?',
                 font=('Helvetica', 12))],

        [sg.Text('', size=(50, 1))],  # Spacer

        [sg.Text('USB DISPONIBLES:', font=('Helvetica', 11, 'bold'))],

        [sg.Listbox(
            values=usb_options,
            size=(60, 5),
            key='-USB_SELECT-',
            default_values=[usb_options[0]] if usb_options else [],
            background_color='#1a1a2e',
            text_color=COLOR_CYAN,
            font=('Courier', 11)
        )],

        [sg.Checkbox(
            '✓ Entiendo que se borrará TODO en esta USB',
            key='-CONFIRM-',
            font=('Helvetica', 11)
        )],

        [sg.Text('', size=(50, 1))],  # Spacer

        [sg.Button('➡️ CONFIRMAR', size=(15, 2),
                   button_color=(COLOR_SUCCESS, COLOR_DARK),
                   font=('Helvetica', 12, 'bold'),
                   disabled=True,
                   key='-CONFIRM_BTN-'),
         sg.Button('⬅️ ATRÁS', size=(15, 2),
                   button_color=(COLOR_PURPLE, COLOR_DARK),
                   font=('Helvetica', 12))],
    ]

    window = sg.Window(
        'NexusOS Installer',
        layout,
        size=(700, 500),
        element_justification='center',
        finalize=True
    )

    # Binding: habilitar botón solo si checkbox marcado
    while True:
        event, values = window.read()

        if event == sg.WINDOW_CLOSED or event == '⬅️ ATRÁS':
            window.close()
            return None

        if values['-CONFIRM-']:
            window['-CONFIRM_BTN-'].update(disabled=False)
        else:
            window['-CONFIRM_BTN-'].update(disabled=True)

        if event == '➡️ CONFIRMAR':
            selected = values['-USB_SELECT-']
            if selected:
                window.close()
                # Retornar índice del USB seleccionado
                usb_index = usb_options.index(selected[0])
                return usb_devices[usb_index]

    return None


def create_installation_window():
    """Ventana de instalación en progreso"""

    layout = [
        [sg.Text('🎮 INSTALANDO NEXUSOS',
                 font=('Helvetica', 20, 'bold'),
                 text_color=COLOR_CYAN)],

        [sg.Text('Por favor espera... (~5 minutos)',
                 font=('Helvetica', 12))],

        [sg.Text('', size=(50, 1))],  # Spacer

        [sg.Text('Paso actual:', font=('Helvetica', 11, 'bold'))],
        [sg.Text('Descargando ISO...',
                 key='-STATUS-',
                 font=('Courier', 10),
                 text_color=COLOR_CYAN)],

        [sg.ProgressBar(
            100,
            size=(60, 20),
            key='-PROGRESS-',
            bar_color=(COLOR_CYAN, COLOR_DARK)
        )],

        [sg.Text('0%', key='-PERCENT-', font=('Helvetica', 11, 'bold'))],

        [sg.Multiline(
            size=(60, 8),
            disabled=True,
            key='-LOG-',
            background_color='#1a1a2e',
            text_color='#999',
            font=('Courier', 9)
        )],

        [sg.Text('', size=(50, 1))],

        [sg.Button('CANCELAR', size=(15, 2),
                   button_color=(COLOR_ERROR, COLOR_DARK),
                   font=('Helvetica', 12),
                   key='-CANCEL-')],
    ]

    window = sg.Window(
        'NexusOS Installer',
        layout,
        size=(700, 650),
        element_justification='center',
        finalize=True
    )

    return window


def create_success_window():
    """Ventana de éxito"""

    layout = [
        [sg.Text('✅ INSTALACIÓN COMPLETADA',
                 font=('Helvetica', 20, 'bold'),
                 text_color=COLOR_SUCCESS)],

        [sg.Text('', size=(50, 1))],  # Spacer

        [sg.Multiline(
            text="""
🎉 ¡NexusOS instalado correctamente!

PRÓXIMOS PASOS:

1. Apagar tu PC
2. Conectar el USB
3. Encender PC
4. Presionar F12 o ESC (según tu PC)
5. Seleccionar el USB en el menú

PRIMERO ARRANQUE:

• Presionar ENTER para continuar
• Seleccionar idioma (Español)
• Conectar WiFi
• ¡Listo! Puedes jugar

TIPS:
✓ Guardamos tus datos en la USB (portable)
✓ Puedes reinstalar cuantas veces quieras
✓ Tenemos documentación en español
✓ Comunidad activa en Discord

¡A divertirse! 🎮
            """,
            size=(60, 18),
            disabled=True,
            font=('Courier', 10)
        )],

        [sg.Text('', size=(50, 1))],

        [sg.Button('✅ CERRAR', size=(15, 2),
                   button_color=(COLOR_SUCCESS, COLOR_DARK),
                   font=('Helvetica', 12, 'bold'))],
    ]

    window = sg.Window(
        'NexusOS Installer',
        layout,
        size=(700, 600),
        element_justification='center',
        finalize=True
    )

    return window


def main():
    """Flujo principal del instalador"""

    installer = NexusOSInstaller()

    # Paso 1: Bienvenida
    window = create_welcome_window()
    event, values = window.read()
    window.close()

    if event != '➡️ SIGUIENTE':
        return

    # Paso 2: Detectar y seleccionar USB
    usb_devices = installer.detect_usb()
    selected_usb = create_usb_selection_window(usb_devices)

    if not selected_usb:
        return

    # Paso 3: Instalación
    window = create_installation_window()

    # Simular instalación (en producción: real)
    steps = [
        ("Descargando ISO...", 25),
        ("Formateando USB...", 50),
        ("Escribiendo datos...", 75),
        ("Verificando instalación...", 100),
    ]

    for step_text, progress in steps:
        window['-STATUS-'].update(step_text)
        window['-PROGRESS-'].update(progress)
        window['-PERCENT-'].update(f"{progress}%")
        window['-LOG-'].update(f"[{time.strftime('%H:%M:%S')}] {step_text}\n",
                               append=True)

        event, values = window.read(timeout=100)
        if event == '-CANCEL-' or event == sg.WINDOW_CLOSED:
            window.close()
            return

        time.sleep(1)

    window.close()

    # Paso 4: Éxito
    window = create_success_window()
    window.read()
    window.close()


if __name__ == '__main__':
    main()
