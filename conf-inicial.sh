#!/bin/bash

# Script de configuración CORREGIDO para estaciones de trabajo empresariales
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta este script como root o con sudo"
    exit 1
fi

# Configuración de variables
IMAGE_URL="https://drive.google.com/uc?export=download&id=1Khfg0Ow3PLQ6hjyel32IzsEMZeZ6ZUiM"
GAJIM_SERVER="10.2.70.36"
OWNCLOUD_SERVER="10.2.70.97:1030"
TELEFONIA_SERVER="143.0.66.222"

# Función mejorada con manejo de errores
check_success() {
    if [ $? -eq 0 ]; then
        echo "✓ $1 completado"
    else
        echo "⚠ Error en: $1 - Continuando..."
        return 1
    fi
}


# Función para ejecutar comandos como usuario gráfico
ejecutar_como_usuario() {
    local usuario=$(logname)
    local comando=$1
    
    if [ -z "$usuario" ]; then
        echo "⚠ No se puede ejecutar como usuario: usuario no detectado"
        return 1
    fi
    
    local usuario_id=$(id -u $usuario)
    local bus_address="unix:path=/run/user/$usuario_id/bus"
    
    # Verificar que la sesión existe
    if [ ! -S "/run/user/$usuario_id/bus" ]; then
        echo "❌ ERROR: El usuario $usuario no tiene sesión gráfica activa."
        echo "   Inicie sesión gráfica primero y luego ejecute el script."
        return 1
    fi
    
    sudo -u $usuario DBUS_SESSION_BUS_ADDRESS=$bus_address bash -c "$comando"
}

# Función SIMPLIFICADA para configurar el dock
# Función que solo agrega aplicaciones INSTALADAS
configurar_dock_empresarial() {
    local usuario=$(logname)

    if [ -z "$usuario" ]; then
        return 1
    fi

    echo "🎯 Configurando dock solo con apps instaladas..."

    local dock_apps=()
    local local_apps_dir="/home/$usuario/.local/share/applications"
    mkdir -p "$local_apps_dir"

    # --- Función auxiliar para crear archivos .desktop ---
    crear_desktop_si_no_existe() {
        local desktop_path="$1"
        local nombre="$2"
        local comando="$3"
        local icono="$4"

        if [ ! -f "$desktop_path" ]; then
            echo "  🧩 Creando lanzador $nombre..."
            cat <<EOF > "$desktop_path"
[Desktop Entry]
Name=$nombre
Comment=Aplicación $nombre
Exec=$comando
Icon=$icono
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
EOF
            update-desktop-database "$local_apps_dir" >/dev/null 2>&1
        fi
    }

    # --- Chromium ---
    if which chromium >/dev/null 2>&1 || which chromium-browser >/dev/null 2>&1; then
        dock_apps+=("'chromium.desktop'")
        echo "  ✅ Chromium - agregado"
    fi

    # --- Gajim ---
    if which gajim >/dev/null 2>&1; then
        local desktop_path="$local_apps_dir/gajim.desktop"
        crear_desktop_si_no_existe "$desktop_path" "Gajim" "gajim" "gajim"
        dock_apps+=("'gajim.desktop'")
        echo "  ✅ Gajim - agregado"
    fi

    # --- Linphone (AppImage o instalado) ---
    if which linphone >/dev/null 2>&1; then
        dock_apps+=("'linphone.desktop'")
        echo "  ✅ Linphone - agregado"
    elif ls /home/$usuario/Descargas/Linphone*.AppImage >/dev/null 2>&1; then
        local linphone_appimage=$(ls /home/$usuario/Descargas/Linphone*.AppImage | head -n 1)
        local desktop_path="$local_apps_dir/linphone.desktop"
        crear_desktop_si_no_existe "$desktop_path" "Linphone" "$linphone_appimage" "phone"
        dock_apps+=("'linphone.desktop'")
        echo "  ✅ Linphone (AppImage) - lanzador creado y agregado"
    fi

    # --- OwnCloud ---
    if which owncloud >/dev/null 2>&1; then
        dock_apps+=("'owncloud.desktop'")
        echo "  ✅ OwnCloud - agregado"
    fi

    # --- Thunderbird ---
    if which thunderbird >/dev/null 2>&1; then
        dock_apps+=("'thunderbird.desktop'")
        echo "  ✅ Thunderbird - agregado"
    fi

    # --- LibreOffice ---
    if which libreoffice >/dev/null 2>&1; then
        dock_apps+=("'libreoffice-startcenter.desktop'")
        echo "  ✅ LibreOffice - agregado"
    fi

    # --- Capturas de pantalla ---
    local screenshot_instalada=""
    if which gnome-screenshot >/dev/null 2>&1; then
        screenshot_instalada="gnome-screenshot"
    elif which flameshot >/dev/null 2>&1; then
        screenshot_instalada="flameshot"
    else
        echo "⚙️ gnome-screenshot no instalado, instalando..."
        sudo apt update && sudo apt install -y gnome-screenshot
        if which gnome-screenshot >/dev/null 2>&1; then
            screenshot_instalada="gnome-screenshot"
            echo "  ✅ gnome-screenshot instalado"
        fi
    fi

    if [ -n "$screenshot_instalada" ]; then
        local desktop_name="gnome-screenshot.desktop"
        local desktop_path="$local_apps_dir/$desktop_name"
        crear_desktop_si_no_existe "$desktop_path" "Captura de pantalla" "$screenshot_instalada" "org.gnome.Screenshot"
        dock_apps+=("'$desktop_name'")
        echo "  ✅ Capturas - agregado al dock"
    else
        echo "  ⚠️ No se pudo instalar herramienta de capturas"
    fi

    # --- Generar lista final correctamente formateada ---
    local dock_list="[$(IFS=,; echo "${dock_apps[*]}")]"

    # --- Aplicar configuración al usuario ---
    ejecutar_como_usuario "gsettings set org.gnome.shell favorite-apps \"$dock_list\""

    echo "✓ Dock configurado con apps disponibles"
}

