# XIVLauncherCLInstall

### ATTENTION:
_The shell script version is deprecated, it is only kept for historical/educational purposes_.

<hr>

This is a script to install [XIVLauncher.Core](https://github.com/goatcorp/XIVLauncher.Core) in a Linux distribution (it aims at being distro agnostic, even though you'd have to edit a simple line of text in the script for that, I'll get to it).

## How to use this:

Just run `./XIVLauncherCLInstall.py` in the terminal, and it will give you some prompts to answer. After that, you'll have a working copy of XIVLauncher.Core in your user (the installation is user-wide, not system-wide).

### Dependencies:

- git

- curl

- bsdtar

- GitPython (python3 module)

- distro (python3 module)

## Reason for this to exist:

Void Linux currently doesn't have the .NET SDK available, which is needed to build XIVLauncher.Core, therefore I can't make a template that builds a working version of it. The [flatpak](https://flathub.org/apps/details/dev.goats.xivlauncher) currently has an issue where it starts to have performance issues after some time playing the game, along with not being able to use [gamemode](https://github.com/FeralInteractive/gamemode), so that's also out of question.

## Some things you might want to edit in the script:

The script's default path to clone XIVLauncher.Core to is `~/Github/XIVLauncher.Core`, but you can edit it to where you want it to point to.

Additionally, the desktop entry has the following: `env XL_SECRET_PROVIDER=FILE`. That saves your password as a file in your computer, so that XIVLauncher can store it and that you don't have to type your password every time. It poses as a possible security risk, though, so you could want to remove that.
