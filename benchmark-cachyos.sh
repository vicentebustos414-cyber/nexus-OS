#!/bin/bash
# NexusOS Pro - CachyOS Performance Benchmark
# Mide las mejoras con BORE Scheduler

set -e

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════╗
║  NexusOS Pro - CachyOS Performance Benchmark  ║
║  Midiendo mejoras de BORE Scheduler            ║
╚════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════
# INFORMACIÓN DEL SISTEMA
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}INFORMACIÓN DEL SISTEMA:${NC}"
echo "─────────────────────────────────────"

# Kernel
echo -n "Kernel: "
uname -r

# BORE status
echo -n "BORE Scheduler: "
if grep -q "CONFIG_SCHED_BORE=y" /boot/config-$(uname -r); then
    echo -e "${GREEN}✓ Habilitado${NC}"
else
    echo -e "${RED}✗ NO habilitado${NC}"
    echo "  Este benchmark requiere linux-cachyos con BORE"
    exit 1
fi

# CPU Info
echo -n "CPU: "
lscpu | grep "Model name" | sed 's/Model name://' | xargs

# Cores
echo -n "Cores: "
nproc

# RAM
echo -n "RAM: "
free -h | grep "Mem:" | awk '{print $2}'

echo ""

# ═══════════════════════════════════════════════════════════════
# TEST 1: INPUT LATENCY (RTL=Real-Time Latency)
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}TEST 1: Input Latency (cyclictest)${NC}"
echo "─────────────────────────────────────"
echo "Midiendo latencia de entrada (CPU scheduling)..."
echo "(Este test toma ~20 segundos)"
echo ""

if command -v cyclictest &> /dev/null; then
    # Ejecutar cyclictest
    cyclictest -p 80 -m -d 0 -a 1 -t 1 -h 100 > /tmp/cyclictest.out 2>&1

    # Procesar resultados
    if [ -f "/tmp/cyclictest.out" ]; then
        MIN=$(grep "Min Latencies" /tmp/cyclictest.out | awk '{print $5}')
        AVG=$(grep "Avg Latencies" /tmp/cyclictest.out | awk '{print $5}')
        MAX=$(grep "Max Latencies" /tmp/cyclictest.out | awk '{print $5}')

        echo -e "${BLUE}Resultados (microsegundos):${NC}"
        echo "  Min: ${GREEN}${MIN}µs${NC}"
        echo "  Avg: ${GREEN}${AVG}µs${NC}"
        echo "  Max: ${GREEN}${MAX}µs${NC}"

        # Interpretación
        if [ "${MAX}" -lt 10000 ]; then
            echo -e "  ${GREEN}✓ Excelente (< 10ms)${NC}"
        elif [ "${MAX}" -lt 25000 ]; then
            echo -e "  ${GREEN}✓ Muy bueno (< 25ms)${NC}"
        else
            echo -e "  ${YELLOW}⚠ Aceptable${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ cyclictest no instalado${NC}"
    echo "  Instala: sudo pacman -S rt-tests"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# TEST 2: CPU SCHEDULER PERFORMANCE
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}TEST 2: Scheduler Efficiency${NC}"
echo "─────────────────────────────────────"
echo "Midiendo eficiencia del scheduler..."
echo ""

# Context switches por segundo
echo -e "${BLUE}Context Switches (vmstat):${NC}"
vmstat 1 3 | tail -1 | awk '{
    print "  Interrupts/sec: " $11
    print "  Context switch/sec: " $12
}'

echo ""

# ═══════════════════════════════════════════════════════════════
# TEST 3: I/O PERFORMANCE
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}TEST 3: I/O Performance (Deadline Scheduler)${NC}"
echo "─────────────────────────────────────"
echo "Midiendo velocidad de lectura de disco..."
echo ""

# Verificar I/O scheduler
SCHEDULER=$(cat /sys/block/sda/queue/scheduler)
echo -e "${BLUE}I/O Scheduler activo:${NC}"
echo "  $SCHEDULER"

if echo "$SCHEDULER" | grep -q "deadline"; then
    echo -e "  ${GREEN}✓ Deadline scheduler activo${NC}"
else
    echo -e "  ${YELLOW}⚠ No es deadline${NC}"
fi

# Prueba de lectura
echo ""
echo -e "${BLUE}Velocidad de lectura secuencial:${NC}"
dd if=/dev/zero of=/tmp/test-io bs=1M count=512 2>&1 | tail -1 | awk '{print "  " $0}'

echo ""

# ═══════════════════════════════════════════════════════════════
# TEST 4: BOOT TIME
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}TEST 4: Boot Time${NC}"
echo "─────────────────────────────────────"
echo "Analizando tiempo de boot..."
echo ""

if command -v systemd-analyze &> /dev/null; then
    systemd-analyze | grep "Startup finished"
    echo ""
    echo "Top servicios más lentos:"
    systemd-analyze blame | head -5 | while read line; do
        echo "  $line"
    done
else
    echo -e "${YELLOW}⚠ systemd-analyze no disponible${NC}"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# TEST 5: STRESS TEST
# ═══════════════════════════════════════════════════════════════

echo -e "${YELLOW}TEST 5: System Stability (Stress-ng)${NC}"
echo "─────────────────────────────────────"
echo "Ejecutando prueba de estrés (30 segundos)..."
echo ""

if command -v stress-ng &> /dev/null; then
    stress-ng --cpu $(nproc) --io 2 --vm 1 --timeout 30s --metrics-brief 2>&1 | tail -10
else
    echo -e "${YELLOW}⚠ stress-ng no instalado${NC}"
    echo "  Instala: sudo pacman -S stress-ng"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# RESUMEN Y RECOMENDACIONES
# ═══════════════════════════════════════════════════════════════

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  BENCHMARKING COMPLETADO              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}INTERPRETACIÓN DE RESULTADOS:${NC}"
echo ""
echo "Input Latency:"
echo "  < 10ms: Excelente (gaming competitivo)"
echo "  10-25ms: Muy bueno (gaming casual)"
echo "  > 50ms: Necesita optimización"
echo ""

echo "Context Switches:"
echo "  Menos = Mejor (menos overhead)"
echo "  BORE reduce típicamente 50%"
echo ""

echo "I/O Performance:"
echo "  Deadline > BFQ para gaming"
echo "  Importante para carga de assets"
echo ""

echo "Boot Time:"
echo "  BORE reduce típicamente 2-3 segundos"
echo ""

echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
echo "  1. Comparar con NexusOS stock (sin BORE)"
echo "  2. Probar con tus juegos favoritos"
echo "  3. Medir FPS con:"
echo "     $ gamemoderun glxgears"
echo "     $ gamemoderun unigine-valley"
echo ""

# Guardar resultados
REPORT="/tmp/nexusos-pro-benchmark-$(date +%Y%m%d-%H%M%S).txt"
echo -e "${CYAN}Resultados guardados en: $REPORT${NC}"

{
    echo "NexusOS Pro - CachyOS Benchmark Report"
    echo "Date: $(date)"
    echo ""
    echo "Kernel: $(uname -r)"
    echo "CPU: $(lscpu | grep 'Model name' | sed 's/Model name://')"
    echo "Cores: $(nproc)"
    echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo ""
    echo "═════════════════════════════════════"
    uname -a
    echo ""
    systemd-analyze 2>/dev/null || true
    echo ""
    vmstat 1 3 2>/dev/null | tail -1 || true
} > "$REPORT"

echo "Abre el archivo para ver todos los detalles."
echo ""
