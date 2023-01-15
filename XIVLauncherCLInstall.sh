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
DOTNET_LINK="https://download.visualstudio.microsoft.com/download/pr/c646b288-5d5b-4c9c-a95b-e1fad1c0d95d/e13d71d48b629fe3a85f5676deb09e2d/dotnet-sdk-7.0.102-linux-x64.tar.gz"

clone_repo() {
    mkdir -p "$XIVLauncher_DIR"

    if [ "$(which git)" ]; then
        git clone "$XIVLauncherCore_GIT" "$XIVLauncher_DIR"
    else
        echo "git is not installed" && exit 1
    fi
}

echo "Do you want to clone XIVLauncher.Core's repository?"
while true; do
    if [ -d "$XIVLauncher_DIR" ]; then
        printf "The repository already exists, operation cancelled\n\n"
        break
    fi
    read -r PROMPT
    case $PROMPT in
    "y" | "Y" | "yes" | "Yes") clone_repo && break ;;
    "n" | "N" | "no" | "No") break ;;
    *) continue ;;
    esac
done

download_dotnet() {
    rm -rf "$XIVLauncher_DIR/dotnet"
    if [ -z "$(which curl)" ]; then
        echo "curl is not installed" && exit 1
    elif [ -z "$(which bsdtar)" ]; then
        echo "bsdtar is not installed" && exit 1
    else
        mkdir -p "$XIVLauncher_DIR/dotnet"
        curl -Lo /dev/stdout "$DOTNET_LINK" |
            bsdtar -xf /dev/stdin --directory "$XIVLauncher_DIR/dotnet"
    fi
}

echo "Do you want to install .NET SDK 7?"
while true; do
    read -r PROMPT
    case $PROMPT in
    "y" | "Y" | "yes" | "Yes")
        if [ -d "$XIVLauncher_DIR/dotnet" ]; then
            echo ".NET is already installed, do you want to re-install it?"
            read -r PROMPT
            case $PROMPT in
            "y" | "Y" | "yes" | "Yes") download_dotnet && break ;;
            "n" | "N" | "no" | "No") break ;;
            *) continue ;;
            esac
        fi
        ;;
    "n" | "N" | "no" | "No") break ;;
    *) continue ;;
    esac
done

build() {
    cd "src/XIVLauncher.Core" ||
        (echo "XIVLauncher.Core's directory structure is wrong" && exit 1)
    rm -rf "$XIVLauncher_DIR/build"

    DOTNET_ROOT="$XIVLauncher_DIR/dotnet" PATH="$PATH:$XIVLauncher_DIR/dotnet" \
        dotnet publish -r linux-x64 --sc -o "$XIVLauncher_DIR/build" \
        --configuration Release -p:Version="$VERSION" \
        -p:DefineConstants=WINE_XIV_${DISTRO_NAME}_LINUX
}

echo "Do you want to build XIVLauncher.Core $VERSION?"
while true; do
    read -r PROMPT
    case $PROMPT in
    "y" | "Y" | "yes" | "Yes")
        # pull changes and update submodules
        cd "$XIVLauncher_DIR" ||
            (echo "XIVLauncher.Core's local repo doesn't exist" && exit 1)
        git pull
        git submodule update --init --recursive

        build
        BUILT=true
        break
        ;;
    "n" | "N" | "no" | "No") break ;;
    *) continue ;;
    esac
done

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
