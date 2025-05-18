import socket

def get_service_name(port, protocol):
    try:
        protocol = protocol.lower()

        service_name = socket.getservbyport(port, protocol)
        return service_name
    except OSError as e:
        return f"Error retrieving service name: {e}"
    
port = 80
protocol = 'tcp'
service = get_service_name(port, protocol)

print(f"The service running on port {port} ({protocol.upper()}) is: {service}")
print("Performed by: John Rave O. Camarines | BSIT 3D")

if __name__ == '__main__':
    get_service_name