
#!/bin/bash
# shellcheck disable=SC2086,SC2154,SC2230
cd /home/container || exit

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $NF;exit}')
export INTERNAL_IP

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')

#
# Boring legal stuff
#
if [ ! -f "eula.txt" ]; then
    echo "eula=true" > eula.txt
fi

#
# Perform actions specific to the egg
#
# shellcheck source=/dev/null
source /egg_actions.sh

#
# Run the server
#
echo "Running: ${MODIFIED_STARTUP}"
${MODIFIED_STARTUP}
