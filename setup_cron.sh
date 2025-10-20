#!/bin/bash
# Script para configurar el cron job

# OPCIÓN 1: CADA 5 MINUTOS (PARA PRUEBAS)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/python3 /scripts_p1/backup_config.py >> /home/gael/backup_cron.log 2>&1") | crontab -

# OPCIÓN 2: TODOS LOS DÍAS A LAS 6:00 PM (18:00) - Descomenta para activar
# (crontab -l 2>/dev/null; echo "0 18 * * * /usr/bin/python3 /scripts_p1/backup_config.py >> /home/gael/backup_cron.log 2>&1") | crontab -

# Verificar
echo "Cron job agregado. Lista actual de cron jobs:"
crontab -l