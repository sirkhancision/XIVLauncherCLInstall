#!/bin/sh
# XIVLauncherCLInstall
# by sirkhancision

set -e

# adjust according to the directory you wish to clone XIVLauncher.Core
XIVLauncher_DIR="$HOME/Github/XIVLauncher.Core"
VERSION=1.0.3

BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.icons"

# the distro name must be in uppercase
DISTRO_NAME="VOID"

DESKTOP_ENTRY="[Desktop Entry]
Name=XIVLauncher
Comment=Cross-platform launcher for Final Fantasy XIV Online
Exec=env XL_SECRET_PROVIDER=FILE $BIN_DIR/XIVLauncher.Core
Icon=xivlauncher
Terminal=false
Type=Application
Categories=Application;Game;
StartupWMClass=XIVLauncher"

XIVLauncherCore_GIT="https://github.com/goatcorp/XIVLauncher.Core.git"
DOTNET_LINK="https://dotnet.microsoft.com/pt-br/download/dotnet/thank-you/sdk-6.0.404-linux-x64-binaries"

echo "Do you want to clone XIVLauncher.Core's repository?"
read -r PROMPT
case $PROMPT in
"y" | "Y" | "yes" | "Yes")
    mkdir -p "$XIVLauncher_DIR"

    if [ "$(which git)" ]; then
        git clone "$XIVLauncherCore_GIT" "$XIVLauncher_DIR"
    else
        echo "git is not installed" && exit 1
    fi
    ;;
esac

echo "Do you want to install .NET SDK 6.0?"
read -r PROMPT
case $PROMPT in
"y" | "Y" | "yes" | "Yes")
    # download .NET 6.0 SDK
    mkdir -p "$XIVLauncher_DIR/dotnet"

    if [ -z "$(which curl)" ]; then
        echo "curl is not installed" && exit 1
    elif [ -z "$(which bsdtar)" ]; then
        echo "bsdtar is not installed" && exit 1
    else
        curl -Lo /dev/stdout "$DOTNET_LINK" |
            bsdtar -xf /dev/stdin --directory "$XIVLauncher_DIR/dotnet"
    fi
    ;;
esac

# build
echo "Do you want to build XIVLauncher.Core $VERSION?"
read -r PROMPT
case $PROMPT in
"y" | "Y" | "yes" | "Yes")
    # pull changes and update submodules
    cd "$XIVLauncher_DIR" ||
        (echo "XIVLauncher.Core's local repo doesn't exist" && exit 1)
    git pull
    git submodule update --init --recursive

    cd "src/XIVLauncher.Core" ||
        (echo "XIVLauncher.Core's directory structure is wrong" && exit 1)
    DOTNET_ROOT="$XIVLauncher_DIR/dotnet" PATH="$PATH:$XIVLauncher_DIR/dotnet" dotnet publish \
        -r linux-x64 --sc -o "$XIVLauncher_DIR/build" --configuration Release \
        -p:Version="$VERSION" -p:DefineConstants=WINE_XIV_${DISTRO_NAME}_LINUX \
        --no-restore

    BUILT=true
    ;;
esac

# link the binary file
if [ "$BUILT" = true ]; then
    mkdir -p "$BIN_DIR"
    ln -sf "$XIVLauncher_DIR/build/XIVLauncher.Core" "$BIN_DIR"
fi

# create the desktop entry
if [ ! -f "$APPS_DIR/XIVLauncher.desktop" ]; then
    mkdir -p "$APPS_DIR"
    echo "$DESKTOP_ENTRY" >"$APPS_DIR/XIVLauncher.desktop"
fi

# link the icon for the desktop entry
if [ ! -f "$ICONS_DIR/xivlauncher.png" ]; then
    mkdir -p "$ICONS_DIR"
    ln -sf "$XIVLauncher_DIR/misc/linux_distrib/512.png" "$ICONS_DIR/xivlauncher.png"
fi

if [ "$BUILT" = true ]; then
    echo "Installation sucessful: XIVLauncher.Core $VERSION"
else
    echo "XIVLauncher $VERSION wasn't built"
fi

exit 0