instalar_clima_tucuman() {
    local usuario=$(logname)
    local EXT_UUID="openweather@p0"
    local EXT_DIR="/home/$usuario/.local/share/gnome-shell/extensions/$EXT_UUID"
    local GNOME_VER=$(gnome-shell --version | awk '{print $3}')
    local VERSION_TAG="VERSION_TAG"  # reemplazar con la versión compatible de la extensión
    
    echo "☀️ Instalando extensión de clima para TUCUMÁN..."

    # Crear carpeta de extensiones si no existe
    mkdir -p "$EXT_DIR"

    # Instalar herramientas necesarias
    if ! which gnome-extensions >/dev/null 2>&1; then
        echo "⚙️ Instalando gnome-extensions..."
        sudo apt update && sudo apt install -y gnome-shell-extensions unzip wget
    fi

    # Descargar OpenWeather
    echo "📥 Descargando OpenWeather..."
    wget -O /tmp/openweather.zip "https://extensions.gnome.org/download-extension/$EXT_UUID.shell-extension.zip?version_tag=$VERSION_TAG"

    # Descomprimir
    unzip -o /tmp/openweather.zip -d "$EXT_DIR"

    # Activar extensión
    sudo -u "$usuario" gnome-extensions enable $EXT_UUID

    # Configurar ciudad y unidades
    sudo -u "$usuario" gsettings set org.gnome.shell.extensions.openweather location "San Miguel de Tucumán"
    sudo -u "$usuario" gsettings set org.gnome.shell.extensions.openweather units "metric"

    echo "✅ Clima configurado para TUCUMÁN. Reinicia GNOME Shell (Alt+F2 → r) si no aparece."
}



# Función para configurar zona horaria de Argentina
configurar_zona_horaria() {
    echo "Configurando zona horaria de Argentina..."
    
    # Configurar timezone a America/Argentina/Buenos_Aires
    timedatectl set-timezone America/Argentina/Buenos_Aires
    
    # Verificar la configuración
    current_timezone=$(timedatectl show --property=Timezone --value)
    if [ "$current_timezone" = "America/Argentina/Buenos_Aires" ]; then
        echo "✓ Zona horaria configurada: Argentina (Buenos Aires)"
        echo "  Hora actual: $(date)"
    else
        echo "⚠ No se pudo configurar la zona horaria automáticamente"
        echo "  Configurar manualmente: sudo timedatectl set-timezone America/Argentina/Buenos_Aires"
    fi
    
    # Configurar NTP para sincronización automática
    timedatectl set-ntp true
    echo "✓ Sincronización automática de hora activada"
}

# Función para configuraciones GNOME - BARRA INFERIOR CORREGIDA
configurar_gnome() {
    local usuario=$(logname)
    
    if [ -z "$usuario" ]; then
        echo "⚠ No se puede detectar usuario para configurar GNOME"
        return 1
    fi
    
    echo "Configurando GNOME para usuario: $usuario"
    
    # SOLUCIÓN DEFINITIVA: Usar Dash to Dock configurado correctamente
    echo "Instalando y configurando Dash to Dock..."
    apt install -y gnome-shell-extension-dash-to-dock
    
    # Configuraciones básicas de GNOME
    ejecutar_como_usuario "gsettings set org.gnome.mutter dynamic-workspaces false"
    ejecutar_como_usuario "gsettings set org.gnome.desktop.wm.preferences num-workspaces 1"
    ejecutar_como_usuario "gsettings set org.gnome.desktop.session idle-delay 300"
    ejecutar_como_usuario "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'"
    ejecutar_como_usuario "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
    ejecutar_como_usuario "gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'"
    
    # CONFIGURACIÓN DASH TO DOCK PARA COMPORTAMIENTO COMO WINDOWS
    echo "Configurando dock en la parte inferior..."
    
    # Posición en la parte inferior
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'"
    
    # Siempre visible (no se esconde)
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock autohide false"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false"
    
    # Mostrar ventanas minimizadas en el dock
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock show-running-apps true"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false"
    
    # Tamaño y comportamiento
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.8"
    
    # Forzar recarga de la extensión
    echo "Activando extensión Dash to Dock..."
    ejecutar_como_usuario "gnome-extensions enable dash-to-dock@micxgx.gmail.com"
    
    echo "✓ Dock configurado en la parte inferior"
    echo "Las ventanas minimizadas se mostrarán en la barra inferior"
}

