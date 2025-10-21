#!/bin/bash

REPORTE="reporte_conexiones.txt"
LOG_SECURE="/var/log/secure"

echo "=== Reporte de Conexiones SSH generado el $(date) ===" > $REPORTE
echo "" >> $REPORTE
echo "--- Usuarios conectados ---" >> $REPORTE
grep -a 'session opened for user' $LOG_SECURE | sort | uniq >> $REPORTE
echo "" >> $REPORTE
echo "--- Conexión fallida---" >> $REPORTE
grep -a 'Failed password' $LOG_SECURE | tail -n 20 >> $REPORTE
echo "" >> $REPORTE
