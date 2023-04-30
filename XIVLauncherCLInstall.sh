#!/bin/bash
# XIVLauncherCLInstall
# by sirkhancision

if ! command -v git >/dev/null; then
	echo "git is not installed"
	exit 1
fi

if ! command -v curl >/dev/null; then
	echo "curl is not installed"
	exit 1
fi

if ! command -v bsdtar >/dev/null; then
	echo "bsdtar is not installed"
	exit 1
fi

XIVLAUNCHER_DIR="$HOME/Github/XIVLauncher.Core"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.icons"
XIVLAUNCHERCORE_GIT="https://github.com/goatcorp/XIVLauncher.Core.git"
DOTNET_LINK="https://download.visualstudio.microsoft.com/download/pr/ebfd0bf8-79bd-480a-9e81-0b217463738d/9adc6bf0614ce02670101e278a2d8555/dotnet-sdk-7.0.203-linux-x64.tar.gz"
DESKTOP_ENTRY="[Desktop Entry]
Name=XIVLauncher
Comment=Cross-platform launcher for Final Fantasy XIV Online
Exec=env XL_SECRET_PROVIDER=FILE $BIN_DIR/XIVLauncher.Core
Icon=xivlauncher
Terminal=false
Type=Application
Categories=Application;Game;
StartupWMClass=XIVLauncher"

set -e
set -o pipefail

# get distro's name
if command -v lsb_release >/dev/null 2>&1; then
	DISTRO_NAME=$(lsb_release -si | tr "[:lower:]" "[:upper:]")
elif [ -f /etc/os-release ]; then
	. /etc/os-release
	DISTRO_NAME=$(echo "$NAME" | tr "[:lower:]" "[:upper:]")
elif [ -f /etc/lsb-release ]; then
	# shellcheck source=/dev/null
	. /etc/lsb-release
	DISTRO_NAME=$(echo "$DISTRIB_ID" | tr "[:lower:]" "[:upper:]")
elif [ -f /etc/debian_version ]; then
	DISTRO_NAME="DEBIAN"
elif [ -f /etc/SuSe-release ]; then
	DISTRO_NAME="SUSE"
elif [ -f /etc/redhat-release ]; then
	DISTRO_NAME="REDHAT"
else
	DISTRO_NAME="UNKNOWN"
fi

clone_repo() {
	if [ -d "$XIVLAUNCHER_DIR/dotnet" ]; then
		if [ -d "$HOME/.cache/dotnet" ]; then
			rm -rf "$HOME/.cache/dotnet"
		fi

		mv "$XIVLAUNCHER_DIR/dotnet" "$HOME/.cache"
		rm -rf "$XIVLAUNCHER_DIR"
	fi

	mkdir -p "$XIVLAUNCHER_DIR"
	git clone "$XIVLAUNCHERCORE_GIT" "$XIVLAUNCHER_DIR"

	if [ -d "$HOME/.cache/dotnet" ]; then
		mv "$HOME/.cache/dotnet" "$XIVLAUNCHER_DIR"
	fi
}

download_dotnet() {
	rm -rf "$XIVLAUNCHER_DIR/dotnet"
	mkdir -p "$XIVLAUNCHER_DIR/dotnet"

	curl -Lo /dev/stdout "$DOTNET_LINK" |
		bsdtar -xf /dev/stdin --directory "$XIVLAUNCHER_DIR/dotnet"
}

build() {
	cd "$XIVLAUNCHER_DIR"
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "This is not a git repository"
		exit 1
	fi

	rm -rf "$XIVLAUNCHER_DIR/build"
	git pull
	git submodule update --init --recursive

	VERSION=$(git tag -l --sort=-creatordate | head -n1)
	git checkout --quiet "$VERSION"

	cd src/XIVLauncher.Core

	DOTNET_ROOT="$XIVLAUNCHER_DIR/dotnet" \
		PATH="$PATH:$XIVLAUNCHER_DIR/dotnet" \
		dotnet publish -r linux-x64 \
		--self-contained true \
		--configuration Release \
		-p:Version="$VERSION" \
		-p:DefineConstants=WINE_XIV_"$DISTRO_NAME"_LINUX \
		-o "$XIVLAUNCHER_DIR/build"

	git checkout --quiet main
}

