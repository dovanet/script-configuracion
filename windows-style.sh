#!/bin/bash

# Script para personalizar Debian con apariencia estilo Windows
# Versión corregida - Usa temas disponibles en repositorios Debian

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}


# Verificar que estamos en Debian
if ! grep -q "Debian" /etc/os-release; then
    print_error "Este script está diseñado para Debian"
    exit 1
fi

print_message "Iniciando personalización de Debian con estilo Windows..."

# Instalar componentes básicos del escritorio (si no están instalados)
print_message "Instalando componentes del escritorio..."
sudo apt install -y \
    gnome-shell \
    gnome-shell-extensions \
    gnome-tweaks \
    gnome-shell-extension-desktop-icons-ng \
    dconf-editor \
    arc-theme \
    adwaita-icon-theme \
    fonts-noto \
    file-roller \
    nautilus \
    gedit

# Instalar temas disponibles en Debian
print_message "Instalando temas y iconos..."
sudo apt install -y \
    gtk2-engines-pixbuf \
    gtk2-engines-murrine \
    numix-icon-theme \
    breeze-cursor-theme

# Intentar instalar temas adicionales desde repositorios alternativos
print_message "Buscando temas adicionales..."
if apt-cache show materia-gtk-theme > /dev/null 2>&1; then
    sudo apt install -y materia-gtk-theme
else
    print_warning "materia-gtk-theme no disponible, usando temas alternativos"
fi

# Instalar papirus-icon-theme si está disponible
if apt-cache show papirus-icon-theme > /dev/null 2>&1; then
    sudo apt install -y papirus-icon-theme
else
    print_warning "papirus-icon-theme no disponible, usando numix-icon-theme"
fi

# Configurar GNOME Shell extensions
print_message "Configurando extensiones de GNOME..."

# Crear directorio de extensiones si no existe
mkdir -p ~/.local/share/gnome-shell/extensions

# Instalar extensiones útiles para estilo Windows
print_message "Instalando extensiones adicionales..."

# Instalar dash-to-panel (similar a la barra de tareas de Windows)
if [ ! -d ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com ]; then
    print_message "Instalando dash-to-panel..."
    wget -O /tmp/dash-to-panel.zip https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v54.shell-extension.zip
    mkdir -p /tmp/dash-to-panel
    unzip -q /tmp/dash-to-panel.zip -d /tmp/dash-to-panel
    mkdir -p ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com
    cp -r /tmp/dash-to-panel/* ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/
    rm -rf /tmp/dash-to-panel /tmp/dash-to-panel.zip
fi

# Instalar desktop-icons-ng (iconos en el escritorio)
sudo apt install -y gnome-shell-extension-desktop-icons-ng

# Configurar temas y apariencia
print_message "Configurando temas y apariencia..."

# Configurar GTK theme (usar Adwaita o Arc como fallback)
if gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null; then
    gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita-dark'
    gsettings set org.gnome.shell.extensions.user-theme name 'Adwaita-dark'
    print_message "Tema Adwaita-dark configurado"
else
    gsettings set org.gnome.desktop.interface gtk-theme 'Arc'
    gsettings set org.gnome.desktop.wm.preferences theme 'Arc'
    gsettings set org.gnome.shell.extensions.user-theme name 'Arc'
    print_message "Tema Arc configurado"
fi

# Configurar icon theme
if gsettings set org.gnome.desktop.interface icon-theme 'Numix' 2>/dev/null; then
    print_message "Tema de iconos Numix configurado"
else
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
    print_message "Tema de iconos Adwaita configurado"
fi

# Configurar fuentes
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 10'

# Configurar comportamiento de ventanas al estilo Windows
print_message "Configurando comportamiento de ventanas..."

# Botones de ventana (minimizar, maximizar, cerrar)
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Habilitar minimizar al hacer clic
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'

# Configurar dash-to-panel (si está disponible)
if [ -d ~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com ]; then
    print_message "Configurando dash-to-panel..."
    # Habilitar la extensión primero
    gnome-extensions enable dash-to-panel@jderose9.github.com 2>/dev/null || true
    
    # Configurar después de un breve delay
    sleep 2
    gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 40
    gsettings set org.gnome.shell.extensions.dash-to-panel location-clock 'STATUSLEFT'
    gsettings set org.gnome.shell.extensions.dash-to-panel show-show-apps-button true
fi

# Configurar iconos del escritorio
print_message "Configurando iconos del escritorio..."

# Habilitar iconos en el escritorio
gsettings set org.gnome.shell.extensions.ding show-home true
gsettings set org.gnome.shell.extensions.ding show-trash true
gsettings set org.gnome.shell.extensions.ding show-volumes true
gsettings set org.gnome.shell.extensions.ding show-drop-shadow true
gsettings set org.gnome.shell.extensions.ding icon-size 'small'

# Configurar Nautilus (gestor de archivos)
print_message "Configurando Nautilus..."

gsettings set org.gnome.nautilus.preferences default-folder-viewer 'icon-view'
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'
gsettings set org.gnome.nautilus.preferences show-hidden-files false
gsettings set org.gnome.nautilus.preferences show-create-link true
gsettings set org.gnome.nautilus.list-view use-tree-view true

# Configurar comportamiento del sistema
print_message "Configurando comportamiento del sistema..."

# Habilitar ubicación de la barra de tareas (abajo)
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'

# Mostrar porcentaje de batería
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Configurar atajos de teclado similares a Windows
print_message "Configurando atajos de teclado..."

gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"


# Crear accesos directos comunes en el escritorio
print_message "Creando accesos directos en el escritorio..."

mkdir -p ~/Escritorio

# Crear lanzador para terminal
cat > ~/Escritorio/terminal.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Terminal de sistema
Exec=gnome-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;
EOF

# Crear lanzador para navegador web
cat > ~/Escritorio/navegador-web.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Navegador Web
Comment=Navegador web
Exec=xdg-open https://www.google.com
Icon=web-browser
Terminal=false
Categories=Network;
EOF

# Crear lanzador para gestor de archivos
cat > ~/Escritorio/archivos.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Archivos
Comment=Gestor de archivos
Exec=nautilus
Icon=system-file-manager
Terminal=false
Categories=System;
EOF

# Hacer ejecutables los lanzadores
chmod +x ~/Escritorio/*.desktop

# Configuración final
print_message "Aplicando configuración final..."

# Habilitar extensiones
gnome-extensions enable desktop-icons@csoriano 2>/dev/null || true

print_message "¡Configuración completada!"
print_warning "Es posible que necesites reiniciar la sesión para que todos los cambios surtan efecto."
print_message "Características configuradas:"
echo "  ✓ Botones de ventana (minimizar, maximizar, cerrar)"
echo "  ✓ Iconos en el escritorio"
echo "  ✓ Barra de tareas en la parte inferior"
echo "  ✓ Tema similar a Windows"
echo "  ✓ Atajos de teclado estilo Windows"
echo "  ✓ Gestor de archivos configurado"
echo "  ✓ Accesos directos en el escritorio"
echo ""
print_message "Para personalizar más ajustes ejecuta: gnome-tweaks"
print_message "Si algunas extensiones no funcionan, reinicia GNOME con: Alt+F2, luego escribe 'r' y presiona Enter"