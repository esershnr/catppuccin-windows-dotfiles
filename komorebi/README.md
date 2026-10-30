# Komorebi Yapılandırma Rehberi

Bu dizin, Windows için kiremit döşemeli pencere yöneticisi (tiling window manager) olan **Komorebi**'nin yapılandırma ayarlarını ve yedekleme bilgilerini içerir.

## 📂 Dosya Yapısı ve Konumları

Komorebi'nin düzgün çalışması için yapılandırma dosyalarının aşağıdaki konumlarda bulunması gerekir:

*   **Ana Yapılandırma Dosyası (`komorebi.json`):**
    *   **Konum:** `$Env:USERPROFILE\komorebi.json`
    *   Bu dosya ekran bölme kurallarını, çalışma alanlarını (workspaces), kenarlıkları (borders) ve animasyonları tanımlar.

*   **Uygulamaya Özel Ayarlar (`applications.json`):**
    *   **Konum:** `$Env:USERPROFILE\applications.json`
    *   Bu dosya tarayıcılar, Discord, Spotify vb. uygulamaların döşeme dışı bırakılması (floating) veya otomatik yönetilmesi için kuralları içerir.
    *   ⚠️ **ÖNEMLİ:** `komorebi.json` dosyasında `"app_specific_configuration_path"` parametresi etkin olduğu sürece, bu dosyanın belirtilen konumda bulunması **zorunludur**. Aksi takdirde Komorebi açılışta hata vererek kapanacaktır (çökecektir).

---

## 🚀 Sık Kullanılan Komutlar

Komorebi'yi yönetmek için terminalde (PowerShell) aşağıdaki komutları kullanabilirsiniz:

### 1. Komorebi'yi Başlatma ve Durdurma
*   **Başlat:** `komorebic start`
*   **Durdur:** `komorebic stop`

### 2. Yapılandırmayı Yenileme (Reload)
Yapılandırma dosyasında (`komorebi.json`) bir değişiklik yaptıktan sonra Komorebi'yi yeniden başlatmak yerine ayarları anında uygulamak için:
```powershell
komorebic reload-configuration
```

### 3. Hazır Uygulama Kurallarını İndirme (Fetch Rules)
Topluluk tarafından hazırlanan güncel ve popüler uygulama kurallarını doğrudan `applications.json` dosyanıza indirmek için:
```powershell
komorebic fetch-app-specific-configuration
```

---

## 🎨 Tema ve Sınır (Border) Notları
*   `komorebi.json` dosyasında bir `"theme"` (örneğin Catppuccin Mocha) tanımlıysa, yazdığınız manuel `"border_colours"` (sınır renkleri) ayarları etkisiz kalacaktır.
*   Kendi özel renk kodlarınızı kullanmak istiyorsanız yapılandırma dosyasındaki `"theme"` bloğunu kaldırarak veya yorum satırına alarak sınırları özelleştirebilirsiniz.

---

## ⌨️ Klavye Kısayolları (Senbonzakura / komorebi.sbz)

`komorebi.sbz` dosyasında tanımlı olan aktif kısayollar aşağıda listelenmiştir:

| Kısayol | İşlem | Açıklama |
| :--- | :--- | :--- |
| **Pencere Odaklama (Focus)** | | |
| `Alt + H` veya `Alt + Sol Ok` | `focus left` | Soldaki pencereye odaklanır |
| `Alt + J` veya `Alt + Aşağı Ok` | `focus down` | Aşağıdaki pencereye odaklanır |
| `Alt + K` veya `Alt + Yukarı Ok` | `focus up` | Yukarıdaki pencereye odaklanır |
| `Alt + L` veya `Alt + Sağ Ok` | `focus right` | Sağdaki pencereye odaklanır |
| **Pencere Taşıma (Move)** | | |
| `Alt + Shift + H` veya `Alt + Shift + Sol Ok` | `move left` | Aktif pencereyi sola taşır |
| `Alt + Shift + J` veya `Alt + Shift + Aşağı Ok` | `move down` | Aktif pencereyi aşağı taşır |
| `Alt + Shift + K` veya `Alt + Shift + Yukarı Ok` | `move up` | Aktif pencereyi yukarı taşır |
| `Alt + Shift + L` veya `Alt + Shift + Sağ Ok` | `move right` | Aktif pencereyi sağa taşır |
| **Pencere Yığınlama (Stacking)** | | |
| `Alt + Ctrl + H` | `stack left` | Aktif pencereyi soldakiyle yığınlar (stack) |
| `Alt + Ctrl + J` | `stack down` | Aktif pencereyi aşağıdakiyle yığınlar (stack) |
| `Alt + Ctrl + K` | `stack up` | Aktif pencereyi yukarıdakiyle yığınlar (stack) |
| `Alt + Ctrl + L` | `stack right` | Aktif pencereyi sağdakiyle yığınlar (stack) |
| `Alt + [` | `cycle-stack prev` | Yığındaki bir önceki pencereye geçer |
| `Alt + ]` | `cycle-stack next` | Yığındaki bir sonraki pencereye geçer |
| `Alt + Shift + U` | `unstack` | Yığındaki aktif pencereyi yığından çıkarır |
| **Düzen ve Görünüm Kontrolleri** | | |
| `Alt + F` | `toggle-float` | Pencereyi serbest/yüzen (float) moda geçirir veya döşemeye dahil eder |
| `Alt + M` | `toggle-monocle` | Monocle modunu açar/kapatır (aktif pencereyi tam ekran yapar) |
| `Alt + P` | `toggle-maximize` | Pencereyi maksimum boyuta getirir (sınırları korur) |
| **Çalışma Alanı (Workspace) İşlemleri** | | |
| `Alt + 1..9` | `focus-workspace 0..8` | 1'den 9'a kadar olan çalışma alanlarına geçiş yapar |
| `Alt + Shift + 1..9` | `move-to-workspace 0..8` | Aktif pencereyi belirtilen çalışma alanına taşır |
| **Yönetici Kontrolleri** | | |
| `Alt + R` | `reload-configuration` | Komorebi yapılandırmasını yeniler |
| `Alt + S` | `start` | Komorebi servisini başlatır |
| `Alt + Q` | `stop` | Komorebi servisini durdurur |

