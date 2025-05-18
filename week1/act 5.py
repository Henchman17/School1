import socket

def convert_byte_order():

    port = 12345
    network_order_port = socket.htons(port)
    print(f"Host to Network Byte Order (16-bit): {network_order_port}")

   
    host_order_port = socket.ntohs(network_order_port)
    print(f"Network to Host Byte Order (16-bit): {host_order_port}")

   
    ip_integer = 123456789
    network_order_ip = socket.htonl(ip_integer)
    print(f"Host to Network Byte Order (32-bit): {network_order_ip}")


    host_order_ip = socket.ntohl(network_order_ip)
    print(f"Network to Host Byte Order (32-bit): {host_order_ip}")

    print("Performed by: John Rave O. Camarines | BSIT 3D")

if __name__ == '__main__':
    convert_byte_order()
    
