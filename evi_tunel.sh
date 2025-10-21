#!/bin/bash

echo "--- Inicio de prueba: $(date) ---"

sudo grep -E '(::1|127\.0\.0\.1)' /var/log/httpd/access_log

sudo ss -tpn | grep 'sshd' | grep ':80'


echo "--- Fin de prueba ---"
