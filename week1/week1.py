import socket

def print_machine_name():
    host_name = socket.gethostname() #Getting host name
    ip_address = socket.gethostbyname(host_name) #Getting IP Address
    print("Host name: %s" %host_name)
    print("IP Address: %s" %ip_address)

    print("Performed by: John Rave O. Camarines | BSIT 3D")

if __name__ == '__main__':
    print_machine_name()