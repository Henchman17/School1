import socket
import threading

clients = {}  # Maps client_socket to username
clients_lock = threading.Lock()

def broadcast(message, sender_socket):
    with clients_lock:
        for client in clients:
            if client != sender_socket:
                try:
                    client.sendall(message.encode())
                except Exception:
                    # Ignore broken pipe errors, other client will be handled in their thread
                    pass

def handle_client(client_socket, client_address):
    ip = client_address[0]
    print(f"Connection attempt from {ip}")

    # Example IP confirmation - allow all for now, you can restrict here
    allowed_ips = ['127.0.0.1', 'localhost']  # Adjust as necessary or remove whitelist check to accept all
    # For simplicity, let's allow all IPs in this example:
    if ip not in allowed_ips:
        print(f"Rejected connection from {ip}")
        client_socket.sendall("Your IP is not allowed to connect.\n".encode())
        client_socket.close()
        return

    try:
        # First message expected: username
        client_socket.sendall("Please enter your username: ".encode())
        username = client_socket.recv(1024).decode().strip()
        if not username:
            client_socket.close()
            return

        with clients_lock:
            clients[client_socket] = username

        print(f"{username} ({ip}) connected.")
        broadcast(f"[{username} has joined the chat]", client_socket)
        client_socket.sendall(f"Welcome to the chat, {username}!\n".encode())

        while True:
            message = client_socket.recv(1024).decode()
            if not message:
                break
            message = message.strip()
            if message:
                full_message = f"{username}: {message}"
                print(full_message)
                broadcast(full_message, client_socket)

    except ConnectionResetError:
        pass
    finally:
        with clients_lock:
            if client_socket in clients:
                left_username = clients.pop(client_socket)
                print(f"{left_username} ({ip}) disconnected")
                broadcast(f"[{left_username} has left the chat]", client_socket)
        client_socket.close()

def start_server(host='127.0.0.1', port=65432):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen()
    print(f"Chat server started on {host}:{port}")

    try:
        while True:
            client_socket, client_address = server_socket.accept()
            threading.Thread(target=handle_client, args=(client_socket, client_address), daemon=True).start()
    except KeyboardInterrupt:
        print("\nServer shutting down...")
    finally:
        server_socket.close()

if __name__ == "__main__":
    start_server()
