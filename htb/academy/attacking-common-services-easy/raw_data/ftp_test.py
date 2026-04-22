from ftplib import FTP
import socket
socket.setdefaulttimeout(10)

print("[*] Connecting to FTP server...")
ftp = FTP('10.129.203.7')
ftp.login('fiona', '987654321')

print("[*] Trying passive mode...")
ftp.set_pasv(True)

try:
    print("\n=== Directory listing (passive) ===")
    files = ftp.nlst()
    for f in files:
        print(f"  {f}")
except Exception as e:
    print(f"[!] Passive mode failed: {e}")
    
    print("\n[*] Trying active mode...")
    ftp.set_pasv(False)
    
    try:
        print("\n=== Directory listing (active) ===")
        files = ftp.nlst()
        for f in files:
            print(f"  {f}")
    except Exception as e2:
        print(f"[!] Active mode failed: {e2}")

print("\n=== Current directory ===")
print(ftp.pwd())

ftp.quit()
print("\n[*] Done")
