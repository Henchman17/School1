import sys, socket

def create_socket():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        return s
    except socket.error as e:
        print(f"Socket creation error: {e}")
        sys.exit(1)

def connect_to_server(s, host, port):
    try:
        s.connect((host, port))
        print(f"Connected to the server.")
    except socket.gaierror as e:
        print(f"Address-related error connecting to server: {e}")
    except socket.timeout as e:
        print(f"Connection timed out: {e}")
    except socket.error as e:
        print(f"Socket error: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    
    print(f"Performed by: John Rave O. Camarines | BSIT 3D")

def main():
    host = 'localhost'
    port = int(input("Enter port: "))

    s = create_socket()
    
    connect_to_server(s, host, port)

    s.close

if __name__ == '__main__':
    main()