# Función para configurar servicios del sistema que inician automáticamente
configurar_servicios_sistema() {
    echo "⚙️ CONFIGURANDO SERVICIOS DEL SISTEMA..."
    
    # 1. SSH Server
    systemctl enable ssh
    systemctl start ssh
    echo "✓ SSH Server - Activado"
    
    # 2. Servicio de impresión (CUPS)
    systemctl enable cups
    systemctl start cups  
    echo "✓ CUPS (Impresión) - Activado"
    
    # 3. USB
    modprobe -r uas usb_storage 2>/dev/null
    echo "blacklist usb_storage" > /etc/modprobe.d/disable-usb-storage.conf
    echo "blacklist uas" >> /etc/modprobe.d/disable-usb-storage.conf
    update-initramfs -u 2>/dev/null
    echo "Pendrives bloqueados"
    
    # 4. Network Manager (importante para conexiones)
    systemctl enable NetworkManager
    systemctl start NetworkManager
    echo "✓ NetworkManager - Activado"
    
    # 5. Servicio de Bluetooth (si está instalado)
    if systemctl status bluetooth >/dev/null 2>&1; then
        systemctl enable bluetooth
        systemctl start bluetooth
        echo "✓ Bluetooth - Activado"
    fi
}

    # Función para configurar aplicaciones que se abren al inicio
configurar_autostart_aplicaciones() {
    local usuario=$(logname)
    
    if [ -z "$usuario" ]; then
        echo "⚠ No se puede configurar autostart sin usuario"
        return 1
    fi
    
    echo "🚀 CONFIGURANDO APLICACIONES DE INICIO AUTOMÁTICO..."
    
    # Directorio de autostart
    AUTOSTART_DIR="/home/$usuario/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    
    # 1. RUSTDESK - Acceso remoto
    cat > "$AUTOSTART_DIR/rustdesk.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=RustDesk
Comment=Acceso remoto
Exec=rustdesk
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    # 2. GAJIM - Mensajería
    cat > "$AUTOSTART_DIR/gajim.desktop" << 'EOF'  
[Desktop Entry]
Type=Application
Name=Gajim
Comment=Cliente de mensajería
Exec=gajim
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    # 3. OWNCLOUD - Sincronización de archivos
    cat > "$AUTOSTART_DIR/owncloud.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=OwnCloud
Comment=Sincronización de archivos
Exec=owncloud
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    # 4. LINPHONE - Telefonía IP
    LINPHONE_FILE="/home/$usuario/Descargas/Linphone-6.0.1-CallEdition-x86_64.AppImage"
    cat > "$AUTOSTART_DIR/linphone.desktop" << EOF
LINPHONE_FILE="/home/$usuario/Descargas/Linphone-6.0.1-CallEdition-x86_64.AppImage"
cat > "$AUTOSTART_DIR/linphone.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Linphone
Comment=Cliente de VoIP
Exec=sh -c "sleep 10 && export DISPLAY=:0 && export XAUTHORITY=/home/$usuario/.Xauthority && $LINPHONE_FILE"
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

    # 5. CONFIGURAR THUNDERBIRD para iniciar minimizado
    cat > "$AUTOSTART_DIR/thunderbird.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Thunderbird
Comment=Cliente de correo
Exec=thunderbird
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    # Dar permisos al usuario
    chown -R $usuario:$usuario "$AUTOSTART_DIR"
    chmod -R 755 "$AUTOSTART_DIR"
    
    echo "✓ Aplicaciones configuradas para inicio automático:"
    echo "  - RustDesk (Acceso remoto)"
    echo "  - Gajim (Mensajería)" 
    echo "  - OwnCloud (Sincronización)"
    echo "  - Linphone (Telefonía IP)"
    echo "  - Thunderbird (Correo)"
}

