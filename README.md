# 🖨️ Configuración de Impresoras - Guía Manual

## 📋 Descripción
Guía de configuración manual posterior a la ejecución del script `impresora.sh` para las impresoras Brother HL1210W y HP Smart Tank.

## PASO 1
Dar permisos de ejecución al script

```bash
chmod +x impresora.sh
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