# Windows Battery Widget

Widget baterai ringan untuk Windows yang menampilkan ikon dan persentase baterai pada desktop. Widget dibuat menggunakan PowerShell dan Windows Forms, tanpa perlu memasang aplikasi tambahan.

## Fitur

- Menampilkan ikon baterai dan persentase daya.
- Memperbarui informasi baterai secara berkala.
- Warna indikator berubah sesuai kondisi pengisian daya dan level baterai.
- Dapat dipindahkan dengan menyeret widget menggunakan mouse.
- Menu klik kanan menyediakan opsi untuk keluar.
- Dapat dijalankan otomatis saat pengguna masuk ke Windows.

> **Catatan:** Widget ini ditujukan untuk perangkat Windows yang memiliki baterai, seperti laptop. Tampilan dapat berbeda bergantung pada versi Windows dan konfigurasi perangkat.

## 1. Struktur repository

Simpan file repository dengan struktur berikut:

```text
windows-battery-widget/
├── BatteryTray.ps1
├── BatteryIcon.ico
├── README.md
└── LICENSE
```

Keterangan:

- `BatteryTray.ps1`: skrip utama untuk menjalankan widget.
- `BatteryIcon.ico`: ikon untuk shortcut widget. Jika skrip yang digunakan tidak memerlukan ikon ini, file tersebut hanya diperlukan untuk shortcut.
- `README.md`: panduan ini.
- `LICENSE`: lisensi proyek, misalnya MIT jika kamu memilih untuk merilis proyek dengan lisensi MIT.

Pastikan `BatteryTray.ps1` dan `BatteryIcon.ico` benar-benar tersedia di repository sebelum pengguna mengikuti langkah instalasi. Jika nama file berbeda, sesuaikan perintah dan langkah di bawah.

## 2. Mengunduh file dari GitHub

Ada dua cara:

### Opsi A: Unduh repository sebagai ZIP

1. Buka halaman repository GitHub.
2. Klik tombol **Code**.
3. Pilih **Download ZIP**.
4. Ekstrak ZIP ke folder yang mudah ditemukan, misalnya `Downloads\windows-battery-widget`.

### Opsi B: Unduh file satu per satu

Buka file `BatteryTray.ps1` dan `BatteryIcon.ico` pada repository, lalu unduh masing-masing file menggunakan tombol **Download raw file** atau opsi unduh yang tersedia di GitHub.

## 3. Memasang skrip ke folder Startup Windows

Dengan cara ini, widget dapat dijalankan otomatis saat pengguna masuk ke Windows.

### Langkah 1: Buka folder Startup

1. Tekan `Win + R` pada keyboard.
2. Ketik:

   ```text
   shell:startup
   ```

3. Tekan `Enter`.

Windows akan membuka folder Startup untuk akun pengguna yang sedang digunakan. Umumnya folder ini berada di:

```text
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
```

### Langkah 2: Salin file skrip

Salin `BatteryTray.ps1` dari folder hasil ekstraksi ke folder Startup yang baru dibuka.

Contoh lokasi akhirnya:

```text
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\BatteryTray.ps1
```

Jika ingin menggunakan ikon khusus, salin `BatteryIcon.ico` ke folder yang sama. Ikon ini tidak harus berada di folder Startup untuk menjalankan skrip, tetapi menyimpannya di sana memudahkan pengelolaan shortcut.

> **Penting:** Pastikan file tidak bernama `BatteryTray.ps1.txt`. Di File Explorer, aktifkan **View → Show → File name extensions** agar ekstensi file terlihat.

## 4. Membuat shortcut agar widget berjalan otomatis

1. Buka folder Startup dengan `Win + R` → `shell:startup`.
2. Klik kanan area kosong, lalu pilih **New → Shortcut**.
3. Pada kolom lokasi item, masukkan perintah berikut:

   ```text
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\BatteryTray.ps1"
   ```

4. Klik **Next**.
5. Beri nama shortcut, misalnya `Battery Widget`.
6. Klik **Finish**.

Shortcut `Battery Widget` sekarang berada di folder Startup. Saat masuk ke Windows, Windows akan menjalankan shortcut tersebut.

Jika jendela PowerShell tetap muncul, hapus opsi `-WindowStyle Hidden` dari perintah shortcut untuk membantu melihat pesan kesalahan. Perilaku jendela juga dapat bergantung pada cara skrip dibuat.

### Opsional: Mengatur ikon shortcut

