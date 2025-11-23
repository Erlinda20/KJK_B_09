# ============================================================
# BAGIAN 5: PERMANENSI ROUTING & GATEWAY (VIA WEB GUI)
# ============================================================
# Note: Konfigurasi shell (route add) akan hilang saat reboot.
# Lakukan ini di Browser Firefox (http://10.20.100.1)

# 1. Buat Gateway Baru
# Menu: System > Routing > Gateways > Add
# ------------------------------------------------
# Gateway 1 (Arah Router Eksternal)
# Interface: LAN
# Name: GW_ROUTER_EKSTERNAL
# Gateway: 10.20.100.2
#
# Gateway 2 (Arah Router Internal)
# Interface: OPT1
# Name: GW_ROUTER_INTERNAL
# Gateway: 10.20.200.2

# 2. Masukkan Static Routes Permanen
# Menu: System > Routing > Static Routes > Add
# ------------------------------------------------
# Route Mahasiswa: 10.20.10.0/24 -> GW_ROUTER_EKSTERNAL
# Route Guest:     10.20.50.0/24 -> GW_ROUTER_EKSTERNAL
# Route Akademik:  10.20.20.0/24 -> GW_ROUTER_INTERNAL
# Route Riset:     10.20.30.0/24 -> GW_ROUTER_INTERNAL
# Route Admin:     10.20.40.0/24 -> GW_ROUTER_INTERNAL

# ============================================================
# BAGIAN 6: MANAGEMEN ALIAS (AGAR RULE RAPI)
# ============================================================
# Menu: Firewall > Aliases > IP > Add
# Buat daftar berikut agar rule firewall mudah dibaca.

# Alias: Net_Mahasiswa  -> 10.20.10.0/24
# Alias: Net_Guest      -> 10.20.50.0/24
# Alias: Net_Akademik   -> 10.20.20.0/24
# Alias: Net_Riset      -> 10.20.30.0/24
# Alias: Net_Admin      -> 10.20.40.0/24
# Alias: Net_Kampus_All -> 10.20.0.0/16

# ============================================================
# BAGIAN 7: KEBIJAKAN FIREWALL FINAL (ACL)
# ============================================================
# Prinsip: Block Dulu, Baru Allow (Urutan dari Atas ke Bawah)

# --- A. Interface LAN (Mahasiswa & Guest) ---
# Menu: Firewall > Rules > LAN
# Hapus rule default, buat urutan baru:

# 1. Anti-Lockout (PENTING: Agar tetap bisa akses Web pfSense)
#    Action: Pass | Proto: TCP | Src: Net_Mahasiswa | Dst: LAN Address (Port 80/443)

# 2. Isolasi Guest (Guest cuma boleh internet)
#    Action: Block | Src: Net_Guest | Dst: Net_Kampus_All

# 3. Blokir Mahasiswa ke Zona Sensitif
#    Action: Block | Src: Net_Mahasiswa | Dst: Net_Admin
#    Action: Block | Src: Net_Mahasiswa | Dst: Net_Riset

# 4. Izinkan Sisa Trafik (Internet & Akademik)
#    Action: Pass | Src: Any | Dst: Any

# --- B. Interface OPT1 (Internal: Admin, Riset, Akad) ---
# Menu: Firewall > Rules > OPT1

# 1. Admin God-Mode (Bebas Akses Kemana Saja)
#    Action: Pass | Src: Net_Admin | Dst: Any

# 2. Lindungi Admin dari Tetangga (Riset/Akad gak boleh ke Admin)
#    Action: Block | Src: Any | Dst: Net_Admin

# 3. Izinkan Riset & Akademik ke Internet
#    Action: Pass | Src: Any | Dst: Any

# *JANGAN LUPA KLIK "APPLY CHANGES"*

# ============================================================
# BAGIAN 8: VERIFIKASI AKHIR (BUKTI KERJA)
# ============================================================

# 1. Test Pertahanan Admin (Defense in Depth)
# Dari Firefox (Mhs) -> Ping 10.20.40.5 (Admin)
# HASIL HARUS: Request Timed Out (Diblokir Firewall)

# 2. Test Akses Sah
# Dari Firefox (Mhs) -> Ping 10.20.20.5 (Akademik)
# HASIL HARUS: Reply (Diizinkan Rule allow sisa trafik)

# 3. Test Isolasi Total
# Dari VPCS Guest -> Ping 10.20.20.5 (Akademik)
# HASIL HARUS: Request Timed Out (Diblokir Rule Guest Isolation)

# 4. Test Routing Balik
# Dari VPCS Admin -> Ping 10.20.10.5 (Mahasiswa)
# HASIL HARUS: Reply (Karena Admin punya akses Pass Any)