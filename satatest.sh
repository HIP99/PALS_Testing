#!/bin/bash

# Rough script for testing the PALS v2 PCB SATA ports connection with hard-drives
# This script will need editting to match specifics of the flight computer and PALS hard-drive setup
# Usage: ./satatest.sh [config_file]

bus=1
addr=0x74

LOG_FILE="sata_test_summary.log"
> "$LOG_FILE"  # Clears the log file for new write

DEFAULT_CONFIG_FILE="sata_config.txt"
CONFIG_FILE="${1:-$DEFAULT_CONFIG_FILE}"  # Use the first argument or default to sata_config.txt

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found!"
    exit 1
fi

# Read the configuration file
declare -A PORT_DRIVE_MAP
while IFS='=' read -r PORT DRIVE; do
    [[ "$PORT" =~ ^#.*$ || -z "$PORT" ]] && continue
    PORT_DRIVE_MAP["$PORT"]="$DRIVE"
done < "$CONFIG_FILE"

# Just outputs what the file thinks the configuration is
echo "Configured PORT_DRIVE_MAP:" | tee -a "$LOG_FILE"
for PORT in "${!PORT_DRIVE_MAP[@]}"; do
    if [ "${PORT_DRIVE_MAP[$PORT]}" == "None" ]; then
        continue
    fi
    echo "Port $PORT -> PALS_${PORT_DRIVE_MAP[$PORT]}" | tee -a "$LOG_FILE"
done
echo "" >> "$LOG_FILE"


####################
# 1. Initialize GPIOs
####################

echo "Initializing ports on bus $bus, address $addr"
i2cset -y $bus $addr 0x02 0x00 &&
i2cset -y $bus $addr 0x03 0x00 &&
i2cset -y $bus $addr 0x06 0x00 &&
i2cset -y $bus $addr 0x07 0x00

## Comment this out when debugging offline
if [ $? -ne 0 ]; then
    echo "Error: Could not initialize the GPIOs" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Starting SATA port testing..."

# Initialize counters
SUCCESS_COUNT=0
TESTED_COUNT=0

# Loop through the configured ports
for PORT in "${!PORT_DRIVE_MAP[@]}"; do
    DRIVE="${PORT_DRIVE_MAP[$PORT]}"
    if [ "$DRIVE" == "None" ]; then
        # echo -e "➡️ Skipping SATA port $PORT (No drive connected)" | tee -a "$LOG_FILE"
        continue
    fi

    TESTED_COUNT=$((TESTED_COUNT + 1))

    echo "" >> "$LOG_FILE"

    FULL_DRIVE_NAME="PALS_$DRIVE"
    echo "Switching to SATA port $PORT (Drive: $FULL_DRIVE_NAME)..." | tee -a "$LOG_FILE"

    # Clear dmesg buffer. May not be neccesary if each drive has a unique distinguishable message
    ## Comment this out when debugging offline
    sudo dmesg -c > /dev/null

    ####################
    # 2. Switch SATA port
    ####################

    ./sataswitch.sh "$PORT"
    ## Comment this out when debugging offline
    if [ $? -ne 0 ]; then
        echo "Error: Failed to switch to SATA port $PORT" | tee -a "$LOG_FILE"
        continue
    fi

    ####################
    # 3. Monitor activity
    ####################

    echo "Monitoring activity on SATA port $PORT..."
    ACTIVITY_DETECTED=false
    for i in $(seq 1 60); do
        ##
        ## The exact message needs to be updated.
        ##
        if dmesg | grep -q "I cannot remember the message"; then
            ACTIVITY_DETECTED=true
            break
        fi
        sleep 1
    done

    if $ACTIVITY_DETECTED; then
        echo -e "✅ Activity detected on SATA port $PORT (Drive: $FULL_DRIVE_NAME)" | tee -a "$LOG_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "❌ No activity detected on SATA port $PORT (Drive: $FULL_DRIVE_NAME) after 60 seconds" | tee -a "$LOG_FILE"
    fi

    ####################
    # 4. Detach drive
    ####################
    if [ -e "/sys/block/$FULL_DRIVE_NAME/device/delete" ]; then
        echo "Detaching block device /dev/$FULL_DRIVE_NAME..." | tee -a "$LOG_FILE"
        echo 1 > "/sys/block/$FULL_DRIVE_NAME/device/delete"
        if [ $? -eq 0 ]; then
            echo "Block device /dev/$FULL_DRIVE_NAME detached successfully." | tee -a "$LOG_FILE"
        else
            echo "Error: Failed to detach block device /dev/$FULL_DRIVE_NAME." | tee -a "$LOG_FILE"
        fi
    else
        echo "Warning: Block device /dev/$FULL_DRIVE_NAME not found or cannot be detached." | tee -a "$LOG_FILE"
    fi

    ####################
    # 5. Turn off drives
    ####################
    echo "Turning off drives..."
    ./sataswitch.sh
    echo "Waiting 10 seconds for drives to power down..."
    sleep 10

    echo "" >> "$LOG_FILE"
done

# Print summary
echo ""
echo ""
echo "" >> "$LOG_FILE"
echo "Summary: $SUCCESS_COUNT/$TESTED_COUNT ports working" >> "$LOG_FILE"
echo "SATA port testing completed. Summary:"
cat "$LOG_FILE"