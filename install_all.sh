#!/bin/bash
# Script maestro de instalación
# Detecta automáticamente si es servidor o cliente
# PREREQUISITO: Ejecutar desde el directorio scripts_p1 ya clonado

# Detectar usuario actual y directorio del script
CURRENT_USER=${SUDO_USER:-$USER}
HOME_DIR="/home/$CURRENT_USER"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "INSTALADOR AUTOMÁTICO DE SISTEMA DE BACKUP"
echo "============================================"
echo ""
echo "Usuario detectado: $CURRENT_USER"
echo "Directorio home: $HOME_DIR"
echo ""
echo "Selecciona el tipo de instalación:"
echo ""
echo "1) Servidor de Backup (VM clonada)"
echo "2) Cliente de Backup (VM original)"
echo ""
read -p "Opción [1-2]: " OPCION

case $OPCION in
    1)
        echo ""
        echo "Instalando como SERVIDOR DE BACKUP..."
        echo ""
        
        # Cambiar hostname
        echo "[1/4] Cambiando hostname..."
        sudo hostnamectl set-hostname backup-server
        
        # Mostrar IP
        echo "[2/4] Dirección IP de este servidor:"
        ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}'
        
        # Crear directorio
        echo "[3/4] Creando directorio de backups..."
        sudo mkdir -p /backups_remoto
        sudo chown $CURRENT_USER:$CURRENT_USER /backups_remoto
        
        # Instalar paquetes
        echo "[4/4] Instalando SSH y rsync..."
        sudo dnf install -y openssh-server rsync
        sudo systemctl enable --now sshd
        
        echo ""
        echo "============================================"
        echo "   SERVIDOR DE BACKUP CONFIGURADO"
        echo "============================================"
        echo ""
        echo "IMPORTANTE: Anota la IP mostrada arriba"
        echo "La necesitarás para configurar la máquina principal"
        echo "============================================"
        ;;
    2)
        echo ""
        echo "Instalando como CLIENTE DE BACKUP..."
        echo ""
        
        read -p "Ingresa la IP del servidor de backup: " BACKUP_IP
        
        if [ -z "$BACKUP_IP" ]; then
            echo "Error: IP requerida"
            exit 1
        fi
        
        # Instalar paquetes del sistema
        echo "[1/8] Instalando dependencias del sistema..."
        sudo dnf install -y epel-release git rsync python3-pip
        
        # Instalar dependencias de Python
        echo "[2/8] Instalando dependencias de Python..."
        pip3 install paramiko scp
        
        # Generar llaves SSH para root
        echo "[3/8] Generando llaves SSH para root..."
        sudo mkdir -p /root/.ssh
        sudo chmod 700 /root/.ssh
        if [ ! -f /root/.ssh/id_rsa ]; then
            sudo ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
            echo "Llaves SSH generadas"
        else
            echo "Las llaves SSH de root ya existen, omitiendo generación..."
        fi
        
        # Configurar script de backup (YA NO ES NECESARIO, el script Python lo hace automáticamente)
        echo "[4/8] El script Python ya detecta automáticamente el usuario..."
        echo "No se requiere configuración manual"
        
        # Solo actualizar la IP del servidor remoto
        echo "[5/8] Configurando IP del servidor de backup..."
        sed -i "s|REMOTE_HOST = '.*'|REMOTE_HOST = '$BACKUP_IP'|" "$SCRIPT_DIR/backup_config.py"
        echo "IP configurada: $BACKUP_IP"
        
        # Crear directorio de backups local
        echo "[6/8] Creando directorio de backups local..."
        mkdir -p "$HOME_DIR/backups"
        
        # Configurar sudoers
        echo "[7/8] Configurando sudoers..."
        SUDOERS_LINE="$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/python3 $SCRIPT_DIR/backup_config.py"
        if ! sudo grep -q "python3.*backup_config.py" /etc/sudoers 2>/dev/null; then
            echo "$SUDOERS_LINE" | sudo tee -a /etc/sudoers > /dev/null
            echo "Sudoers configurado"
        else
            echo "Sudoers ya configurado, omitiendo..."
        fi
        
        # Configurar cron
        echo "[8/8] Configurando cron job..."
        chmod +x "$SCRIPT_DIR/setup_cron.sh"
        "$SCRIPT_DIR/setup_cron.sh"
        
        echo ""
        echo "============================================"
        echo "  ACCIÓN MANUAL REQUERIDA"
        echo "============================================"
        echo ""
        echo "Para completar la configuración, ejecuta:"
        echo ""
        echo "  sudo ssh-copy-id -i /root/.ssh/id_rsa.pub $CURRENT_USER@$BACKUP_IP"
        echo ""
        echo "Esto copiará la llave SSH de root al servidor de backup."
        echo "Te pedirá la contraseña de '$CURRENT_USER' UNA SOLA VEZ."
        echo ""
        echo "Después de hacerlo, prueba el backup con:"
        echo ""
        echo "  sudo python3 $SCRIPT_DIR/backup_config.py"
        echo ""
        echo "Y monitorea el cron con:"
        echo ""
        echo "  tail -f $HOME_DIR/backup_cron.log"
        echo ""
        echo "============================================"
        ;;
    *)
        echo "Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "============================================"
echo "✅ INSTALACIÓN COMPLETADA"
echo "============================================"