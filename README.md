# CONFIGURACIÓN INICIAL PARA PCs - DEBIAN 13

## PASO 1 - Ejecutar como root
Ejecutaremos los comandos como root por lo tanto:
```bash
su
#Ingresar contraseña de root
```

## PASO 2 - Instalar Git
Instalaremos git para importar el repositorio publico
```bash
apt install git

```

## PASO 3 - Clonar repositorio
Clonamos el repositorio publico
```bash
git clone https://github.com/dovanet/script-configuracion.git

```

## PASO 4  - Acceder al directorio
Ingresamos dentro de la carpeta "script-configuracion
```bash
cd script-configuracion/

```

## PASO 5 - Dar permisos de ejecución
Concedemos privilegios de ejecución a conf-inicial.sh
```bash
chmod +x conf-inicial.sh

```

## PASO 6 - Ejecutar script de configuración inicial
Ejecutamos el script para la configuracion inicial
```bash
./conf-inicial.sh

```
Nota: Esperar a que finalice, puede llevar unos minutos.

## PASO 7 - Reiniciar sistema
Reiniciamos la computadora
```bash
sudo reboot

```

## PASO 8 - Ejecutar script nuevamente como root
Nos dirigimos nuevamente al archivo "conf-inicial.sh", subimos nuestro privilegios a root y ejecutamos nuevamente
```bash
su
#Ingresar clave de root

./conf-inicial.sh

```

## PASO 9 - Reiniciar nuevamente
Esperamos a que finalice la instalación y reiniciamos
```bash
sudo reboot

```

## PASO 10 - Configuración inicial completada
La configuración base del sistema ha finalizado. A continuación se explica cómo configurar las impresoras...







# 🖨️ Configuración de Impresoras - Guía Manual

## 📋 Descripción
Guía de configuración manual posterior a la ejecución del script `impresora.sh` para las impresoras Brother HL1210W y HP Smart Tank.

## PASO 1
Dar permisos de ejecución al script

```bash
chmod +x impresora.sh

#Instalación de paquete lpr

sudo apt install lpr
```

## PASO 2
Ejecutar script

```bash
sudo ./impresora.sh
```

## PASO 3
Dentro del script se ejecutara un instalador, este te pedira el nombre de la impresora, en este caso es HL1210W, luego darle "y" a todo.

## PASO 4
Luego de instalar la impresora, se deben correr los siguientes comandos para configurar su CONNECTION mediante Socket con su IP, ejecutar en orden los siguientes comandos:

```bash
# Configurar Brother HL1210W
sudo lpadmin -p HL1210W -v socket://10.126.67.123:9100 -E

# Configurar HP Smart Tank  
sudo lpadmin -p HP_Smart_Tank_580_590_series_31897D -v socket://10.126.67.10:9100 -E

# Reiniciar CUPS
sudo systemctl restart cups
```

## Configuración manual finalizada