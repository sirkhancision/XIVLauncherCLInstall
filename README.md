# XIVLauncherCLInstall

### ATTENTION:
_The shell script version is deprecated, it is only kept for historical/educational purposes_.

<hr>

This is a script to install [XIVLauncher.Core](https://github.com/goatcorp/XIVLauncher.Core) in a Linux distribution.

## How to use this:

Just run `./XIVLauncherCLInstall.py` in a terminal and it will give you some prompts to answer. After that you'll have a working copy of XIVLauncher.Core in your user (the installation is user wide, not system wide).

### Dependencies:

- git

- curl

- bsdtar

- GitPython (python3 module)

- distro (python3 module)

## Reason for this to exist:

Void Linux does not currently have the .NET SDK available, which is needed to build XIVLauncher.Core, so I cannot create a template that builds a working version of it. The [flatpak](https://flathub.org/apps/details/dev.goats.xivlauncher) currently has an issue where it starts having performance issues after some time of playing the game, along with not being able to use [gamemode](https://github.com/FeralInteractive/gamemode), so that's also out of the question as well.

## Some things you might want to edit in the script:

The default path for the script to clone XIVLauncher.Core to is `~/Github/XIVLauncher.Core`, but you can edit it to where you want it to point to.

In addition, the desktop entry has the following: `env XL_SECRET_PROVIDER=FILE`. This saves your password as a file on your computer, so that XIVLauncher can store it and that you don't have to enter it every time. It is a possible security risk, though, so you might want to remove it.
