#!/usr/bin/env python3
# XIVLauncherCLInstall
# by sirkhancision

import argparse
import distro
import git
import os
import subprocess
import sys
from constants import (APPS_DIR, BIN_DIR, DOTNET_LINK, ICONS_DIR,
                       XIVLAUNCHERCORE_GIT, XIVLAUNCHER_DIR)
from desktop_file import DESKTOP_ENTRY
from shutil import which


def check_dependencies(dependencies):
    """
    Check if the required programs are installed
    """
    missing_deps = [cmd for cmd in dependencies if which(cmd) is None]
    if missing_deps:
        print("The following dependencies are missing:")
        print("\n".join(missing_deps))
        sys.exit(1)


def get_distro_name():
    return distro.name(pretty=True).upper().replace(" ", "_")


def clone_repo():
    CACHE_DIR = os.path.expanduser("~/.cache")
    DOTNET_CACHE_DIR = os.path.expanduser("~/.cache/dotnet")
    dotnet_cache_exists = False

    if os.path.exists(f"{XIVLAUNCHER_DIR}/dotnet"):
        if os.path.exists(DOTNET_CACHE_DIR):
            dotnet_cache_exists = True
            os.remove(DOTNET_CACHE_DIR)

        os.replace(f"{XIVLAUNCHER_DIR}/dotnet", f"{CACHE_DIR}")
        os.remove(XIVLAUNCHER_DIR)

    if not os.path.exists(XIVLAUNCHER_DIR):
        os.makedirs(XIVLAUNCHER_DIR, exist_ok=True)
        git.Repo.clone_from(XIVLAUNCHERCORE_GIT, XIVLAUNCHER_DIR)

    if dotnet_cache_exists:
        os.replace(DOTNET_CACHE_DIR, XIVLAUNCHER_DIR)


def download_dotnet():
    if os.path.exists(f"{XIVLAUNCHER_DIR}/dotnet"):
        os.remove(f"{XIVLAUNCHER_DIR}/dotnet")
        os.makedirs(f"{XIVLAUNCHER_DIR}/dotnet")

    curl_command = ["curl", "-L", DOTNET_LINK]
    bsdtar_command = [
        "bsdtar", "-xf", "-", "--directory", f"{XIVLAUNCHER_DIR}/dotnet"
    ]

    curl_process = subprocess.Popen(curl_command, stdout=subprocess.PIPE)
    bsdtar_process = subprocess.Popen(bsdtar_command,
                                      stdin=curl_process.stdout)

    bsdtar_process.wait()


def get_version():
    os.chdir(XIVLAUNCHER_DIR)
    return git.Repo.tags()[0]


def build():
    os.chdir(XIVLAUNCHER_DIR)

    if git.Repo.bare:
        print("Repository is bare")
        sys.exit(1)

    os.remove(f"{XIVLAUNCHER_DIR}/build")
    git.remote.Remote.pull()
    git.Repo.submodule_update(init=True, recursive=True)

    version = get_version()

    # change branch to version tag
    git.Repo.heads[f"{version}"].checkout()

    os.chdir("src/XIVLauncher.Core")

    os.environ["DOTNET_ROOT"] = f"{XIVLAUNCHER_DIR}/dotnet"
    os.environ["PATH"] += os.pathsep + f"{XIVLAUNCHER_DIR}/dotnet"
    DISTRO_NAME = get_distro_name()

    dotnet_cmd = [
        "dotnet", "publish", "-r", "linux-x64", "--self-contained", "true",
        "--configuration", "Release", f"-p:Version={version}",
        f"-p:DefineConstants=WINE_XIV_{DISTRO_NAME}", "-o",
        f"{XIVLAUNCHER_DIR}/build"
    ]

    subprocess.run(dotnet_cmd)

    git.Repo.heads["main"].checkout()


