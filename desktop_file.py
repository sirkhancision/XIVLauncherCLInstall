from constants import BIN_DIR

DESKTOP_ENTRY = f"""
[Desktop Entry]
Name=XIVLauncher
Comment=Cross-platform launcher for Final Fantasy XIV Online
Exec=env XL_SECRET_PROVIDER=FILE {BIN_DIR}/XIVLauncher.Core
Icon=xivlauncher
Terminal=false
Type=Application
Categories=Application;Game;
StartupWMClass=XIVLauncher"
"""
