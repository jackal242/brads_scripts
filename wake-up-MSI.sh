#!/bin/bash
# Old Example: wakeonlan -i 192.168.0.255 30:9C:23:8E:5A:0C

# List of MAC addresses to wake up
# Add or remove MAC addresses as needed
MAC_ADDRESSES=(
  "9C:36:D0:20:B6:F1"  # Device 1 (e.g., Gaming PC - Wi-Fi)
  "30:9C:23:8E:5A:0C"  # Device 1 (e.g., Gaming PC - Ethernet 2)
)

# Function to ensure MAC address has leading zeros where needed
fix_mac_format() {
  local mac="$1"
  local fixed_mac=""
  
  IFS=':' read -ra MAC_PARTS <<< "$mac"
  
  for part in "${MAC_PARTS[@]}"; do
    # If the part is one character, add a leading zero
    if [[ ${#part} -eq 1 ]]; then
      fixed_mac+="0$part:"
    else
      fixed_mac+="$part:"
    fi
  done
  
  # Remove the trailing colon
  echo "${fixed_mac%:}"
}

# Loop through each MAC address
for mac in "${MAC_ADDRESSES[@]}"; do
  # Fix MAC address format if needed
  fixed_mac=$(fix_mac_format "$mac")
  
  echo "Sending Wake-on-LAN packet to: $fixed_mac"
  
  # Define the command based on available tools
  if command -v wakeonlan &> /dev/null; then
    CMD="wakeonlan -i 192.168.0.255 \"$fixed_mac\""
  elif [ -f "./wakeonlan.sh" ]; then
    CMD="./wakeonlan.sh \"$fixed_mac\""
  else
    CMD="python -c \"import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); mac=bytes.fromhex('${fixed_mac}'.replace(':', '')); s.sendto(bytes.fromhex('FF'*6) + mac*16, ('255.255.255.255', 9))\""
  fi
  
  # Echo the command being executed
  echo "Running command: $CMD"
  
  # Execute the command
  eval "$CMD" 

  echo "Wake packet sent to $fixed_mac"
  echo "------------------------"
  
  # Optional: Add a small delay between sending packets
  sleep 1
done

echo "All wake packets sent successfully!"
