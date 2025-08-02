#!/bin/bash
# shellcheck disable=SC2086,SC2154,SC2230

#
# MIT License
#
# Copyright (c) 2021-2022 DaneEveritt
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

#
# DO NOT MODIFY THIS FILE
#
# This file is part of the Pterodactyl Jars auto-updating script. This file
# is downloaded from the Pterodactyl Jars repository at the time the server
# is installed, and updated periodically.
#
# https://github.com/pelican-eggs/jars
#

#
# This script is designed to be used with the Pterodactyl Minecraft eggs. It will
# automatically download the latest version of the specified Minecraft server software
# and install it.
#
# It is not designed to be run directly by the user. It is designed to be run
# by the Pterodactyl daemon.
#

##
## Jars Functions
##

# Backwards compatibility for eggs that have not been updated to use the new
# `jars` functions.
function get_latest_version() {
    jars_get_latest_version "$1"
}

function install_jar() {
    jars_install_jar "$1"
}

# Get the latest version of the specified software.
#
# $1: software name (e.g. "paper")
function jars_get_latest_version() {
    local software="$1"
    local version_url

    case "${software}" in
        "paper" )
            version_url="https://api.papermc.io/v2/projects/paper"
            ;;
        "travertine" )
            version_url="https://api.papermc.io/v2/projects/travertine"
            ;;
        "waterfall" )
            version_url="https://api.papermc.io/v2/projects/waterfall"
            ;;
        "velocity" )
            version_url="https://api.papermc.io/v2/projects/velocity"
            ;;
        "purpur" )
            version_url="https://api.purpurmc.org/v2/purpur"
            ;;
        "fabric" )
            version_url="https://meta.fabricmc.net/v2/versions/installer"
            ;;
        "forge" )
            if [ -z "$MINECRAFT_VERSION" ]; then
                echo "Minecraft version not set."
                exit 1
            fi
            version_url="https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json"
            ;;
        "quilt" )
            if [ -z "$MINECRAFT_VERSION" ]; then
                echo "Minecraft version not set."
                exit 1
            fi
            version_url="https://meta.quiltmc.org/v3/versions/loader/${MINECRAFT_VERSION}"
            ;;
        "bungeecord" )
            version_url="https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/api/json"
            ;;
        "spigot" )
            version_url="https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/api/json"
            ;;
        *)
            echo "Unsupported software: ${software}"
            exit 1
            ;;
    esac

    if [ "$MINECRAFT_VERSION" == "latest" ]; then
        if [ "$software" == "purpur" ] || [ "$software" == "paper" ]; then
            VERSION=$(curl -sSL "$version_url" | jq -r '.versions[-1]')
        elif [ "$software" == "fabric" ]; then
            VERSION=$(curl -sSL "$version_url" | jq -r '.[0].version')
        elif [ "$software" == "quilt" ]; then
            VERSION=$(curl -sSL "$version_url" | jq -r '.[0].loader.version')
        else
            echo "The 'latest' version is not supported for this software."
            exit 1
        fi
    else
        VERSION="$MINECRAFT_VERSION"
    fi
}

