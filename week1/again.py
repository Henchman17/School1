import socket
from binascii import hexlify

def convert_ipv4_address(ip_addr):
    try:
        # Convert the IP address to a packed binary format
        packed_ip = socket.inet_pton(socket.AF_INET, ip_addr)
        # Convert the packed binary format to hexadecimal
        hex_ip = hexlify(packed_ip).decode('utf-8')
        return hex_ip
    except socket.error as e:
        return f"Invalid IP address: {e}"

# Example usage
ip_address = "127.0.0.1"
hexadecimal = convert_ipv4_address(ip_address)
print(f"The hexadecimal representation of {ip_address} is: {hexadecimal}")
