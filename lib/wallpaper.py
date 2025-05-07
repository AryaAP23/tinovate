# from datetime import datetime
# import locale

# locale.setlocale(locale.LC_TIME, 'id_ID.UTF-8')
# sekarang = datetime.now()

# tanggal_waktu = sekarang.strftime("%A, %d-%m-%Y %H:%M:%S")
# print("Waktu saat ini:", tanggal_waktu)

# import psycopg2

# try:
#     koneksi = psycopg2.connect(
#         dbname="local",
#         user="postgres",
#         password="passwordmu",
#         host="localhost",
#         port="5432"
#     )
    
#     cursor = koneksi.cursor()
    
#     cursor.execute("SELECT * FROM profil")
#     data = cursor.fetchone()  # Hanya ambil satu baris

#     # Misalnya kolom: nama, email, umur
#     nama, email, umur = data
#     print(f"Nama: {nama}")
#     print(f"Email: {email}")
#     print(f"Umur: {umur}")

# except Exception as e:
#     print("Terjadi kesalahan:", e)

# finally:
#     if koneksi:
#         cursor.close()
#         koneksi.close()

# fake_music_visualizer.py
import time
import os
import random

bars = [
    "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"
]

def generate_bar():
    return random.choice(bars)

def draw_fake_visualizer():
    os.system('cls' if os.name == 'nt' else 'clear')
    print("Now Playing: Lofi Beats\n")
    for _ in range(10):  # number of bars
        bar = "".join(generate_bar() for _ in range(40))  # line length
        print(bar)
    print("\nPress Ctrl+C to exit.")

try:
    while True:
        draw_fake_visualizer()
        time.sleep(0.3)
except KeyboardInterrupt:
    print("\nVisualizer stopped.")
