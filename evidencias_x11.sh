#!/bin/bash

# Definir nombre del archivo con fecha y hora
ARCHIVO="evidencia_x11_$(date +%Y%m%d_%H%M%S).txt"

# Generar evidencias y guardar en archivo
{
echo "==================================================="
echo "EVIDENCIAS DE CONEXIÓN X11 FORWARDING"
echo "Fecha y hora: $(date)"
echo "Servidor: $(hostname)"
echo "==================================================="
echo ""

echo "--- 1. USUARIOS CONECTADOS ---"
w
echo ""

echo "--- 2. SESIONES SSH ACTIVAS ---"
ps aux | grep "sshd.*@pts" | grep -v grep
echo ""

echo "--- 3. PROCESOS GRÁFICOS EN EJECUCIÓN ---"
ps -eo pid,user,lstart,etime,%mem,rss,cmd | grep -E "xterm|xclock|pgadmin|X11" | grep -v grep
echo ""

echo "--- 4. CONEXIONES DE RED ESTABLECIDAS ---"
ss -tnp | grep ESTABLISHED | grep -E "sshd|X11"
echo ""

echo "--- 5. CONEXIONES SSH DETALLADAS ---"
netstat -tnpa 2>/dev/null | grep ESTABLISHED | grep ssh || ss -tnp | grep ESTABLISHED | grep ssh
echo ""

echo "--- 6. PUERTOS EN ESCUCHA ---"
ss -tlnp | grep -E ":22|:60"
echo ""

echo "--- 7. DISPLAY FORWARDING ACTIVOS ---"
netstat -tlnp 2>/dev/null | grep X11 || ss -tlnp | grep X11
echo ""

echo "--- 8. USO DE MEMORIA DEL SISTEMA ---"
free -h
echo ""

echo "--- 9. PROCESOS CON MAYOR USO DE MEMORIA ---"
ps aux --sort=-%mem | head -10
echo ""

echo "==================================================="
echo "FIN DE EVIDENCIAS"
echo "==================================================="

} | tee "$ARCHIVO"

echo ""
echo "✓ Evidencia guardada en: $ARCHIVO"
