# Spot Monitoring - SCADA Excavator Telemetry & GeoJSON Analyzer

Aplikasi web SCADA monitoring hasil galian excavator (Mode Spot & Mode Crumbling) dengan visualisasi GIS MapLibre, dashboard KPI 4-Quadrant QC, dan kustomisasi toleransi kedalaman.

## Fitur Utama

- **Mode Crumbling (Continuous Trenches)**:
  - Analisis geometri 3D LineString dari file telemetry GeoJSON (6.452+ segmen).
  - Skema warna 4-Quadrant QC (Ideal Pass, Overwidth, Depth Out of Spec, Fail Both).
  - Formula perhitungan luas area: $\text{Jarak Tempuh } (m) \times \text{Spacing } (4m) \to \text{m}^2 \to \text{Ha}$.
- **Mode Spot (Discrete Excavation Pits)**:
  - Monitoring lubang tanam diskrit dengan status Done, Pending, In-Progress.
- **GIS Map View**:
  - GPU Polyline rendering dengan 4 mode pewarnaan layer (4-Quadrant QC, Progress, Heatmap Kedalaman, Heatmap Deviasi).
  - Inspeksi segmen interaktif (klik segmen untuk melihat detail koordinat, kedalaman, lebar, dan deviasi).
- **Navigation & Theming**:
  - Responsive Side Menu navigasi modern.
  - Dukungan tema Dark SCADA dan Light Mode dengan toggle instan.
- **Konfigurasi & Toleransi**:
  - Penyesuaian target kedalaman dinamis (preset 70cm, 80cm, 90cm) dan batas toleransi (±10%).
  - Inspeksi data tabel segmen dan export ringkasan.

## Memulai

Jalankan perintah berikut untuk menjalankan aplikasi:

```bash
# Menjalankan di Chrome
flutter run -d chrome

# Menjalankan sebagai web server lokal (bisa diakses laptop lain di Wi-Fi yang sama)
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080

# Build release untuk web deployment
flutter build web --release
```
