import ipaddress

def convert_ipv4_address(ip_str):
    ip = ipaddress.IPv4Address(ip_str)

    binary_format = bin(int(ip))[2:]  
    hex_format = hex(int(ip))[2:]      
    integer_format = int(ip)            

    return {
        'binary': binary_format,
        'hexadecimal': hex_format,
        'integer': integer_format
    }

ipv4_address = '192.168.1.1'
converted_formats = convert_ipv4_address(ipv4_address)

print(f"IPv4 Address: {ipv4_address}")
print(f"Binary Format: {converted_formats['binary']}")
print(f"Hexadecimal Format: {converted_formats['hexadecimal']}")
print(f"Integer Format: {converted_formats['integer']}")
print("Performed by: John Rave O. Camarines | BSIT 3D")

if __name__ == '__main__':
    convert_ipv4_address