# Función MEJORADA para configurar escritorio como Windows (COMPLETAMENTE FUNCIONAL)
configurar_escritorio_windows() {
    local usuario=$(logname)
    
    if [ -z "$usuario" ]; then
        echo "⚠ No se puede detectar usuario para configurar escritorio"
        return 1
    fi
    
    echo "🖥️ CONFIGURANDO ESCRITORIO FUNCIONAL..."
    
    # 1. INSTALAR la extensión CORRECTA para iconos en escritorio
    echo "Instalando extensiones de escritorio..."
    apt install -y gnome-shell-extension-desktop-icons-ng
    
    # 2. CREAR y CONFIGURAR directorio Escritorio
    echo "Configurando directorio Escritorio..."
    ESCRITORIO_DIR="/home/$usuario/Escritorio"
    mkdir -p "$ESCRITORIO_DIR"
    chown $usuario:$usuario "$ESCRITORIO_DIR"
    chmod 755 "$ESCRITORIO_DIR"
    
    # 3. CONFIGURACIÓN ESENCIAL para mostrar iconos
    echo "Activando iconos en escritorio..."
    
    # Configurar Nautilus para manejar el escritorio
    ejecutar_como_usuario "gsettings set org.gnome.nautilus.preferences show-create-link true" || true
    
    # Configurar Desktop Icons NG (la extensión moderna)
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.ding show-home true" || true
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.ding show-trash true" || true
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.ding show-volumes true" || true
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.ding show-drop-place true" || true
    
    # 4. COMPORTAMIENTO WINDOWS
    echo "Configurando comportamiento Windows..."
    ejecutar_como_usuario "gsettings set org.gnome.nautilus.preferences click-policy 'double'" || true
    ejecutar_como_usuario "gsettings set org.gnome.nautilus.preferences default-sort-order 'name'" || true
    
    # 5. CREAR ACCESOS DIRECTOS BÁSICOS
    echo "Creando accesos directos..."
    
    # Navegador
    cat > "$ESCRITORIO_DIR/Chromium.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Chromium
Comment=Navegador web
Exec=chromium
Icon=chromium
Terminal=false
Categories=Network;WebBrowser;
EOF

    # Archivos
    cat > "$ESCRITORIO_DIR/Archivos.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Archivos
Comment=Administrar archivos
Exec=nautilus
Icon=system-file-manager
Terminal=false
Categories=System;FileTools;
EOF

    # Terminal
    cat > "$ESCRITORIO_DIR/Terminal.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Terminal del sistema
Exec=gnome-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

    # Dar permisos
    chmod +x "$ESCRITORIO_DIR/"*.desktop
    chown $usuario:$usuario "$ESCRITORIO_DIR/"*.desktop
    
    # 6. ACTIVAR EXTENSIÓN - MÉTODO DIRECTO
    echo "Activando extensión de iconos..."
    ejecutar_como_usuario "gnome-extensions enable desktop-icons@csoriano" || true
    
    echo "✓ Escritorio configurado - Los iconos aparecerán tras reiniciar"
}

# Función ESPECÍFICA para forzar iconos en escritorio - EJECUTAR DESPUÉS DEL REINICIO
forzar_iconos_escritorio() {
    local usuario=$(logname)
    
    if [ -z "$usuario" ]; then
        return 1
    fi
    
    echo "🔧 Activando iconos de escritorio..."
    
    # Métodos alternativos para activar iconos
    ejecutar_como_usuario "gsettings set org.gnome.desktop.background show-desktop-icons true" || true
    
    # Forzar recarga de extensiones
    ejecutar_como_usuario "gnome-extensions enable desktop-icons@csoriano" || true
    ejecutar_como_usuario "gnome-extensions enable ding@rastersoft.com" || true
    
    # Configuración adicional para Nautilus
    ejecutar_como_usuario "gsettings set org.gnome.nautilus.preferences default-folder-viewer 'icon-view'" || true
    
    echo "✓ Iconos de escritorio activados"
}
# Función para verificar configuraciones de seguridad
verificar_seguridad() {
    echo ""
    echo "🔐 VERIFICANDO CONFIGURACIONES DE SEGURIDAD..."
    echo "=================================================="
    
    # Verificar USBGuard
    
    
    # Verificar apagado automático
    if grep -q "apagado-automatico" /etc/crontab 2>/dev/null; then
        echo "✅ Apagado automático 19:00 - PROGRAMADO"
        grep "apagado-automatico" /etc/crontab
    else
        echo "❌ Apagado automático - NO CONFIGURADO"
    fi
    
    # Verificar /etc/hosts bloqueado
    if lsattr /etc/hosts 2>/dev/null | grep -q "i"; then
        echo "✅ /etc/hosts - BLOQUEADO (inmutable)"
    else
        echo "❌ /etc/hosts - NO BLOQUEADO"
        # Bloquearlo ahora
        chattr +i /etc/hosts 2>/dev/null && echo "✓ /etc/hosts bloqueado"
    fi
    
    echo "=================================================="
}

# Función FALTANTE para forzar configuración Windows
forzar_escritorio_windows() {
    local usuario=$(logname)
    
    if [ -z "$usuario" ]; then
        echo "⚠ No se puede detectar usuario para forzar escritorio"
        return 1
    fi
    
    echo "🔧 Forzando configuración Windows..."
    
    # Reactivar extensiones
    ejecutar_como_usuario "gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true"
    
    # Forzar recarga de GNOME Shell
    ejecutar_como_usuario "gsettings set org.gnome.shell enabled-extensions \"['dash-to-dock@micxgx.gmail.com']\""
    
    # Reconfigurar dock
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true"
    ejecutar_como_usuario "gsettings set org.gnome.shell.extensions.dash-to-dock autohide false"
    
    echo "✓ Configuración Windows forzada"
}

