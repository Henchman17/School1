import socket
import threading
import sys

def receive_messages(sock):
    try:
        while True:
            message = sock.recv(1024)
            if not message:
                print("\nDisconnected from server")
                break
            print("\n" + message.decode() + "\n> ", end='', flush=True)
    except ConnectionResetError:
        print("\nConnection closed by server")
    except Exception as e:
        print(f"\nError: {e}")
    finally:
        sys.exit()

def start_client(host='127.0.0.1', port=65432):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.connect((host, port))
    except ConnectionRefusedError:
        print("Unable to connect to the server. Make sure the server is running.")
        return

    print(f"Connected to chat server at {host}:{port}")

    # Receive initial prompt for username
    username_prompt = sock.recv(1024).decode()
    username = input(username_prompt)
    sock.sendall(username.encode())

    threading.Thread(target=receive_messages, args=(sock,), daemon=True).start()

    try:
        while True:
            message = input("> ")
            if message.lower() in ('exit', 'quit'):
                print("Exiting chat...")
                break
            if message.strip() == '':
                continue
            sock.sendall(message.encode())
    except KeyboardInterrupt:
        print("\nExiting chat...")
    finally:
        sock.close()

if __name__ == "__main__":
    start_client()
