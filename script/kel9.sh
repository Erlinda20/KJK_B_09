#!/bin/bash
# ============================================================
# DOKUMENTASI KONFIGURASI KEAMANAN JARINGAN KAMPUS (GNS3)
# Topologi: Edge -> pfSense -> (R.Eksternal & R.Internal)
# ============================================================

# ============================================================
# BAGIAN 1: KONFIGURASI ROUTER CISCO (INFRASTRUKTUR FISIK)
# ============================================================

# --- 1. Edge Router (Gateway Internet) ---
# Aksi: Buka Console EdgeRouter
enable
configure terminal
! Interface ke Internet (NAT GNS3)
interface Ethernet0/0
 description Link-to-Internet
 ip address dhcp
 no shutdown
! Interface ke pfSense (WAN)
interface FastEthernet1/0
 description Link-to-pfSense-WAN
 ip address 10.20.254.1 255.255.255.252
 no shutdown
exit
! Routing
ip route 0.0.0.0 0.0.0.0 Ethernet0/0
end
write

# --- 2. Router Eksternal (Mahasiswa & Guest) ---
# Aksi: Buka Console RouterEksternal
enable
configure terminal
! Interface ke pfSense (LAN Port pfSense) - SUBNET 100
interface Ethernet0/0
 description Uplink-to-pfSense
 ip address 10.20.100.2 255.255.255.252
 no shutdown
! Interface Gateway Mahasiswa (PORT YANG BENAR)
interface Ethernet1/0
 description Gateway-Mahasiswa
 ip address 10.20.10.1 255.255.255.0
 no shutdown
! Interface Gateway Guest
interface Ethernet1/1
 description Gateway-Guest
 ip address 10.20.50.1 255.255.255.0
 no shutdown
exit
! Routing Default ke pfSense
ip route 0.0.0.0 0.0.0.0 10.20.100.1
! Pastikan NAT dimatikan (Pure Routing)
interface Ethernet0/0
 no ip nat outside
interface Ethernet1/0
 no ip nat inside
end
write

# --- 3. Router Internal (Admin, Riset, Akademik) ---
# Aksi: Buka Console RouterInternal
enable
configure terminal
! Interface ke pfSense (OPT1 Port pfSense) - SUBNET 200
interface Ethernet0/0
 description Uplink-to-pfSense
 ip address 10.20.200.2 255.255.255.252
 no shutdown
! Interface Gateway Akademik
interface Ethernet1/0
 description Gateway-Akademik
 ip address 10.20.20.1 255.255.255.0
 no shutdown
! Interface Gateway Admin
interface Ethernet1/1
 description Gateway-Admin
 ip address 10.20.40.1 255.255.255.0
 no shutdown
! Interface Gateway Riset
interface Ethernet1/2
 description Gateway-Riset
 ip address 10.20.30.1 255.255.255.0
 no shutdown
exit
! Routing Default ke pfSense
ip route 0.0.0.0 0.0.0.0 10.20.200.1
end
write

# ============================================================
# BAGIAN 2: KONFIGURASI PFSENSE (OTAK KEAMANAN)
# ============================================================

# --- 1. Assign Interfaces (Mapping Kabel) ---
# Aksi: Console pfSense -> Menu 1 (Assign Interfaces)
# Masalah "Salah Lobang" diselesaikan di sini.
# WAN  -> em1 (Arah Edge)
# LAN  -> em3 (Arah Router Eksternal) - PENTING!
# OPT1 -> em2 (Arah Router Internal)

# --- 2. Set IP Address ---
# Aksi: Console pfSense -> Menu 2 (Set IP)
# WAN (em1)  : 10.20.254.2 / 30 -> Gateway: 10.20.254.1
# LAN (em3)  : 10.20.100.1 / 30 -> Gateway: ENTER (KOSONG)
# OPT1 (em2) : 10.20.200.1 / 30 -> Gateway: ENTER (KOSONG)

# --- 3. Routing Static (Supaya Kenal Subnet Klien) ---
# Aksi: Console pfSense -> Menu 8 (Shell) - Manual Inject
# (Dilakukan karena Web GUI belum bisa diakses dari jauh)