# Install the specified jar.
#
# $1: software name (e.g. "paper")
function jars_install_jar() {
    local software="$1"
    local download_url

    cd /mnt/server || exit

    echo "Installing ${software} ${VERSION}"

    case "${software}" in
        "paper" )
            BUILD=$(curl -sSL "https://api.papermc.io/v2/projects/paper/versions/${VERSION}" | jq -r '.builds[-1]')
            download_url="https://api.papermc.io/v2/projects/paper/versions/${VERSION}/builds/${BUILD}/downloads/paper-${VERSION}-${BUILD}.jar"
            ;;
        "travertine" )
            BUILD=$(curl -sSL "https://api.papermc.io/v2/projects/travertine/versions/${VERSION}" | jq -r '.builds[-1]')
            download_url="https://api.papermc.io/v2/projects/travertine/versions/${VERSION}/builds/${BUILD}/downloads/travertine-${VERSION}-${BUILD}.jar"
            ;;
        "waterfall" )
            BUILD=$(curl -sSL "https://api.papermc.io/v2/projects/waterfall/versions/${VERSION}" | jq -r '.builds[-1]')
            download_url="https://api.papermc.io/v2/projects/waterfall/versions/${VERSION}/builds/${BUILD}/downloads/waterfall-${VERSION}-${BUILD}.jar"
            ;;
        "velocity" )
            BUILD=$(curl -sSL "https://api.papermc.io/v2/projects/velocity/versions/${VERSION}" | jq -r '.builds[-1]')
            download_url="https://api.papermc.io/v2/projects/velocity/versions/${VERSION}/builds/${BUILD}/downloads/velocity-${VERSION}-${BUILD}.jar"
            ;;
        "purpur" )
            BUILD=$(curl -sSL "https://api.purpurmc.org/v2/purpur/${VERSION}" | jq -r '.builds.latest')
            download_url="https://api.purpurmc.org/v2/purpur/${VERSION}/${BUILD}/download"
            ;;
        "fabric" )
            download_url="https://meta.fabricmc.net/v2/versions/installer/$(curl -sSL 'https://meta.fabricmc.net/v2/versions/installer' | jq -r '.[0].version')/$(curl -sSL 'https://meta.fabricmc.net/v2/versions/installer' | jq -r '.[0].version')/fabric-server-launch.jar"
            ;;
        "forge" )
            FORGE_VERSION=$(curl -sSL "https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json" | jq -r ".promos[\"${VERSION}-latest\"]")
            if [ -z "$FORGE_VERSION" ]; then
                echo "No recommended Forge version found for Minecraft ${VERSION}."
                exit 1
            fi
            download_url="https://files.minecraftforge.net/net/minecraftforge/forge/index_${VERSION}/${FORGE_VERSION}/forge-${VERSION}-${FORGE_VERSION}-installer.jar"
            ;;
        "quilt" )
            download_url="https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/${QUILT_INSTALLER_VERSION}/quilt-installer-${QUILT_INSTALLER_VERSION}.jar"
            ;;
        "bungeecord" )
            BUILD=$(curl -sSL "https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/api/json" | jq -r '.number')
            download_url="https://ci.md-5.net/job/BungeeCord/${BUILD}/artifact/bootstrap/target/BungeeCord.jar"
            ;;
        "spigot" )
            BUILD=$(curl -sSL "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/api/json" | jq -r '.number')
            download_url="https://hub.spigotmc.org/jenkins/job/BuildTools/${BUILD}/artifact/target/BuildTools.jar"
            ;;
        *)
            echo "Unsupported software: ${software}"
            exit 1
            ;;
    esac

    # Download and install the jar.
    if [ -f "${SERVER_JARFILE}" ]; then
        # Don't redownload the jar if it's already there.
        echo "Jar already exists, skipping download."
    else
        echo "Downloading jar from ${download_url}"
        curl -sSL -o "${SERVER_JARFILE}" "${download_url}"

        # If the software is Spigot or Forge, we need to run the installer.
        if [ "${software}" == "spigot" ]; then
            echo "Running BuildTools..."
            java -jar "${SERVER_JARFILE}" --rev "${VERSION}"
            cp "spigot-${VERSION}.jar" "server.jar"
        elif [ "${software}" == "forge" ]; then
            echo "Running Forge installer..."
            java -jar "${SERVER_JARFILE}" --installServer
            # The forge universal jar is now named "forge-x.x.x-x.x.x.jar", so we need to find it.
            find . -name "forge-*-universal.jar" -exec mv {} "${SERVER_JARFILE}" \;
        elif [ "${software}" == "fabric" ]; then
            echo "Running Fabric installer..."
            java -jar "${SERVER_JARFILE}" server -mcversion "${MINECRAFT_VERSION}" -downloadMinecraft
            mv "fabric-server-launch.jar" "${SERVER_JARFILE}"
        fi
    fi
}
