import ntplib
from time import ctime

def get_current_time():
    try:
        client = ntplib.NTPClient()

        response = client.request('time.google.com')

        current_time = ctime(response.tx_time)
        return current_time
    except Exception as e:
        return f"Error fetching time: {e}"
    
    
def main():
    current_time = get_current_time()
    print("Current time from NTP server:", current_time)
    print("Performed by: John Rave O. Camarines | BSIT 3D")
    
if __name__ == '__main__':
    main()