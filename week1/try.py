import socket

def convert_byte_order():
    # Example 16-bit integer
    port = 12345
    # Convert from host to network byte order
    network_order_port = socket.htons(port)
    print(f"Host to Network Byte Order (16-bit): {network_order_port}")

    # Convert back from network to host byte order
    host_order_port = socket.ntohs(network_order_port)
    print(f"Network to Host Byte Order (16-bit): {host_order_port}")

    # Example 32-bit integer
    ip_integer = 123456789
    # Convert from host to network byte order
    network_order_ip = socket.htonl(ip_integer)
    print(f"Host to Network Byte Order (32-bit): {network_order_ip}")

    # Convert back from network to host byte order
    host_order_ip = socket.ntohl(network_order_ip)
    print(f"Network to Host Byte Order (32-bit): {host_order_ip}")

# Run the conversion
convert_byte_order()