1. Klik kanan shortcut `Battery Widget`, lalu pilih **Properties**.
2. Klik **Change Icon...**.
3. Klik **Browse...** dan pilih `BatteryIcon.ico`.
4. Klik **OK**, lalu **Apply**.

Jika ikon disimpan di folder Startup, jangan pindahkan file ikon setelah mengaturnya karena shortcut dapat kehilangan referensi ikon.

## 5. Menjalankan widget sekarang

Setelah shortcut dibuat, jalankan widget dengan salah satu cara berikut:

- Klik dua kali shortcut `Battery Widget` di folder Startup.
- Atau buka PowerShell dan jalankan:

  ```powershell
  & "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\BatteryTray.ps1"
  ```

Jika skrip disimpan di lokasi lain, sesuaikan path dengan lokasi file sebenarnya.

## 6. Menghentikan widget

Jika skrip menyediakan menu keluar, klik kanan widget lalu pilih **Keluar**. Jika widget tidak merespons:

1. Tekan `Ctrl + Shift + Esc` untuk membuka Task Manager.
2. Cari proses PowerShell yang menjalankan widget.
3. Akhiri proses yang sesuai.

Mengakhiri proses PowerShell akan menutup widget yang dijalankan oleh proses tersebut. Shortcut di folder Startup tetap ada, sehingga widget dapat berjalan lagi pada login Windows berikutnya.

## 7. Pemecahan masalah

### Widget tidak muncul

1. Pastikan `BatteryTray.ps1` ada di lokasi yang benar.
2. Jalankan skrip secara manual dari PowerShell agar pesan kesalahan terlihat:

   ```powershell
   & "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\BatteryTray.ps1"
   ```

3. Jika muncul pesan kesalahan, salin pesan tersebut untuk diperiksa.
4. Pastikan perangkat memiliki baterai dan Windows dapat membaca status baterainya.

### Muncul pesan bahwa skrip tidak dapat dijalankan

Shortcut di panduan ini menggunakan `-ExecutionPolicy Bypass` hanya untuk proses PowerShell yang dijalankan melalui shortcut tersebut. Jika organisasi atau administrator perangkat menerapkan kebijakan yang lebih ketat, kebijakan tersebut dapat tetap membatasi eksekusi.

Jangan mengubah kebijakan keamanan seluruh sistem hanya untuk menjalankan widget. Periksa isi skrip terlebih dahulu dan jalankan hanya skrip yang kamu percayai.

### Widget berjalan lebih dari satu kali

Pastikan hanya ada satu shortcut yang menjalankan `BatteryTray.ps1` di folder Startup dan tidak ada salinan skrip lain yang dijalankan melalui shortcut berbeda. Tutup proses widget yang duplikat, lalu jalankan satu kali.

### Widget tidak berjalan setelah file dipindahkan

Periksa target shortcut. Jika skrip atau file ikon dipindahkan, perbarui path yang digunakan shortcut.

## 8. Keamanan

Skrip PowerShell dapat menjalankan perintah pada komputer. Sebelum menjalankan proyek dari internet:

- Baca `BatteryTray.ps1` terlebih dahulu.
- Pastikan file berasal dari repository yang kamu percayai.
- Jangan menjalankan skrip yang tidak kamu pahami pada komputer penting atau komputer kantor yang dikelola organisasi.
- `-ExecutionPolicy Bypass` pada shortcut ini tidak mengubah kebijakan eksekusi secara permanen, tetapi tetap memungkinkan skrip tersebut berjalan dalam proses yang dipanggil oleh shortcut.

## 9. Menghapus widget

1. Tutup widget.
2. Tekan `Win + R`, ketik `shell:startup`, lalu tekan `Enter`.
3. Hapus shortcut `Battery Widget` agar widget tidak otomatis dijalankan saat login berikutnya.
4. Hapus `BatteryTray.ps1` dan `BatteryIcon.ico` dari folder Startup jika tidak lagi diperlukan.

Langkah ini hanya menghapus salinan di folder Startup. Jika kamu menyimpan salinan lain di folder unduhan atau repository lokal, hapus secara terpisah jika memang tidak diperlukan.

## Kontribusi

Saran perbaikan, laporan bug, dan kontribusi kode dipersilakan melalui **Issues** atau **Pull Requests** pada repository ini.

## Lisensi

Tambahkan file `LICENSE` dan nyatakan lisensi yang kamu pilih sebelum mengizinkan orang lain menggunakan, mengubah, atau mendistribusikan proyek. Jika memilih MIT, gunakan teks lisensi MIT yang sesuai dan cantumkan nama pemegang hak cipta serta tahun yang benar.