# Hapus rute lama jika salah
route delete -net 10.20.10.0/24

# Tambah Rute ke Zona Eksternal (Mhs, Guest) -> Via Router Ekst
route add -net 10.20.10.0/24 10.20.100.2
route add -net 10.20.50.0/24 10.20.100.2

# Tambah Rute ke Zona Internal (Admin, Akad, Riset) -> Via Router Int
route add -net 10.20.40.0/24 10.20.200.2
route add -net 10.20.30.0/24 10.20.200.2
route add -net 10.20.20.0/24 10.20.200.2

# --- 4. Bypass Firewall (Untuk Setup Awal) ---
# Aksi: Console pfSense -> Menu 8 (Shell)
pfctl -d
# (Sekarang akses Web GUI http://10.20.100.1 sudah terbuka)

# ============================================================
# BAGIAN 3: KONFIGURASI KLIEN (TARGET UJI COBA)
# ============================================================

# --- 1. Firefox (Mahasiswa) ---
# Aksi: Buka Console / Terminal di Desktop Firefox
# (Harus diulang setiap kali restart GNS3 karena sifatnya VM)
sudo ifconfig eth0 10.20.10.5 netmask 255.255.255.0 up
sudo route add default gw 10.20.10.1
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# --- 2. VPCS Guest ---
# Aksi: Buka Console VPCS
ip 10.20.50.5 255.255.255.0 10.20.50.1
save

# --- 3. VPCS Admin ---
# Aksi: Buka Console VPCS
ip 10.20.40.5 255.255.255.0 10.20.40.1
save

# ============================================================
# BAGIAN 4: SKENARIO PENGUJIAN (BUKTI LAPORAN)
# ============================================================

# -----------------------------------------------------------
# SKENARIO 1: UJI KONEKTIVITAS DASAR (PING TEST)
# Tujuan: Membuktikan Routing Table pfSense & Router bekerja.
# -----------------------------------------------------------

# Tes 1: Mahasiswa ke Gateway Sendiri
# Di Terminal Firefox:
ping 10.20.10.1
# Hasil: REPLY (Kabel Lokal Aman)

# Tes 2: Mahasiswa ke pfSense (Core)
# Di Terminal Firefox:
ping 10.20.100.1
# Hasil: REPLY (Routing Router Eksternal -> pfSense Aman)

# Tes 3: Mahasiswa ke Admin (Lintas Router)
# Di Terminal Firefox:
ping 10.20.40.5
# Hasil: REPLY (pfSense berhasil routing dari LAN ke OPT1)

# -----------------------------------------------------------
# SKENARIO 2: PENERAPAN KEAMANAN (FIREWALL RULES)
# Tujuan: Memblokir akses Mahasiswa ke Admin.
# -----------------------------------------------------------

# Aksi: Masuk Web GUI pfSense (http://10.20.100.1) -> Firewall -> Rules -> LAN
# Buat Rule Paling Atas:
# Action: Block
# Protocol: Any
# Source: Network 10.20.10.0/24
# Destination: Network 10.20.40.0/24
# Apply Changes.

# Verifikasi:
# Di Terminal Firefox:
ping 10.20.40.5
# Hasil: Request Timed Out / Destination Unreachable. (SUKSES DIBLOKIR)

# -----------------------------------------------------------
# SKENARIO 3: GUEST ISOLATION
# Tujuan: Guest cuma boleh internet, tidak boleh ke jaringan lokal.
# -----------------------------------------------------------

# Aksi: Web GUI pfSense -> Firewall -> Rules -> LAN
# Buat Rule untuk Guest:
# Action: Block
# Source: Network 10.20.50.0/24
# Destination: Network 10.20.0.0/16 (Seluruh Kampus)
# Apply Changes.

# Verifikasi:
# Di VPCS Guest:
ping 10.20.40.5 (Admin) -> GAGAL
ping 8.8.8.8 (Internet) -> SUKSES (Jika NAT pfSense WAN sudah aktif)