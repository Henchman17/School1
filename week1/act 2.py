import socket

def get_ip_address(hostname):
    try:
        ip_address = socket.gethostbyname(hostname)
        return ip_address
    except socket.gaierror as e:
        return f"Erroe retrieving IP address: {e}"
    
hostname = 'www.google.com'
ip = get_ip_address(hostname)
print(f"The IP address of {hostname} is {ip}")
print("Performed by: John Rave O. Camarines | BSIT 3D")

if __name__ == '__main__':
    get_ip_address