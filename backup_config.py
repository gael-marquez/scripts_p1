#!/usr/bin/env python3
"""
Script de backup de archivos de configuración
"""

import os
import shutil
import datetime
import logging
from pathlib import Path

# ==================== CONFIGURACIÓN ====================

# Obtener el usuario actual (funciona con sudo)
CURRENT_USER = os.environ.get('SUDO_USER') or os.environ.get('USER') or 'gael'
HOME_DIR = f'/home/{CURRENT_USER}'

# Archivos a respaldar (modifica estas rutas según tus necesidades)
FILES_TO_BACKUP = [
    '/etc/hostname',
    '/etc/hosts',
    '/etc/ssh/sshd_config'
]

# Directorio de destino LOCAL (para pruebas)
BACKUP_DIR_LOCAL = f'{HOME_DIR}/backups'

# Directorio de destino REMOTO (configurar IP del servidor de backup)
REMOTE_USER = CURRENT_USER
REMOTE_HOST = '192.168.86.34'  # Cambiar por la IP de tu servidor de backup
REMOTE_PATH = '/backups_remoto'

# Número de backups a mantener (rotación)
MAX_BACKUPS = 7

# Archivo de log
LOG_FILE = f'{HOME_DIR}/backup_config.log'

# ==================== CONFIGURACIÓN DE LOG ====================

# Crear directorio de logs si no existe
os.makedirs(HOME_DIR, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# ==================== FUNCIONES ====================

def create_backup_dir(backup_path):
    """Crea el directorio de backup si no existe"""
    try:
        Path(backup_path).mkdir(parents=True, exist_ok=True)
        logger.info(f"Directorio de backup listo: {backup_path}")
        return True
    except Exception as e:
        logger.error(f"Error creando directorio {backup_path}: {e}")
        return False

def backup_files_local(files_list, destination):
    """
    Realiza backup local de los archivos especificados
    """
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_folder = os.path.join(destination, f'backup_{timestamp}')
    
    try:
        os.makedirs(backup_folder, exist_ok=True)
        logger.info(f"Iniciando backup en: {backup_folder}")
        
        success_count = 0
        for file_path in files_list:
            if os.path.exists(file_path):
                try:
                    # Mantener la estructura de directorios
                    relative_path = file_path.lstrip('/')
                    dest_path = os.path.join(backup_folder, relative_path)
                    dest_dir = os.path.dirname(dest_path)
                    
                    os.makedirs(dest_dir, exist_ok=True)
                    shutil.copy2(file_path, dest_path)
                    
                    logger.info(f"✓ Copiado: {file_path}")
                    success_count += 1
                except Exception as e:
                    logger.error(f"✗ Error copiando {file_path}: {e}")
            else:
                logger.warning(f"⚠ Archivo no encontrado: {file_path}")
        
        logger.info(f"Backup completado: {success_count}/{len(files_list)} archivos")
        return backup_folder
        
    except Exception as e:
        logger.error(f"Error en backup_files_local: {e}")
        return None

def backup_files_remote(files_list, remote_user, remote_host, remote_path):
    """
    Realiza backup remoto usando rsync (para la segunda fase)
    """
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    temp_dir = f'/tmp/backup_{timestamp}'
    
    try:
        os.makedirs(temp_dir, exist_ok=True)
        
        # Copiar archivos al directorio temporal
        for file_path in files_list:
            if os.path.exists(file_path):
                relative_path = file_path.lstrip('/')
                dest_path = os.path.join(temp_dir, relative_path)
                dest_dir = os.path.dirname(dest_path)
                os.makedirs(dest_dir, exist_ok=True)
                shutil.copy2(file_path, dest_path)
        
        # Usar rsync para transferir
        remote_dest = f"{remote_user}@{remote_host}:{remote_path}/backup_{timestamp}"
        rsync_cmd = f"rsync -avz -e ssh {temp_dir}/ {remote_dest}"
        
        logger.info(f"Transfiriendo a servidor remoto...")
        result = os.system(rsync_cmd)
        
        # Limpiar directorio temporal
        shutil.rmtree(temp_dir)
        
        if result == 0:
            logger.info(f"✓ Backup remoto completado exitosamente")
            return True
        else:
            logger.error(f"✗ Error en transferencia remota")
            return False
            
    except Exception as e:
        logger.error(f"Error en backup_files_remote: {e}")
        return False

def rotate_backups(backup_dir, max_backups):
    """
    Mantiene solo los últimos N backups, elimina los más antiguos
    """
    try:
        backups = sorted([
            d for d in os.listdir(backup_dir) 
            if os.path.isdir(os.path.join(backup_dir, d)) and d.startswith('backup_')
        ])
        
        if len(backups) > max_backups:
            to_delete = backups[:-max_backups]
            for old_backup in to_delete:
                old_path = os.path.join(backup_dir, old_backup)
                shutil.rmtree(old_path)
                logger.info(f"Eliminado backup antiguo: {old_backup}")
                
    except Exception as e:
        logger.error(f"Error en rotación de backups: {e}")

# ==================== FUNCIÓN PRINCIPAL ====================

def main():
    """Función principal"""
    logger.info("="*60)
    logger.info("INICIANDO PROCESO DE BACKUP")
    logger.info(f"Usuario: {CURRENT_USER}")
    logger.info(f"Directorio home: {HOME_DIR}")
    logger.info("="*60)
    
    # Modo de operación (cambia a 'remote' cuando configures la VM remota)
    MODE = 'remote'  # 'local' o 'remote'
    
    if MODE == 'local':
        # FASE 1: Backup local (prueba)
        if not create_backup_dir(BACKUP_DIR_LOCAL):
            logger.error("No se pudo crear directorio de backup. Abortando.")
            return 1
        
        backup_path = backup_files_local(FILES_TO_BACKUP, BACKUP_DIR_LOCAL)
        
        if backup_path:
            rotate_backups(BACKUP_DIR_LOCAL, MAX_BACKUPS)
            logger.info("✓ Proceso completado exitosamente")
            return 0
        else:
            logger.error("✗ Proceso fallido")
            return 1
    
    elif MODE == 'remote':
        # FASE 2: Backup remoto
        success = backup_files_remote(
            FILES_TO_BACKUP,
            REMOTE_USER,
            REMOTE_HOST,
            REMOTE_PATH
        )
        return 0 if success else 1

if __name__ == "__main__":
    exit(main())