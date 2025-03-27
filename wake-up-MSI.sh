#!/bin/bash

# Predefined MAC address
MAC_ADDRESS="30:9c:23:8e:5a:c"  # My MSI desktop MAC address to wake up
#MAC_ADDRESS="30:9C:23:8E:5A:0C"

# Default broadcast IP (adjust if needed)
BROADCAST_IP="192.168.0.255"

# Function to validate MAC address
validate_mac() {
    # Remove any existing whitespace
    local cleaned_mac=$(echo "$1" | tr -d ' ')
    
    # Split into octets
    IFS=':' read -ra ADDR <<< "$cleaned_mac"
    
    # Validate we have 6 octets
    if [[ ${#ADDR[@]} -ne 6 ]]; then
        echo "Invalid MAC address: Must have 6 octets" >&2
        return 1
    fi
    
    echo "$cleaned_mac"
}

# Validate MAC address
formatted_mac=$(validate_mac "$MAC_ADDRESS")
if [[ $? -ne 0 ]]; then
    echo "MAC address validation failed" >&2
    exit 1
fi

# Check if wakeonlan is installed
if ! command -v wakeonlan &> /dev/null; then
    echo "wakeonlan command not found. Please install it." >&2
    exit 1
fi

# Send Wake-on-LAN packet
echo "Sending Wake-on-LAN to $formatted_mac"
wakeonlan -i $BROADCAST_IP $formatted_mac

echo "Wake-on-LAN command completed."
