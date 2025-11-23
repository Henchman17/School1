import socket
import struct
import sys
import ntplib
from time import ctime


def print_menu():
    print("\nSocket/Network Code Inspections Menu:")
    print("1. Print your machine's name and IPv4 address")
    print("2. Retrieve a remote machine's IP address")
    print("3. Convert an IPv4 address to different formats")
    print("4. Find a service name, given the port and protocol")
    print("5. Convert integers to and from host to network byte order")
    print("6. Set and get the default socket timeout")
    print("7. Handle socket errors gracefully")
    print("8. Modify a socket's send/receive buffer size")
    print("9. Change a socket to the blocking/non-blocking mode")
    print("10. Reuse socket addresses")
    print("11. Print the current time from the internet time server")
    print("0. Exit")

def option_1():
    # Printing your machine's name and IPv4 address
    try:
        hostname = socket.gethostname()
        print(f"Your machine's hostname is: {hostname}")
        ip_address = socket.gethostbyname(hostname)
        print(f"Your machine's IPv4 address is: {ip_address}")
    except Exception as e:
        print(f"Error: {e}")

def option_2():
    # Retrieving a remote machine's IP address
    host = input("Enter the remote hostname or IP address: ").strip()
    try:
        ip = socket.gethostbyname(host)
        print(f"The IP address of {host} is: {ip}")
    except socket.gaierror:
        print("Hostname could not be resolved.")
    except Exception as e:
        print(f"Error: {e}")

def option_3():
    # Converting an IPv4 address to different formats
    ip_str = input("Enter an IPv4 address (e.g., 192.168.1.1): ").strip()
    try:
        packed_ip = socket.inet_aton(ip_str)  # packed binary format
        print(f"Packed binary format: {packed_ip}")
        # convert to integer (network byte order)
        ip_integer = struct.unpack("!I", packed_ip)[0]
        print(f"Integer representation (network byte order): {ip_integer}")
        # convert back to dotted decimal
        unpacked_ip = socket.inet_ntoa(packed_ip)
        print(f"Back to dotted decimal format: {unpacked_ip}")
    except socket.error:
        print("Invalid IPv4 address.")

def option_4():
    # Finding a service name, given the port and protocol
    try:
        port = int(input("Enter the port number (e.g., 80): ").strip())
        protocol = input("Enter the protocol (tcp or udp): ").strip().lower()
        if protocol not in ('tcp', 'udp'):
            print("Protocol must be 'tcp' or 'udp'.")
            return
        service = socket.getservbyport(port, protocol)
        print(f"Service running on port {port}/{protocol}: {service}")
    except OverflowError:
        print("Port number must be in range 0-65535.")
    except OSError:
        print("Service not found for given port/protocol.")
    except ValueError:
        print("Invalid input. Port must be an integer.")

def option_5():
    # Converting integers to and from host to network byte order
    try:
        num = int(input("Enter an integer (0 - 4294967295): ").strip())
        if not (0 <= num <= 0xFFFFFFFF):
            print("Integer out of range.")
            return
        print(f"Host to network byte order: {socket.htonl(num)}")
        print(f"Network to host byte order: {socket.ntohl(socket.htonl(num))}")
    except ValueError:
        print("Invalid integer input.")

def option_6():
    # Setting and getting the default socket timeout
    try:
        current_timeout = socket.getdefaulttimeout()
        print(f"Current default socket timeout: {current_timeout}")
        inp = input("Enter new timeout in seconds (or leave blank to keep current): ").strip()
        if inp == '':
            print("Timeout unchanged.")
        else:
            new_timeout = float(inp)
            socket.setdefaulttimeout(new_timeout)
            print(f"New default socket timeout set to: {new_timeout}")
    except ValueError:
        print("Invalid timeout value.")

def option_7():
    # Handling socket errors gracefully (demonstration)
    host = input("Enter a hostname or IP address to connect: ").strip()
    port_input = input("Enter a port number to connect: ").strip()
    try:
        port = int(port_input)
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        print(f"Trying to connect to {host}:{port} ...")
        s.connect((host, port))
        print("Connection succeeded!")
        s.close()
    except socket.gaierror:
        print("Address-related error connecting to server.")
    except socket.timeout:
        print("Connection timed out.")
    except ConnectionRefusedError:
        print("Connection refused by the server.")
    except Exception as e:
        print(f"Socket error occurred: {e}")

def option_8():
    # Modifying a socket's send/receive buffer size
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        print(f"Default send buffer size: {s.getsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF)}")
        print(f"Default receive buffer size: {s.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF)}")
        send_buf = int(input("Enter new send buffer size in bytes: ").strip())
        recv_buf = int(input("Enter new receive buffer size in bytes: ").strip())
        s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, send_buf)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, recv_buf)
        print(f"New send buffer size set to: {s.getsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF)}")
        print(f"New receive buffer size set to: {s.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF)}")
        s.close()
    except ValueError:
        print("Invalid buffer size input.")
    except Exception as e:
        print(f"Error modifying buffer sizes: {e}")

def option_9():
    # Changing a socket to the blocking/non-blocking mode
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        mode = input("Set socket mode: (b)locking or (n)on-blocking? ").strip().lower()
        if mode == 'b':
            s.setblocking(True)
            print("Socket set to blocking mode.")
        elif mode == 'n':
            s.setblocking(False)
            print("Socket set to non-blocking mode.")
        else:
            print("Invalid mode option.")
        s.close()
    except Exception as e:
        print(f"Error changing socket mode: {e}")

def option_10():
    # Reusing socket addresses
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        reuse = input("Set SO_REUSEADDR to True or False? (t/f): ").strip().lower()
        if reuse == 't':
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            print("SO_REUSEADDR set to True")
        elif reuse == 'f':
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 0)
            print("SO_REUSEADDR set to False")
        else:
            print("Invalid input.")
        current = s.getsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR)
        print(f"Current SO_REUSEADDR value: {current}")
        s.close()
    except Exception as e:
        print(f"Error setting SO_REUSEADDR: {e}")

def option_11():
    try:
        client = ntplib.NTPClient()

        response = client.request('time.google.com')

        current_time = ctime(response.tx_time)
        print("Current time from NTP server:", current_time)
        return current_time
    except Exception as e:
        return f"Error fetching time: {e}"
    
    

def main():
    while True:
        print_menu()
        choice = input("Enter your choice (0-11): ").strip()
        if choice == '1':
            option_1()
        elif choice == '2':
            option_2()
        elif choice == '3':
            option_3()
        elif choice == '4':
            option_4()
        elif choice == '5':
            option_5()
        elif choice == '6':
            option_6()
        elif choice == '7':
            option_7()
        elif choice == '8':
            option_8()
        elif choice == '9':
            option_9()
        elif choice == '10':
            option_10()
        elif choice == '11':
            option_11()
        elif choice == '0':
            print("Exiting the program.")
            break
        else:
            print("Invalid choice. Please enter a number between 0 and 11.")

if __name__ == "__main__":
    main()