import socket

def set_and_get_socket_timeout(timeout):

    socket.setdefaulttimeout(timeout)
    print(f"Default socket timeout set to: {timeout} seconds")

    current_timeout = socket.getdefaulttimeout()
    print(f"Current default socket timeout is: {current_timeout} seconds")

    print("Performed by: John Rave O. Camarines | BSIT 3D")

if __name__ == '__main__':
    set_and_get_socket_timeout(10)