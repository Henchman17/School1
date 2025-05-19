import socket, sys

def create_socket():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        return s
    except socket.error as e:
        print(f"Socket creation error: {e}")

def enable_address_reuse(s):
    try:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        print("Address reuse enabled.")
    except socket.error as e:
        print(f"Error enabling address reuse: {e}")

def bind_socket(s, host, port):
    try:
        s.bind((host, port))
        print(f"Socket bound to {host}:{port}")
    except socket.error as e:
        print(f"Error binding socket: {e}")

    print("Performed by: John Rave O. Camarines | BSIT 3D")

def main():
    host = 'localhost'
    port = int(input("Enter port: "))

    s = create_socket()

    enable_address_reuse(s)

    bind_socket(s, host, port)

    s.listen(5)
    print("Listening for incoming connections...")

    conn, addr = s.accept()
    print(f"Connection accepted from {addr}")

    conn.close()
    s.close()

if __name__ == '__main__':
    main()