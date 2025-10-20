#!/bin/bash
# Script para configurar el cron job de backups
# Detecta automáticamente el usuario y rutas

# Detectar usuario actual
CURRENT_USER=${SUDO_USER:-$USER}
HOME_DIR="/home/$CURRENT_USER"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME_DIR/backup_cron.log"

echo "============================================"
echo "CONFIGURACIÓN DE CRON JOB PARA BACKUPS"
echo "============================================"
echo ""
echo "Usuario detectado: $CURRENT_USER"
echo "Directorio home: $HOME_DIR"
echo "Script ubicado en: $SCRIPT_DIR"
echo ""

# Eliminar cron jobs anteriores del backup (si existen)
echo "[1/3] Eliminando cron jobs anteriores..."
crontab -l 2>/dev/null | grep -v "backup_config.py" | crontab -

# Crear archivo de log si no existe
echo "[2/3] Creando archivo de log..."
touch "$LOG_FILE"
chmod 666 "$LOG_FILE"

# Configurar nuevo cron job
echo "[3/3] Configurando cron job..."

# OPCIÓN 1: CADA 5 MINUTOS (PARA PRUEBAS) ⚠️ ACTIVA
(crontab -l 2>/dev/null; echo "*/5 * * * * sudo /usr/bin/python3 $SCRIPT_DIR/backup_config.py >> $LOG_FILE 2>&1") | crontab -

# OPCIÓN 2: CADA HORA (en el minuto 0) - Descomenta para activar
# (crontab -l 2>/dev/null; echo "0 * * * * sudo /usr/bin/python3 $SCRIPT_DIR/backup_config.py >> $LOG_FILE 2>&1") | crontab -

# OPCIÓN 3: TODOS LOS DÍAS A LAS 6:00 PM (18:00) - Descomenta para activar
# (crontab -l 2>/dev/null; echo "0 18 * * * sudo /usr/bin/python3 $SCRIPT_DIR/backup_config.py >> $LOG_FILE 2>&1") | crontab -

# OPCIÓN 4: TODOS LOS DÍAS A LAS 2:00 AM (producción recomendada) - Descomenta para activar
# (crontab -l 2>/dev/null; echo "0 2 * * * sudo /usr/bin/python3 $SCRIPT_DIR/backup_config.py >> $LOG_FILE 2>&1") | crontab -

echo ""
echo "✓ Cron job configurado exitosamente"
echo ""
echo "Configuración actual:"
crontab -l