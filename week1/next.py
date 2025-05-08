import socket

def print_machine_name():
    remote_host = 'www.youtube.com'
    try:
        print("IP address of %s: %s" %(remote_host,socket.gethostbyname(remote_host)))
    except socket.error as err_msg:
        print("%s: %s" %(remote_host, err_msg))

if __name__ == '__main__':
    print_machine_name()