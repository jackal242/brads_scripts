#!/bin/bash
# Usage of raw command:
#       wakeonlan -i 192.168.0.255 30:9C:23:8E:5A:0C


BLACKLIST="192.168.0.1 192.168.0.255 224.0.0.251"

# Run arp -a and capture the output
arp_output=$(arp -a)

# Process each line of the arp output
while IFS= read -r line; do
  # Extract the IP address - different approach that won't cause syntax errors
  ip_address=$(echo "$line" | grep -o '([0-9.]*)'| tr -d '()')

  # Check if the IP address is in the blacklist
  skip=0
  for blacklisted_ip in $BLACKLIST; do
    if [[ "$ip_address" == "$blacklisted_ip" ]]; then
      echo "Skipping blacklisted IP: $ip_address"
      skip=1
      break
    fi
  done
  
  # Skip this IP if it's in the blacklist
  if [[ $skip -eq 1 ]]; then
    continue
  fi

  # Extract the MAC address (typically in the format xx:xx:xx:xx:xx:xx)
  mac_address=$(echo "$line" | grep -Eo '([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2}')
  
  # If we found a MAC address, process it
  if [ -n "$mac_address" ]; then
    # Add leading zeros where necessary
    fixed_mac=""
    IFS=':' read -ra MAC_PARTS <<< "$mac_address"
    
    for part in "${MAC_PARTS[@]}"; do
      # If the part is one character, add a leading zero
      if [[ ${#part} -eq 1 ]]; then
        fixed_mac+="0$part:"
      else
        fixed_mac+="$part:"
      fi
    done
    
    # Remove the trailing colon
    fixed_mac=${fixed_mac%:}
    
    echo "Found MAC: $mac_address -> Fixed: $fixed_mac (IP: $ip_address)"
    
    # Run wakeonlan against the fixed MAC address
    echo "Running: wakeonlan $fixed_mac"
    wakeonlan -i 192.168.0.255 "$fixed_mac"
    
    # Add a blank line for better readability
    echo ""
  fi
done <<< "$arp_output"

echo "Wake-on-LAN commands sent to all discovered MAC addresses."
