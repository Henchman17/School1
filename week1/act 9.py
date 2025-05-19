import socket, time

def create_socket():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        return s
    except socket.error as e:
        print(f"Socket creation error: {e}")
        return None
    
def set_blocking_mode(s, blocking):
    s.setblocking(blocking)
    mode = "blocking" if blocking else "non-blocking"
    print(f"Socket set to {mode} mode.")

def connect_to_server(s, host, port):
    try:
        s.connect((host, port))
        print("Connnected to the server.")
    except BlockingIOError:
        print("Connection attempt in non-blocking mode failed. Try again later.")
    except socket.error as e:
        print(f"Socket error: {e}")

    print("Performed by: John Rave O. Camarines | BSIT 3D")

def main():
    host = 'localhost'
    port = int(input("Enter port: "))

    s = create_socket()
    if s is None:
        return
    
    set_blocking_mode(s, False)

    connect_to_server(s, host, port)

    time.sleep(2)

    set_blocking_mode(s, True)

    try:
        connect_to_server(s, host, port)
    except socket.error as e:
        print(f"Socket error: {e}")

    s.close

if __name__ == '__main__':
    main()