def uninstall():
    if os.path.exists(XIVLAUNCHER_DIR):
        while True:
            option = input(
                "Do you also with to remove the local git repository? <y/n> ")

            if option in ["Y", "y"]:
                os.remove(XIVLAUNCHER_DIR)
                break
            elif option in ["N", "n"]:
                break
            else:
                continue

    files_to_remove = [
        f"{APPS_DIR}/XIVLauncher.desktop", f"{BIN_DIR}/XIVLauncher.Core",
        f"{ICONS_DIR}/xivlauncher.png"
    ]

    for file in files_to_remove:
        os.remove(file)

    print("XIVLauncher.Core was uninstalled")


def arg_parser(argv):
    parser = argparse.ArgumentParser(
        prog="XIVLauncherCLInstall",
        description="Tool to download and update XIVLauncher.Core")
    parser.add_argument("-c",
                        "--clone-repo",
                        dest="do_clone",
                        help="Clones the git repository for XIVLauncher.Core")
    parser.add_argument("-d",
                        "--download-dotnet",
                        dest="do_download",
                        help="Downloads .NET SDK 7")
    parser.add_argument("-b",
                        "--build",
                        dest="do_build",
                        help="Builds XIVLauncher.Core")
    parser.add_argument("-u",
                        "--uninstall",
                        dest="do_uninstall",
                        help="Uninstalls XIVLauncher.Core")

    args = parser.parse_args(argv)

    actions = {
        args.do_clone: clone_repo,
        args.do_download: download_dotnet,
        args.do_build: build,
        args.do_uninstall: uninstall
    }

    arg_found = False
    for arg, function in actions.items():
        if arg:
            arg_found = True
            function()

    if arg_found:
        sys.exit(0)


def clone_repo_prompt():
    option = input(
        "Do you want to clone XIVLauncher.Core's repository? <y/n> ")

    while True:
        if option in ["Y", "y"]:
            if os.path.exists(XIVLAUNCHER_DIR):
                print("The repository already exists, operation cancelled\n")
            else:
                clone_repo()
        elif option in ["N", "n"]:
            break
        else:
            continue


def download_dotnet_prompt():
    option = input("Do you want to install .NET SDK 7? <y/n> ")

    while True:
        if option in ["Y", "y"]:
            if os.path.exists(f"{XIVLAUNCHER_DIR}/dotnet"):
                option = input(
                    ".NET is already installed, do you want to re-install it?"
                    "<y/n> ")

                if option in ["N", "n"]:
                    break
                else:
                    continue

            download_dotnet()
            break
        elif option in ["N", "n"]:
            break
        else:
            continue


def build_prompt():
    option = input("Do you want to build XIVLauncher.Core? <y/n> ")

    while True:
        if option in ["Y", "y"]:
            build()

            os.makedirs(BIN_DIR, exist_ok=True)
            os.symlink(f"{XIVLAUNCHER_DIR}/build/XIVLauncher.Core", BIN_DIR)

            if not os.path.exists(f"{APPS_DIR}/XIVLauncher.desktop"):
                os.makedirs(APPS_DIR, exist_ok=True)

                desktop_file = open(f"{APPS_DIR}/XIVLauncher.desktop", "x")
                desktop_file.write(DESKTOP_ENTRY)
                desktop_file.close()

            if not os.path.exists(f"{ICONS_DIR}/xivlauncher.png"):
                os.makedirs(ICONS_DIR, exist_ok=True)
                os.symlink(f"{XIVLAUNCHER_DIR}/misc/linux_distrib/512.png",
                           f"{ICONS_DIR}/xivlauncher.png")

            print(
                f"XIVLauncher.Core {get_version()} was installed sucessfully")
            break
        elif option in ["N", "n"]:
            print("XIVLauncher wasn't built")
            break
        else:
            continue


def main(argv):
    dependencies = ["git", "curl", "bsdtar"]
    check_dependencies(dependencies)

    arg_parser(argv)

    clone_repo_prompt()

    download_dotnet_prompt()

    build_prompt()


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        print("\nScript aborted")
        sys.exit(1)