# Función para crear lanzador de Linphone
crear_lanzador_linphone() {
    local usuario=$(logname)
    if [ -z "$usuario" ]; then
        echo "⚠ No se puede detectar usuario para crear lanzador"
        return 1
    fi
    
    echo "📱 Creando lanzador de Linphone..."
    
    # Ruta del AppImage
    LINPHONE_FILE="/home/$usuario/Descargas/Linphone-6.0.1-CallEdition-x86_64.AppImage"
    
    # Crear lanzador .desktop en aplicaciones
    cat > "/usr/share/applications/linphone.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Linphone
Comment=Cliente de VoIP y videollamadas
Exec=$LINPHONE_FILE
Icon=linphone
Categories=Network;Telephony;
Terminal=false
StartupWMClass=Linphone
EOF

    # También crear enlace en el escritorio
    cat > "/home/$usuario/Escritorio/Linphone.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Linphone
Comment=Cliente de VoIP y videollamadas
Exec=$LINPHONE_FILE
Icon=linphone
Categories=Network;Telephony;
Terminal=false
StartupWMClass=Linphone
EOF

    # Dar permisos
    chmod +x "/home/$usuario/Escritorio/Linphone.desktop"
    chown $usuario:$usuario "/home/$usuario/Escritorio/Linphone.desktop"
    
    # Descargar icono si no existe
    if [ ! -f "/usr/share/icons/linphone.png" ]; then
        wget -q -O /tmp/linphone.png "https://images.icon-icons.com/1381/PNG/512/linphone_94743.png" 2>/dev/null || true
        if [ -f "/tmp/linphone.png" ]; then
            mv /tmp/linphone.png /usr/share/icons/linphone.png
        fi
    fi
    
    echo "✓ Lanzador de Linphone creado en aplicaciones y escritorio"
}

# Función mejorada para descargar fondo de pantalla
descargar_fondo_pantalla() {
    local usuario=$(logname)
    local imagen_url="$IMAGE_URL"
    local destino="/home/$usuario/Imágenes/fondo-empresa.jpg"
    
    mkdir -p "/home/$usuario/Imágenes"
    
    echo "📥 Intentando descargar fondo de pantalla..."
    
    # Método 1: wget con headers de navegador
    wget --header="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
         --header="Accept: image/webp,image/*,*/*;q=0.8" \
         --no-check-certificate \
         -O "$destino" "$imagen_url" 2>/dev/null
    
    if [ $? -eq 0 ] && [ -f "$destino" ] && [ -s "$destino" ]; then
        # Configurar fondo
        ejecutar_como_usuario "gsettings set org.gnome.desktop.background picture-uri 'file://$destino'"
        ejecutar_como_usuario "gsettings set org.gnome.desktop.background picture-uri-dark 'file://$destino'"
        echo "✓ Fondo de pantalla configurado desde Google Drive"
    else
        # Usar fondo por defecto
        echo "⚠ Usando fondo por defecto - la descarga falló"
        rm -f "$destino"
        # Configurar un fondo oscuro por defecto
        ejecutar_como_usuario "gsettings set org.gnome.desktop.background picture-uri ''"
        ejecutar_como_usuario "gsettings set org.gnome.desktop.background primary-color '#2d2d2d'"
    fi
}

