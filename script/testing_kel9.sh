#!/bin/bash
# =========================================================
# SCRIPT PENGUJIAN KEAMANAN JARINGAN (CLIENT SIDE)
# Dijalankan di: Node Firefox / Linux (Mahasiswa)
# =========================================================

# --- 1. SETUP IP ADDRESS (Auto-Config) ---
echo "-----------------------------------------------------"
echo "[INIT] Mengonfigurasi Network Interface..."
echo "-----------------------------------------------------"
# Pastikan IP tidak hilang saat restart GNS3
ifconfig eth0 10.20.10.5 netmask 255.255.255.0 up
route add default gw 10.20.10.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Cek Gateway
ping -c 1 -W 1 10.20.10.1 > /dev/null
if [ $? -eq 0 ]; then
    echo "[OK] Koneksi ke Gateway (Router Eksternal) AMAN."
else
    echo "[ERROR] Gateway tidak terjangkau! Cek kabel/Switch."
    exit 1
fi

echo ""
echo "-----------------------------------------------------"
echo "MULAI PENGUJIAN ACL FIREWALL (Sesuai Soal)"
echo "-----------------------------------------------------"

# --- 2. TEST CASE A: AKSES SAH (Mahasiswa -> Akademik) ---
# Ekspektasi: REPLY (Sukses)
TARGET_AKAD="10.20.20.5"
echo -n "Tes 1: Akses ke AKADEMIK ($TARGET_AKAD) ... "

ping -c 2 -W 2 $TARGET_AKAD > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "\e[32m[PASSED] SUKSES (Diizinkan)\e[0m"
else
    echo -e "\e[31m[FAILED] GAGAL (Seharusnya BISA)\e[0m"
fi

# --- 3. TEST CASE B: AKSES ILEGAL (Mahasiswa -> Riset) ---
# Ekspektasi: TIMEOUT (Diblokir)
TARGET_RISET="10.20.30.5"
echo -n "Tes 2: Akses ke RISET ($TARGET_RISET) ...... "

ping -c 2 -W 2 $TARGET_RISET > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "\e[32m[PASSED] DIBLOKIR (Sesuai Aturan)\e[0m"
else
    echo -e "\e[31m[FAILED] TEMBUS! (Firewall Bocor)\e[0m"
fi

# --- 4. TEST CASE C: AKSES ILEGAL (Mahasiswa -> Admin) ---
# Ekspektasi: TIMEOUT (Diblokir)
TARGET_ADMIN="10.20.40.5"
echo -n "Tes 3: Akses ke ADMIN ($TARGET_ADMIN) ...... "

ping -c 2 -W 2 $TARGET_ADMIN > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "\e[32m[PASSED] DIBLOKIR (Sesuai Aturan)\e[0m"
else
    echo -e "\e[31m[FAILED] TEMBUS! (Firewall Bocor)\e[0m"
fi

echo ""
echo "-----------------------------------------------------"
echo "PENGUJIAN SELESAI."
echo "-----------------------------------------------------"