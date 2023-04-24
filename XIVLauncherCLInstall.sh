#!/bin/bash
# XIVLauncherCLInstall
# by sirkhancision

# adjust according to the directory you wish to clone XIVLauncher.Core
XIVLauncher_DIR="$HOME/Github/XIVLauncher.Core"
VERSION=""

BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.icons"

# get distro's name
if [ -f /etc/os-release ]; then
	. /etc/os-release
	DISTRO_NAME=$(echo "$NAME" | tr "[:lower:]" "[:upper:]")
elif type lsb_release >/dev/null 2>&1; then
	DISTRO_NAME=$(lsb_release -si | tr "[:lower:]" "[:upper:]")
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

read -rp "Do you want to clone XIVLauncher.Core's repository? <y/n> " PROMPT
while true; do
	if [ -d "$XIVLauncher_DIR" ]; then
		printf "The repository already exists, operation cancelled\n\n"
		CLONED=true
	fi

	if [[ $PROMPT =~ ^[Yy]$ ]] && [[ $CLONED != true ]]; then
		clone_repo
		CLONED=true
	elif [[ $PROMPT =~ ^[Nn]$ ]] && [[ $CLONED != true ]]; then
		break
	elif [[ $CLONED != true ]]; then
		continue
	fi

	cd "$XIVLauncher_DIR" || exit 1
	VERSION=$(git tag -l --sort=-creatordate | head -n1)
	break
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

read -rp "Do you want to install .NET SDK 7? <y/n> " PROMPT
while true; do
	if [[ $PROMPT =~ ^[Yy]$ ]]; then
		if [ -d "$XIVLauncher_DIR/dotnet" ]; then
			read -rp ".NET is already installed, do you want to re-install it? <y/n> " PROMPT
			if [[ $PROMPT =~ ^[Yy]$ ]]; then
				true
			elif [[ $PROMPT =~ ^[Nn]$ ]]; then
				break
			else
				continue
			fi
		fi
		download_dotnet && break
	elif [[ $PROMPT =~ ^[Nn]$ ]]; then
		break
	else
		continue
	fi
done

build() {
	cd "src/XIVLauncher.Core" ||
		(echo "XIVLauncher.Core's directory structure is wrong" && exit 1)
	rm -rf "$XIVLauncher_DIR/build"

	DOTNET_ROOT="$XIVLauncher_DIR/dotnet" PATH="$PATH:$XIVLauncher_DIR/dotnet" \
		dotnet publish -r linux-x64 --sc -o "$XIVLauncher_DIR/build" \
		--configuration Release -p:Version="$VERSION" \
		-p:DefineConstants=WINE_XIV_"${DISTRO_NAME}"_LINUX
}

read -rp "Do you want to build XIVLauncher.Core $VERSION? <y/n> " PROMPT
while true; do
	if [[ $PROMPT =~ ^[Yy]$ ]]; then
		# pull changes and update submodules
		cd "$XIVLauncher_DIR" ||
			(echo "XIVLauncher.Core's local repo doesn't exist" && exit 1)
		git pull
		git submodule update --init --recursive
		git checkout --quiet "$VERSION"

		build
		BUILT=true
		break
	elif [[ $PROMPT =~ ^[Nn]$ ]]; then
		break
	else
		continue
	fi
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

if [[ $CLONED == true ]]; then
	cd "$XIVLauncher_DIR" || exit 1
	git checkout --quiet main
	cd - >/dev/null || exit 1
fi

if [ "$BUILT" = true ]; then
	echo "XIVLauncher.Core ${VERSION} installed successfully"
else
	echo "XIVLauncher wasn't built"
fi