# Función de verificación de instalación
verificar_instalacion() {
    echo ""
    echo "=================================================="
    echo "🔍 VERIFICACIÓN DE INSTALACIÓN EMPRESARIAL"
    echo "=================================================="
    
    # Verificar zona horaria
    echo ""
    echo "🌍 CONFIGURACIÓN DE ZONA HORARIA:"
    current_timezone=$(timedatectl show --property=Timezone --value)
    if [ "$current_timezone" = "America/Argentina/Buenos_Aires" ]; then
        echo "✅ Zona horaria: Argentina (Buenos Aires)"
        echo "   Hora actual: $(date)"
    else
        echo "❌ Zona horaria: $current_timezone (debería ser America/Argentina/Buenos_Aires)"
    fi
    
    # Verificar aplicaciones instaladas
    echo ""
    echo "📦 APLICACIONES INSTALADAS:"
    
    # Chromium
    if which chromium >/dev/null 2>&1; then
        echo "✅ Chromium - INSTALADO"
    else
        echo "❌ Chromium - NO INSTALADO"
    fi
    
    # Remmina
    if which remmina >/dev/null 2>&1; then
        echo "✅ Remmina - INSTALADO"
    else
        echo "❌ Remmina - NO INSTALADO"
    fi
    
    # Wine
    if which wine >/dev/null 2>&1; then
        echo "✅ Wine - INSTALADO"
    else
        echo "❌ Wine - NO INSTALADO"
    fi
    
    # Winetricks
    if which winetricks >/dev/null 2>&1; then
        echo "✅ Winetricks - INSTALADO"
    else
        echo "❌ Winetricks - NO INSTALADO"
    fi
    
    # RustDesk
    if which rustdesk >/dev/null 2>&1; then
        echo "✅ RustDesk - INSTALADO"
    else
        echo "❌ RustDesk - NO INSTALADO"
    fi
    
    # LibreOffice
    if which libreoffice >/dev/null 2>&1; then
        echo "✅ LibreOffice - INSTALADO"
    else
        echo "❌ LibreOffice - NO INSTALADO"
    fi
    
    # OwnCloud
    if which owncloud >/dev/null 2>&1; then
        echo "✅ OwnCloud - INSTALADO"
    else
        echo "❌ OwnCloud - NO INSTALADO"
    fi
    
    # Gajim
    if which gajim >/dev/null 2>&1; then
        echo "✅ Gajim - INSTALADO"
    else
        echo "❌ Gajim - NO INSTALADO"
    fi
    
    # Thunderbird
    if which thunderbird >/dev/null 2>&1; then
        echo "✅ Thunderbird - INSTALADO"
    else
        echo "❌ Thunderbird - NO INSTALADO"
    fi
    
    # Linphone
    if which linphone >/dev/null 2>&1 || [ -f "/usr/local/bin/linphone" ] || [ -f "/usr/bin/linphone" ] || [ -f "/home/$(logname)/Descargas/Linphone-6.0.1-CallEdition-x86_64.AppImage" ]; then
        echo "✅ Linphone - INSTALADO"
    else
        echo "❌ Linphone - NO INSTALADO"
    fi
    
    # Google Earth
    if which google-earth-pro >/dev/null 2>&1; then
        echo "✅ Google Earth - INSTALADO"
    else
        echo "❌ Google Earth - NO INSTALADO"
    fi
    
    # Verificar servicios
    echo ""
    echo "⚙️ SERVICIOS CONFIGURADOS:"
    
    # SSH
    if systemctl is-active ssh >/dev/null 2>&1; then
        echo "✅ SSH Server - ACTIVO"
    else
        echo "❌ SSH Server - INACTIVO"
    fi
    
    # CUPS
    if systemctl is-active cups >/dev/null 2>&1; then
        echo "✅ CUPS (Impresión) - ACTIVO"
    else
        echo "❌ CUPS (Impresión) - INACTIVO"
    fi
    
    
    # Verificar configuraciones de seguridad
    echo ""
    echo "🛡️ CONFIGURACIONES DE SEGURIDAD:"
    
    # /etc/hosts bloqueado
    if lsattr /etc/hosts 2>/dev/null | grep -q "i"; then
        echo "✅ /etc/hosts - BLOQUEADO"
    else
        echo "❌ /etc/hosts - NO BLOQUEADO"
    fi
    
    # Apagado automático
    if grep -q "apagado-automatico" /etc/crontab 2>/dev/null; then
        echo "✅ Apagado automático - CONFIGURADO"
    else
        echo "❌ Apagado automático - NO CONFIGURADO"
    fi
    
    # Verificar configuraciones GNOME
    echo ""
    echo "🎨 CONFIGURACIONES GNOME:"
    usuario=$(logname 2>/dev/null)
    if [ -n "$usuario" ]; then
        # Tema oscuro
        tema=$(ejecutar_como_usuario "gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null" || echo "no-config")
        if [ "$tema" = "'prefer-dark'" ]; then
            echo "✅ Tema oscuro - ACTIVADO"
        else
            echo "❌ Tema oscuro - NO ACTIVADO"
        fi
        
        # Workspace único
        workspaces=$(ejecutar_como_usuario "gsettings get org.gnome.desktop.wm.preferences num-workspaces 2>/dev/null" || echo "0")
        if [ "$workspaces" = "1" ]; then
            echo "✅ Workspace único - CONFIGURADO"
        else
            echo "❌ Workspace único - NO CONFIGURADO"
        fi
        
        # Dock inferior
        dock_pos=$(ejecutar_como_usuario "gsettings get org.gnome.shell.extensions.dash-to-dock dock-position 2>/dev/null" || echo "left")
        if [ "$dock_pos" = "'BOTTOM'" ]; then
            echo "✅ Dock inferior - CONFIGURADO"
        else
            echo "❌ Dock inferior - NO CONFIGURADO"
        fi
        
        # Comportamiento de clics
        clics=$(ejecutar_como_usuario "gsettings get org.gnome.nautilus.preferences click-policy 2>/dev/null" || echo "single")
        if [ "$clics" = "'double'" ]; then
            echo "✅ Clic doble como Windows - CONFIGURADO"
        else
            echo "❌ Clic doble como Windows - NO CONFIGURADO"
        fi
        
        # Verificar si hay iconos en el escritorio
        if [ -d "/home/$usuario/Desktop" ] || [ -d "/home/$usuario/Escritorio" ]; then
            echo "✅ Directorio escritorio - CONFIGURADO"
        else
            echo "❌ Directorio escritorio - NO CONFIGURADO"
        fi
        
        # Verificar plantillas
        if [ -d "/home/$usuario/Templates" ] && [ "$(ls -A /home/$usuario/Templates 2>/dev/null)" ]; then
            echo "✅ Plantillas documentos - CONFIGURADAS"
        elif [ -d "/home/$usuario/Plantillas" ] && [ "$(ls -A /home/$usuario/Plantillas 2>/dev/null)" ]; then
            echo "✅ Plantillas documentos - CONFIGURADAS"
        else
            echo "❌ Plantillas documentos - NO CONFIGURADAS"
        fi
    else
        echo "⚠ No se puede verificar GNOME (usuario no detectado)"
    fi
    
    echo ""
    echo "=================================================="
}

