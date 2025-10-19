#!/bin/bash
# Script para configurar el cron job

# Agregar el cron job (ejecutar cada día a las 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/python3 /home/gael-marquez/backup_config.py >> /var/log/backup_cron.log 2>&1") | crontab -

# Verificar
echo "Cron job agregado. Lista actual de cron jobs:"
crontab -l