# removes xivlauncher.core
uninstall() {
	if [ -d "$XIVLAUNCHER_DIR" ]; then
		while true; do
			read -rp "Do you also wish to remove the local git repository? <y/n> " OPTION
			if [[ $OPTION =~ ^[Yy]$ ]]; then
				rm -rf "$XIVLAUNCHER_DIR"
				break
			elif [[ $OPTION =~ ^[Nn]$ ]]; then
				break
			else
				continue
			fi
		done
	fi

	rm -f "$APPS_DIR/XIVLauncher.desktop"
	rm -f "$BIN_DIR/XIVLauncher.Core"
	rm -f "$ICONS_DIR/xivlauncher.png"

	echo "XIVLauncher.Core was uninstalled"
}

# parse arguments
while getopts ":hcbdu" OPT; do
	case $OPT in
	h)
		echo "Usage: [-h] Displays help text"
		echo "       [-c] Clones the git repository for XIVLauncher.Core"
		echo "       [-d] Downloads .NET SDK 7"
		echo "       [-b] Builds XIVLauncher.Core"
		echo "       [-u] Uninstalls XIVLauncher.Core"
		exit 0
		;;
	c)
		clone_repo
		exit 0
		;;
	d)
		download_dotnet
		exit 0
		;;
	b)
		build
		exit 0
		;;
	u)
		uninstall
		exit 0
		;;
	\?)
		echo "Invalid option"
		exit 1
		;;
	esac
done
shift $((OPTIND - 1))

# cloning repo
read -rp "Do you want to clone XIVLauncher.Core's repository? <y/n> " OPTION
while true; do
	if [[ $OPTION =~ ^[Yy]$ ]]; then
		if [ -d "$XIVLAUNCHER_DIR" ]; then
			printf "The repository already exists, operation cancelled\n\n"
		else
			clone_repo
		fi
		break
	elif [[ $OPTION =~ ^[Nn]$ ]]; then
		break
	else
		continue
	fi
done

# downloading .net
read -rp "Do you want to install .NET SDK 7? <y/n> " OPTION
while true; do
	if [[ $OPTION =~ ^[Yy]$ ]]; then
		if [ -d "$XIVLAUNCHER_DIR/dotnet" ]; then
			read -rp ".NET is already installed, do you want to re-install it? <y/n> " OPTION
			if [[ $OPTION =~ ^[Yy]$ ]]; then
				true
			elif [[ $OPTION =~ ^[Nn]$ ]]; then
				break
			else
				continue
			fi
		fi
		download_dotnet && break
	elif [[ $OPTION =~ ^[Nn]$ ]]; then
		break
	else
		continue
	fi
done

# building xivlauncher.core
read -rp "Do you want to build XIVLauncher.Core? <y/n> " OPTION
while true; do
	if [[ $OPTION =~ ^[Yy]$ ]]; then
		build

		# link the binary file
		mkdir -p "$BIN_DIR"
		ln -sf "$XIVLAUNCHER_DIR/build/XIVLauncher.Core" "$BIN_DIR"

		# create the desktop entry
		if [ ! -f "$APPS_DIR/XIVLauncher.desktop" ]; then
			mkdir -p "$APPS_DIR"
			echo "$DESKTOP_ENTRY" >"$APPS_DIR/XIVLauncher.desktop"
		fi

		# link the icon for the desktop entry
		if [ ! -f "$ICONS_DIR/xivlauncher.png" ]; then
			mkdir -p "$ICONS_DIR"
			ln -sf "$XIVLAUNCHER_DIR/misc/linux_distrib/512.png" "$ICONS_DIR/xivlauncher.png"
		fi

		echo "XIVLauncher.Core ${VERSION} installed successfully"
		break
	elif [[ $OPTION =~ ^[Nn]$ ]]; then
		echo "XIVLauncher wasn't built"
		break
	else
		continue
	fi
done
