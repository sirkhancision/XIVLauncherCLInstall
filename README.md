# XIVLauncherCLInstall

This is a POSIX shell script to install [XIVLauncher.Core]([GitHub - goatcorp/XIVLauncher.Core: Cross-platform version of XIVLauncher, optimized for Steam Deck](https://github.com/goatcorp/XIVLauncher.Core)) in a Linux distribution (it aims at being distro agnostic, even though you'd have to edit a simple line of text in the script for that, I'll get to it).

## How to use this:

Just run `./XIVLauncherCLInstall` in the terminal, and it will give you some prompts to answer. After that, you'll have a working copy of XIVLauncher.Core in your user (the installation is user-wide, not system-wide).

### Dependencies:

- git

- curl

- bsdtar

## Reason for this to exist:

Void Linux currently doesn't have the .NET SDK available, which is needed to build XIVLauncher.Core, therefore I can't make a template that builds a working version of it. The [flatpak]([Flathub—An app store and build service for Linux](https://flathub.org/apps/details/dev.goats.xivlauncher)) currently has an issue where it starts to have performance issues after some time playing the game, along with not being able to use [gamemode]([GitHub - FeralInteractive/gamemode: Optimise Linux system performance on demand](https://github.com/FeralInteractive/gamemode)), so that's also out of question.

## Some things you might want to edit in the script:

The script's default path to clone XIVLauncher.Core to is `~/Github/XIVLauncher.Core`, but you can edit it (at line 8) to where you want it to point to.

Additionally, at line 21, the desktop entry has the following: `env XL_SECRET_PROVIDER=FILE`. That saves your password as a file in your computer, so that XIVLauncher can store it and that you don't have to type your password every time. It poses as a possible security risk, though, so you could want to remove that.

It also comes with a variable called `DISTRO_NAME`, at line 16, which as default, has `VOID` as its value. Feel free to edit that value to the name of your current distribution (e.g. ARCH, FEDORA, etc.), if you care about that.
