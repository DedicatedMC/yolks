
# ------------------------------------------------------------------------------
#
#  Pterodactyl Docker Image: Minecraft - Forge
#  Link: https://github.com/pelican-eggs/yolks/tree/master/minecraft/forge
#
# ------------------------------------------------------------------------------
#
#  ATTENTION: This file was automatically generated via templating.
#
#             YOU SHOULD NOT MODIFY THIS FILE DIRECTLY.
#
#             To update this image, please modify the corresponding template
#             file, which is located in the `.github/templates` directory.
#
# ------------------------------------------------------------------------------
FROM        --platform=${TARGETPLATFORM:-linux/amd64} ghcr.io/pterodactyl/yolks:java_17

LABEL       author="Mark" maintainer="mark@ibh.group"

ENV         SERVER_JARFILE="forge.jar"

USER        root

RUN         apt-get update \
            && apt-get install -y --no-install-recommends \
                jq

USER        container

COPY        --chown=container:container ../entrypoint.sh /entrypoint.sh

CMD         ["/bin/bash", "/entrypoint.sh"]