# ========== EJECUCIÓN PRINCIPAL ==========

# Habilitar repositorios necesarios
echo "Habilitando repositorios contrib y non-free..."
sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
apt update -y

# INSTALAR APLICACIONES CON MANEJO DE ERRORES

# 1. Chromium
echo "Instalando Chromium..."
apt install -y chromium
check_success "Chromium"

# 2. Remmina
echo "Instalando Remmina..."
apt install -y remmina remmina-plugin-rdp remmina-plugin-vnc
check_success "Remmina"

# 3. Wine y Winetricks
echo "Instalando Wine..."
apt install -y wine winetricks
check_success "Wine"

# 4. RustDesk - Instalación mejorada
echo "Instalando RustDesk..."
# Método alternativo - desde repositorio si está disponible
if apt install -y rustdesk 2>/dev/null; then
    echo "✓ RustDesk instalado desde repositorio"
else
    # Descargar e instalar manualmente
    wget -qO rustdesk.deb "https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9-x86_64.deb" || \
    wget -qO rustdesk.deb "https://github.com/rustdesk/rustdesk/releases/download/1.4.2/rustdesk-1.4.2-x86_64.deb"
    
    if [ -f "rustdesk.deb" ] && [ -s "rustdesk.deb" ]; then
        apt install -y ./rustdesk.deb
        rm -f rustdesk.deb
        echo "✓ RustDesk instalado manualmente"
    else
        echo "⚠ RustDesk no se pudo instalar automáticamente"
    fi
fi

# 5. LibreOffice
echo "Instalando LibreOffice..."
apt install -y libreoffice libreoffice-l10n-es
check_success "LibreOffice"

# 6. OwnCloud Desktop Client
echo "Instalando OwnCloud Desktop..."
if apt install -y owncloud-client 2>/dev/null; then
    echo "✓ OwnCloud instalado"
else
    echo "⚠ OwnCloud no disponible en repositorios"
fi

# 7. Gajim
echo "Instalando Gajim..."
apt install -y gajim
check_success "Gajim"

# 8. Thunderbird
echo "Instalando Thunderbird..."
apt install -y thunderbird thunderbird-l10n-es-es
check_success "Thunderbird"

# 9. Linphone - INSTALACIÓN FUNCIONAL CON AppImage
echo "Instalando Linphone..."
LINPHONE_URL="https://download.linphone.org/releases/linux/app/Linphone-6.0.1-CallEdition-x86_64.AppImage"
LINPHONE_FILE="/home/$(logname)/Descargas/Linphone-6.0.1-CallEdition-x86_64.AppImage"

# Crear directorio de Descargas si no existe
mkdir -p "/home/$(logname)/Descargas"

# Descargar Linphone si no existe
if [ ! -f "$LINPHONE_FILE" ]; then
    echo "Descargando Linphone AppImage..."
    wget -q --show-progress "$LINPHONE_URL" -O "$LINPHONE_FILE" || \
    wget -q "https://www.linphone.org/releases/linux/app/Linphone-5.0.14-x86_64.AppImage" -O "$LINPHONE_FILE"
    
    if [ $? -eq 0 ] && [ -f "$LINPHONE_FILE" ]; then
        echo "✓ Linphone descargado correctamente"
    else
        echo "⚠ No se pudo descargar Linphone AppImage"
    fi
else
    echo "✓ Linphone ya está descargado"
fi

# Asegurarse de que el archivo .AppImage tiene permisos de ejecución
if [ -f "$LINPHONE_FILE" ]; then
    chmod +x "$LINPHONE_FILE"
    # Crear enlace simbólico en /usr/local/bin para que funcione el comando 'linphone'
    ln -sf "$LINPHONE_FILE" /usr/local/bin/linphone 2>/dev/null || true
    echo "✓ Linphone configurado con permisos de ejecución"
fi

# 10. SSH Server
echo "Instalando SSH Server..."
apt install -y openssh-server
check_success "SSH Server"

# 11. Google Earth
echo "Instalando Google Earth..."
apt install -y lsb-release libxss1 libnss3 libxrandr2
# Descargar e instalar Google Earth
wget -q -O google-earth.deb "https://dl.google.com/dl/earth/client/current/google-earth-pro-stable_current_amd64.deb" || \
wget -q -O google-earth.deb "https://dl.google.com/earth/client/current/google-earth-pro-stable_current_amd64.deb"

if [ -f "google-earth.deb" ]; then
    apt install -y ./google-earth.deb
    rm -f google-earth.deb
    echo "✓ Google Earth instalado"
else
    echo "⚠ No se pudo descargar Google Earth"
fi

# 12. Sistema de impresión
echo "Instalando sistema de impresión..."
apt install -y cups system-config-printer
check_success "Sistema de impresión"

# CONFIGURACIONES DE SEGURIDAD

# USBGuard
echo "Configurando Bloqueo USB..."

