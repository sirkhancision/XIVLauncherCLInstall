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
from shutil import which, move, rmtree


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
    DOTNET_DIR = os.path.join(XIVLAUNCHER_DIR, "dotnet")
    DOTNET_CACHE_DIR = os.path.expanduser("~/.cache/dotnet")
    dotnet_cache_exists = os.path.exists(DOTNET_CACHE_DIR)

    if os.path.exists(DOTNET_DIR):
        if dotnet_cache_exists:
            rmtree(DOTNET_CACHE_DIR)

        move(
            DOTNET_DIR,
            DOTNET_CACHE_DIR,
        )
        rmtree(XIVLAUNCHER_DIR)

    os.makedirs(XIVLAUNCHER_DIR, exist_ok=True)
    if not os.listdir(XIVLAUNCHER_DIR):
        print("Cloning remote repository...")
        git.Repo.clone_from(XIVLAUNCHERCORE_GIT, XIVLAUNCHER_DIR)

    if dotnet_cache_exists:
        move(DOTNET_CACHE_DIR, XIVLAUNCHER_DIR)

    print("XIVLauncher.Core cloned")


def download_dotnet():
    DOTNET_DIR = os.path.join(XIVLAUNCHER_DIR, "dotnet")

    if os.path.exists(DOTNET_DIR):
        rmtree(DOTNET_DIR)

    os.makedirs(DOTNET_DIR)

    curl_command = ["curl", "-L", DOTNET_LINK]
    bsdtar_command = ["bsdtar", "-xf", "-", "--directory", DOTNET_DIR]

    curl_process = subprocess.Popen(curl_command, stdout=subprocess.PIPE)
    bsdtar_process = subprocess.Popen(bsdtar_command,
                                      stdin=curl_process.stdout)

    bsdtar_process.wait()

    if bsdtar_process.returncode != 0:
        rmtree(DOTNET_DIR)


def get_version():
    os.chdir(XIVLAUNCHER_DIR)
    repository = git.Repo()
    tags = repository.tags
    latest_tag = str(repository.tag(tags[-1]))
    return latest_tag


def build():
    os.chdir(XIVLAUNCHER_DIR)

    try:
        repository = git.Repo()
    except git.InvalidGitRepositoryError:
        print("Invalid git repository passed")
        sys.exit(1)

    BUILD_DIR = os.path.join(XIVLAUNCHER_DIR, "build")

    if os.path.exists(BUILD_DIR):
        rmtree(BUILD_DIR)

    remote_origin = repository.remote(name="origin")

    print("Pulling changes...")
    remote_origin.pull()

    print("Updating submodules...")
    repository.submodule_update(init=True, recursive=True)

    version = get_version()
    version_pretty = version.replace("v", "")

    # change branch to version tag
    repository.git.checkout(version)
    latest_branch = repository.create_head("latest", "HEAD")
    repository.head.reference = latest_branch

    os.chdir("src/XIVLauncher.Core")

    DOTNET_DIR = os.path.join(XIVLAUNCHER_DIR, "dotnet")

    os.environ["DOTNET_ROOT"] = DOTNET_DIR
    os.environ["PATH"] += os.pathsep + DOTNET_DIR
    DISTRO_NAME = get_distro_name()

    dotnet_cmd = [
        "dotnet", "publish", "-r", "linux-x64", "--self-contained", "true",
        "--configuration", "Release", f"-p:Version={version_pretty}",
        f"-p:DefineConstants=WINE_XIV_{DISTRO_NAME}", "-o", BUILD_DIR
    ]

    subprocess.run(dotnet_cmd)

    repository.heads["main"].checkout()


def uninstall():
    if os.path.exists(XIVLAUNCHER_DIR):
        while True:
            option = input(
                "Do you also with to remove the local git repository? <y/n> ")

            if option in ["Y", "y"]:
                rmtree(XIVLAUNCHER_DIR)
                break
            elif option in ["N", "n"]:
                break
            else:
                continue

    files_to_remove = [
        os.path.join(directory, filename) for directory, filename in [(
            APPS_DIR, "XIVLauncher.desktop"), (
                BIN_DIR, "XIVLauncher.Core"), (ICONS_DIR, "xivlauncher.png")]
    ]

    for file in files_to_remove:
        try:
            os.remove(file)
        except FileNotFoundError:
            print(f"{file} not found, ignoring it...")
            continue

    print("XIVLauncher.Core was uninstalled")


def arg_parser(argv):
    parser = argparse.ArgumentParser(
        prog="XIVLauncherCLInstall",
        description="Tool to download and update XIVLauncher.Core")
    parser.add_argument("-c",
                        "--clone-repo",
                        action="store_true",
                        help="Clones the git repository for XIVLauncher.Core")
    parser.add_argument("-d",
                        "--download-dotnet",
                        action="store_true",
                        help="Downloads .NET SDK 7")
    parser.add_argument("-b",
                        "--build",
                        action="store_true",
                        help="Builds XIVLauncher.Core")
    parser.add_argument("-u",
                        "--uninstall",
                        action="store_true",
                        help="Uninstalls XIVLauncher.Core")

    args = parser.parse_args(argv)

    actions = {
        args.clone_repo: clone_repo,
        args.download_dotnet: download_dotnet,
        args.build: build,
        args.uninstall: uninstall
    }

    if any(actions):
        for arg, function in actions.items():
            if arg:
                function()
        sys.exit(0)


def clone_repo_prompt():
    option = input(
        "Do you want to clone XIVLauncher.Core's repository? <y/n> ")

    while True:
        if option in ["Y", "y"]:
            if os.path.exists(XIVLAUNCHER_DIR):
                print("The repository already exists, operation cancelled\n")
                break
            else:
                clone_repo()
                break
        elif option in ["N", "n"]:
            break
        else:
            continue


def download_dotnet_prompt():
    option = input("Do you want to install .NET SDK 7? <y/n> ")

    while True:
        if option in ["Y", "y"]:
            if os.path.exists(os.path.join(XIVLAUNCHER_DIR, "dotnet")):
                option = input(
                    ".NET is already installed, do you want to re-install it? "
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

            xivlauncher_binary_path = os.path.join(BIN_DIR, "XIVLauncher.Core")

            if not os.path.lexists(xivlauncher_binary_path):
                os.symlink(
                    os.path.join(XIVLAUNCHER_DIR, "build/XIVLauncher.Core"),
                    xivlauncher_binary_path)

            xivlauncher_desktop_path = os.path.join(APPS_DIR,
                                                    "XIVLauncher.desktop")

            if not os.path.exists(xivlauncher_desktop_path):
                os.makedirs(APPS_DIR, exist_ok=True)

                desktop_file = open(xivlauncher_desktop_path, "x")
                desktop_file.write(DESKTOP_ENTRY)
                desktop_file.close()

            xivlauncher_icon_path = os.path.join(ICONS_DIR, "xivlauncher.png")

            if not os.path.exists(xivlauncher_icon_path):
                os.makedirs(ICONS_DIR, exist_ok=True)
                if not os.path.lexists(xivlauncher_icon_path):
                    os.symlink(
                        os.path.join(XIVLAUNCHER_DIR,
                                     "misc/linux_distrib/512.png"),
                        xivlauncher_icon_path)

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
