#!/bin/bash
# NexusOS Control Center Launcher
# Script que ejecuta la interfaz gráfica de forma amigable

set -e

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUI_DIR="$SCRIPT_DIR/nexusos-gui"
LOG_DIR="$HOME/.nexusos/logs"

# Crear directorio de logs
mkdir -p "$LOG_DIR"

# Archivo de log
LOG_FILE="$LOG_DIR/nexusos-gui-$(date +%Y%m%d-%H%M%S).log"

echo "Starting NexusOS Control Center..." | tee "$LOG_FILE"

# Verificar dependencias
check_dependencies() {
    echo "Checking dependencies..." | tee -a "$LOG_FILE"

    local missing_deps=0
    local PIP_CMD="pip3"

    # Python
    if ! command -v python3 &> /dev/null; then
        echo "ERROR: Python 3 not found" | tee -a "$LOG_FILE"
        missing_deps=1
    fi

    # Detectar pip command disponible
    if ! command -v pip3 &> /dev/null; then
        PIP_CMD="pip"
        if ! command -v pip &> /dev/null; then
            echo "ERROR: pip or pip3 not found" | tee -a "$LOG_FILE"
            missing_deps=1
        fi
    fi

    # CustomTkinter
    if ! python3 -c "import customtkinter" 2>/dev/null; then
        echo "Installing customtkinter..." | tee -a "$LOG_FILE"
        if ! $PIP_CMD install customtkinter --quiet; then
            echo "ERROR: Failed to install customtkinter" | tee -a "$LOG_FILE"
            missing_deps=1
        fi
    fi

    # PSUtil
    if ! python3 -c "import psutil" 2>/dev/null; then
        echo "Installing psutil..." | tee -a "$LOG_FILE"
        if ! $PIP_CMD install psutil --quiet; then
            echo "ERROR: Failed to install psutil" | tee -a "$LOG_FILE"
            missing_deps=1
        fi
    fi

    # Pillow
    if ! python3 -c "import PIL" 2>/dev/null; then
        echo "Installing Pillow..." | tee -a "$LOG_FILE"
        if ! $PIP_CMD install Pillow --quiet; then
            echo "ERROR: Failed to install Pillow" | tee -a "$LOG_FILE"
            missing_deps=1
        fi
    fi

    if [ $missing_deps -eq 1 ]; then
        echo "Missing dependencies or installation failed. Please install manually." | tee -a "$LOG_FILE"
        exit 1
    fi

    echo "All dependencies OK" | tee -a "$LOG_FILE"
}

# Ejecutar GUI
run_gui() {
    echo "Launching NexusOS Control Center..." | tee -a "$LOG_FILE"

    cd "$GUI_DIR"

    # Ejecutar main.py
    python3 main.py 2>&1 | tee -a "$LOG_FILE"

    if [ $? -eq 0 ]; then
        echo "NexusOS Control Center closed normally" | tee -a "$LOG_FILE"
    else
        echo "ERROR: GUI crashed" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Error handler
handle_error() {
    local exit_code=$?
    echo "ERROR: Script failed with exit code $exit_code" | tee -a "$LOG_FILE"

    # Mostrar último error al usuario
    notify-send "NexusOS Error" "Control Center crashed. Check logs at $LOG_FILE" 2>/dev/null || true

    exit $exit_code
}

trap handle_error ERR

# Main
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎮 NexusOS Control Center v1.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_dependencies
echo ""
run_gui

echo ""
echo "Thank you for using NexusOS!"
echo "Log saved to: $LOG_FILE"
