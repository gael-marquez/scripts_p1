#!/bin/bash

echo "==================================================="
echo "EVIDENCIAS DE CONEXIÓN X11 FORWARDING"
echo "Fecha y hora: $(date)"
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

echo "--- 5. PUERTOS EN ESCUCHA ---"
ss -tlnp | grep -E ":22|:60"
echo ""

echo "--- 6. DISPLAY FORWARDING ACTIVOS ---"
netstat -tlnp 2>/dev/null | grep X11 || ss -tlnp | grep X11
echo ""

echo "--- 7. USO DE MEMORIA DEL SISTEMA ---"
free -h
echo ""

echo "--- 8. PROCESOS CON MAYOR USO DE MEMORIA ---"
ps aux --sort=-%mem | head -10
echo ""

echo "==================================================="