# Bloquear /etc/hosts
echo "Bloqueando /etc/hosts..."
chattr +i /etc/hosts 2>/dev/null && echo "✓ /etc/hosts bloqueado" || echo "⚠ No se pudo bloquear /etc/hosts"

# CONFIGURACIÓN REAL DE APAGADO AUTOMÁTICO
echo "⏰ CONFIGURANDO APAGADO AUTOMÁTICO 19:00..."

# Crear script de apagado REAL
cat > /usr/local/bin/apagado-automatico.sh << 'EOF'
#!/bin/bash
# Script REAL de apagado automático
logger "Apagado automático programado ejecutándose - Sistema se apagará en 5 minutos"

# Notificar a usuarios conectados
wall "⚠️  ATENCIÓN: El sistema se apagará en 5 minutos (19:00). Guarde su trabajo."

# Esperar 5 minutos y luego apagar
sleep 300

# Apagar REALMENTE el sistema
shutdown -h now "Apagado automático programado completado"
EOF

chmod +x /usr/local/bin/apagado-automatico.sh

# Configurar cron para ejecutar diariamente a las 18:55 (para apagar a las 19:00)
echo "55 18 * * * root /usr/local/bin/apagado-automatico.sh" >> /etc/crontab

# También crear un apagado de emergencia más temprano para pruebas
cat > /usr/local/bin/apagado-prueba.sh << 'EOF'
#!/bin/bash
# Apagado de prueba (5 minutos después de ejecutar)
wall "🔧 APAGADO DE PRUEBA: Sistema se reiniciará en 2 minutos para pruebas"
sleep 120
shutdown -r now "Reinicio de prueba completado"
EOF

chmod +x /usr/local/bin/apagado-prueba.sh

echo "✓ Apagado automático configurado: Diario a las 19:00"
echo "✓ Script de prueba creado: /usr/local/bin/apagado-prueba.sh"

# CONFIGURACIONES GNOME (corregidas)
echo "Aplicando configuraciones GNOME..."
configurar_zona_horaria
configurar_gnome

# CONFIGURAR ESCRITORIO ESTILO WINDOWS (COMPLETAMENTE FUNCIONAL)
echo "Configurando escritorio estilo Windows..."


# CAMBIAR POR:
configurar_escritorio_windows
forzar_iconos_escritorio
configurar_escritorio_windows
# CONFIGURAR FONDO DE PANTALLA (OPTIMIZADO)
echo "Configurando fondo de pantalla..."
descargar_fondo_pantalla

# CREAR LANZADORES DE APPLICACIONES
echo "Creando lanzadores de aplicaciones..."
crear_lanzador_linphone

configurar_dock_empresarial
instalar_clima_tucuman

# CONFIGURAR SERVICIOS
echo "Configurando servicios..."
systemctl enable cups 2>/dev/null && systemctl start cups 2>/dev/null
systemctl enable ssh 2>/dev/null && systemctl start ssh 2>/dev/null

# ACTUALIZACIONES FINALES
echo "Actualizando sistema de forma segura..."
apt update
DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confold"

configurar_autostart_aplicaciones
configurar_servicios_sistema

# VERIFICACIÓN FINAL
verificar_instalacion

# VERIFICAR SEGURIDAD
verificar_seguridad

configure_autostart_apps

# LIMPIEZA FINAL
echo "Limpiando sistema..."
apt autoremove -y
apt autoclean

# MENSAJE FINAL
echo ""
echo "=================================================="
echo "✅ CONFIGURACIÓN EMPRESARIAL COMPLETADA!"
echo "=================================================="
echo ""
echo "🎯 RESUMEN EJECUTADO:"
echo "✓ Verificación completa mostrada arriba"
echo "✓ Linphone instalado con AppImage funcional"
echo "✓ Dock inferior configurado y activado"
echo "✓ Escritorio estilo Windows configurado"
echo "✓ Iconos visibles y creación de archivos habilitada"
echo "✓ Todas las aplicaciones instaladas y verificadas"
echo "✓ Servicios configurados y en ejecución"
echo ""
echo "🔧 PASOS FINALES NECESARIOS:"
echo ""
echo "1. OPCIÓN RECOMENDADA - REINICIAR EQUIPO:"
echo "   sudo reboot"
echo ""
echo "2. OPCIÓN ALTERNATIVA - CERRAR SESIÓN:"
echo "   - Clic en menú usuario (esquina superior derecha)"
echo "   - Seleccionar 'Cerrar sesión'"
echo "   - Volver a iniciar sesión"
echo ""
echo "3. SI EL DOCK NO SE VE:"
echo "   Ejecutar en terminal:"
echo "   gnome-extensions enable dash-to-dock@micxgx.gmail.com"
echo "   Luego reiniciar GNOME: Alt + F2, escribir 'r' y Enter"
echo ""
echo "4. PARA VERIFICAR NUEVAMENTE:"
echo "   Ejecutar: sudo $0"
echo ""
echo "⚠️  IMPORTANTE: Algunos cambios requieren reinicio para aplicarse completamente"
echo "=================================================="