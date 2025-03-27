#!/usr/bin/env python3

import socket
import sys

def wake_on_lan(mac_address, broadcast_ip='255.255.255.255', port=9):
    # Validate MAC address
    mac_address = mac_address.replace(':', '').replace('-', '')
    if len(mac_address) != 12:
        raise ValueError("Invalid MAC address. Must be 12 hexadecimal characters.")

    # Create magic packet
    mac_bytes = bytes.fromhex(mac_address)
    magic_packet = b'\xff' * 6 + mac_bytes * 16

    # Create UDP socket
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.sendto(magic_packet, (broadcast_ip, port))
    
    print(f"Wake-on-LAN packet sent to {mac_address}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage  : python3 wake_on_lan.py <MAC_ADDRESS> [BROADCAST_IP]")
        print("Example: python3 wake_on_lan.py 30:9c:23:8e:5a:0c 192.168.0.255")
        sys.exit(1)
    
    mac = sys.argv[1]
    broadcast_ip = sys.argv[2] if len(sys.argv) > 2 else '255.255.255.255'
    
    try:
        wake_on_lan(mac, broadcast_ip)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
