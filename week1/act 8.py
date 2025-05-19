import socket, sys

def create_socket():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        return s
    except socket.error as e:
        print(f"Socket creation error: {e}")
        sys.exit(1)

def set_buffer_sizes(s, send_buffer_size, recieve_buffer_size):
    try:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, send_buffer_size)
        print(f"Send buffer size set to: {send_buffer_size} bytes")

        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, recieve_buffer_size)
        print(f"Recieve buffer size set to: {recieve_buffer_size} bytes")
    except socket.error as e:
        print(f"Error setting buffer sizes: {e}")

def get_buffer_sizes(s):
    current_sent_buffer_size = s.getsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF)
    print(f"Current send buffer size: {current_sent_buffer_size} bytes")

    print(f"Performed by: John Rave O. Camarines | BSIT 3D")

def main():
    send_buffer_size  = int(input("Enter send buffer size: "))
    recieve_buffer_size  = int(input("Enter recieve buffer size: "))

    s = create_socket()

    set_buffer_sizes(s, send_buffer_size, recieve_buffer_size)

    get_buffer_sizes(s)

    s.close()

if __name__ == '__main__':
    main()