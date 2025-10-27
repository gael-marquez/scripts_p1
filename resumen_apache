import requests
import psutil
import os
import time

# =======================
# CONFIGURACIÓN (Versión Apache)
# =======================

# NOTA: Debes tener mod_status habilitado y configurado en Apache.
# La URL debe ser accesible (ej. desde localhost).
APACHE_STATUS_URL = "http://127.0.0.1/server-status?auto"

# Rutas de log para Apache en AlmaLinux/RHEL/CentOS
ERROR_LOG_PATH = "/var/log/httpd/error_log"
ACCESS_LOG_PATH = "/var/log/httpd/access_log"

# Sitios a monitorear (puedes editar estos)
SITES = {
    "Gruv": "http://localhost/gruv",
    "Joomla": "http://localhost/joomla",
    "Moodle": "http://localhost/moodle"
}

# =======================
# FUNCIONES
# =======================

def obtener_estado_apache():
    """
    Obtiene el estado de Apache parseando la salida de mod_status (?auto).
    """
    try:
        r = requests.get(APACHE_STATUS_URL, timeout=1)
        # Lanza una excepción si el código no es 200
        r.raise_for_status() 
        data = r.text.strip().split("\n")
        estado = {}
        for line in data:
            if ":" in line:
                key, val = line.split(":", 1)
                estado[key.strip()] = val.strip()
        return estado
    except Exception as e:
        # print(e) # Descomenta para depurar
        return None

def resumen_errores():
    """
    Lee las últimas 5 líneas del log de errores de Apache.
    """
    try:
        with open(ERROR_LOG_PATH, "r") as f:
            lines = f.readlines()
            return lines[-5:]
    except Exception:
        return []

def resumen_solicitudes():
    """
    Cuenta el total de solicitudes y las rechazadas (4xx/5xx) del access_log.
    """
    total = 0
    rechazadas = 0
    try:
        with open(ACCESS_LOG_PATH, "r") as f:
            lines = f.readlines()
            total = len(lines)
            # Asume el formato "common" donde el código de estado es el 9no elemento (índice 8)
            rechazadas = len([l for l in lines if len(l.split()) > 8 and (l.split()[8].startswith("4") or l.split()[8].startswith("5"))])
    except Exception:
        pass
    return total, rechazadas

def consumo_recursos_apache():
    """
    Obtiene el consumo de CPU y Memoria de los procesos 'httpd'.
    (Usa 'apache2' si estás en Debian/Ubuntu)
    """
    datos = []
    # Busca 'httpd' (AlmaLinux/RHEL)
    apache_procs = [p for p in psutil.process_iter(['name', 'cpu_percent', 'memory_percent', 'create_time']) if 'httpd' in p.info['name']]
    
    for p in apache_procs:
        try:
            # Re-obtenemos la info por si el proceso murió
            p_info = p.info
            tiempo = time.time() - p_info['create_time']
            datos.append({
                "pid": p.pid,
                "cpu": p_info['cpu_percent'],
                "mem": round(p_info['memory_percent'], 2),
                "tiempo": int(tiempo)
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            # El proceso pudo haber terminado mientras iterábamos
            continue
    return datos

def estado_sitios():
    """
    Verifica si los sitios definidos en SITES responden correctamente.
    (Esta función es idéntica a la original)
    """
    resultados = {}
    for nombre, url in SITES.items():
        try:
            resp = requests.get(url, timeout=2)
            if resp.status_code == 200:
                resultados[nombre] = "🟢 En línea"
            else:
                resultados[nombre] = f"🟠 Responde con error ({resp.status_code})"
        except requests.RequestException:
            resultados[nombre] = "🔴 No disponible"
    return resultados

# =======================
# LOOP PRINCIPAL
# =======================

if __name__ == "__main__":
    while True:
        try:
            os.system("clear")
            print("===== 🌐 RESUMEN DE OPERACIÓN DEL SERVIDOR APACHE (httpd) =====\n")

            estado = obtener_estado_apache()
            if estado:
                print(f"Trabajadores (Workers) activos: {estado.get('BusyWorkers', 'N/A')}")
                print(f"Trabajadores (Workers) inactivos: {estado.get('IdleWorkers', 'N/A')}")
                print(f"Solicitudes totales: {estado.get('Total Accesses', 'N/A')}")
                print(f"Solicitudes por segundo: {estado.get('ReqPerSec', 'N/A')}")
            else:
                print(f"❌ No se pudo obtener el estado de Apache (mod_status).")
                print(f"   Asegúrate que {APACHE_STATUS_URL} esté habilitado y accesible.")

            total, rechazadas = resumen_solicitudes()
            print(f"\n📨 Total solicitudes (access_log): {total}")
            print(f"🚫 Solicitudes rechazadas (4xx/5xx): {rechazadas}")

            print("\n🧠 CONSUMO DE RECURSOS APACHE (httpd):")
            recursos = consumo_recursos_apache()
            if recursos:
                for r in recursos:
                    print(f" PID {r['pid']} | CPU {r['cpu']}% | MEM {r['mem']}% | Tiempo {r['tiempo']}s")
            else:
                print(" Apache (httpd) no parece estar corriendo.")

            print("\n📄 ÚLTIMOS ERRORES REGISTRADOS (error_log):")
            errores = resumen_errores()
            if not errores:
                print("   (Sin errores recientes)")
            for e in errores:
                print("  ", e.strip())

            print("\n🌍 ESTADO DE SITIOS CMS:")
            for nombre, estado_sitio in estado_sitios().items():
                print(f"  {nombre}: {estado_sitio}")

            print("\n(Actualizando cada 5 segundos... Presiona Ctrl+C para salir)")
            time.sleep(5)
        
        except KeyboardInterrupt:
            print("\n\n👋 Saliendo del monitor...")
            break
        except Exception as e:
            print(f"\nHa ocurrido un error inesperado: {e}")
            time.sleep(10)
