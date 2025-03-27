#!/bin/bash

# Default configuration
BROADCAST_IP="192.168.0.255"
BLACKLIST=(
  "192.168.0.1"
  "192.168.0.255"
  "224.0.0.251"
)

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Validate dependencies
if ! command_exists wakeonlan; then
  echo "Error: wakeonlan command not found. Please install it."
  exit 1
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -b|--broadcast) BROADCAST_IP="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Run arp and capture output
arp_output=$(arp -a)

# Process each line of the arp output
while IFS= read -r line; do
  # Extract IP address
  ip_address=$(echo "$line" | grep -o '([0-9.]*)'| tr -d '()')
  
  # Skip blacklisted IPs
  skip=0
  for blacklisted_ip in "${BLACKLIST[@]}"; do
    if [[ "$ip_address" == "$blacklisted_ip" ]]; then
      echo "Skipping blacklisted IP: $ip_address"
      skip=1
      break
    fi
  done
  
  [[ $skip -eq 1 ]] && continue
  
  # Extract full MAC address (6 parts)
  mac_address=$(echo "$line" | grep -Eo '([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2}')
  
  if [[ -n "$mac_address" ]]; then
    # Ensure two-digit MAC address octets and convert to UPPERCASE
    # Split by colon, pad each part, then rejoin
    IFS=':' read -ra MAC_PARTS <<< "$mac_address"
    fixed_mac=""
    for part in "${MAC_PARTS[@]}"; do
      # Pad single-digit parts with leading zero and convert to uppercase
      padded_part=$(printf "%02X" "0x$part")
      fixed_mac+="$padded_part:"
    done
    
    # Remove trailing colon
    fixed_mac=${fixed_mac%:}
    
    echo "Sending Wake-on-LAN to $fixed_mac (IP: $ip_address)"
    wakeonlan -i "$BROADCAST_IP" "$fixed_mac"
  fi
done <<< "$arp_output"

echo "Wake-on-LAN commands completed."
