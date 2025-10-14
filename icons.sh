# Función SIMPLIFICADA para configurar el dock
configurar_dock_empresarial() {
    local usuario=$(logname)
    
    if [ -z "$usuario" ]; then
        echo "⚠ No se puede detectar usuario para configurar dock"
        return 1
    fi
    
    echo "🎯 Configurando dock empresarial..."
    
    # Directorio para archivos .desktop del usuario
    local user_desktop_dir="/home/$usuario/.local/share/applications"
    mkdir -p "$user_desktop_dir"
    
    # CREAR archivos .desktop faltantes
    echo "📝 Creando archivos .desktop faltantes..."
    
    # 1. Gajim
    if which gajim >/dev/null 2>&1; then
        cat > "$user_desktop_dir/gajim.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Gajim
Comment=Cliente de mensajería instantánea
Exec=gajim
Icon=gajim
Categories=Network;InstantMessaging;
Terminal=false
StartupWMClass=Gajim
EOF
        chmod +x "$user_desktop_dir/gajim.desktop"
        echo "  ✅ Gajim - creado"
    fi
    
    # 2. OwnCloud
    if which owncloud >/dev/null 2>&1; then
        cat > "$user_desktop_dir/owncloud.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=OwnCloud
Comment=Sincronización de archivos en la nube
Exec=owncloud
Icon=owncloud
Categories=Network;FileTransfer;
Terminal=false
StartupWMClass=Owncloud
EOF
        chmod +x "$user_desktop_dir/owncloud.desktop"
        echo "  ✅ OwnCloud - creado"
    fi
    
    # 3. Thunderbird
    if which thunderbird >/dev/null 2>&1; then
        cat > "$user_desktop_dir/thunderbird.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Thunderbird
Comment=Cliente de correo electrónico
Exec=thunderbird
Icon=thunderbird
Categories=Network;Email;
Terminal=false
StartupWMClass=Thunderbird
EOF
        chmod +x "$user_desktop_dir/thunderbird.desktop"
        echo "  ✅ Thunderbird - creado"
    fi
    
    # 4. LibreOffice
    if which libreoffice >/dev/null 2>&1; then
        cat > "$user_desktop_dir/libreoffice.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=LibreOffice
Comment=Suite ofimática
Exec=libreoffice
Icon=libreoffice-main
Categories=Office;
Terminal=false
StartupWMClass=LibreOffice
EOF
        chmod +x "$user_desktop_dir/libreoffice.desktop"
        echo "  ✅ LibreOffice - creado"
    fi
    
    # 5. Captura de pantalla
    cat > "$user_desktop_dir/gnome-screenshot.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Captura de Pantalla
Comment=Tomar capturas de pantalla
Exec=gnome-screenshot -i
Icon=applets-screenshooter
Categories=Utility;Graphics;
Terminal=false
StartupWMClass=gnome-screenshot
EOF
    chmod +x "$user_desktop_dir/gnome-screenshot.desktop"
    echo "  ✅ Captura de pantalla - creado"
    
    # Dar permisos al usuario
    chown -R $usuario:$usuario "$user_desktop_dir"
    
    # Esperar un momento para que el sistema registre los nuevos archivos
    echo "⏳ Registrando lanzadores..."
    sleep 2
    
    # Configurar el dock con el orden EXACTO que solicitaste
    local apps_config="['chromium.desktop', 'gajim.desktop', 'linphone.desktop', 'owncloud.desktop', 'thunderbird.desktop', 'libreoffice.desktop', 'gnome-screenshot.desktop']"
    
    ejecutar_como_usuario "gsettings set org.gnome.shell favorite-apps \"$apps_config\""
    
    echo "✓ Dock configurado con 7 aplicaciones:"
    echo "  1. Chromium, 2. Gajim, 3. Linphone, 4. OwnCloud"
    echo "  5. Thunderbird, 6. LibreOffice, 7. Captura de pantalla"
}