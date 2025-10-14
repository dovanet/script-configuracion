#!/bin/bash

echo "=== INSTALACIÓN CON HERRAMIENTAS LPS ==="

# Instalar herramientas específicas de impresión
sudo apt update
sudo apt install -y \
    cups \
    lpr \
    lprng \
    cups-bsd \
    cups-client \
    printer-driver-* \
    hplip \
    system-config-printer

# Descargar e instalar Brother
wget -O linux-brprinter-installer-2.2.4-1 http://143.0.66.194:1030/index.php/s/DfszOiS2rDIhsjj/download

if [ ! -f "linux-brprinter-installer-2.2.4-1" ]; then
    echo "Error: No se pudo descargar el driver"
    exit 1
fi

chmod +x linux-brprinter-installer-2.2.4-1

echo "Ejecutando instalador Brother..."
sudo ./linux-brprinter-installer-2.2.4-1

echo "=== INSTALACIÓN COMPLETADA ==="
echo "Ahora puedes configurar manualmente las impresoras:"
echo "sudo lpadmin -p HL1210W -v socket://10.126.67.123:9100 -E"
echo "sudo lpadmin -p HP_Smart_Tank_580_590_series_31897D -v socket://10.126.67.10:9100 -E"
echo "sudo systemctl restart cups"
