# OpenRGB — açılışta renk profili + uykuda söndürme

ASUS **Armoury Crate** kaldırıldı (arka planda servis / boş işlem istemiyor), yerine
[OpenRGB](https://openrgb.org/). Armoury Crate'in bedavaya yaptığı iki şeyi OpenRGB'de
elle kurmak gerekiyor:

1. **Güç döngüsünden sonra rengi koruma.** Cold boot'ta anakart / Aura DDR4 firmware'i
   fabrika **Rainbow** efektine döner, profili her açılışta yeniden uygulamak gerekir →
   **zamanlanmış görev** (`install.ps1`).
2. **Uykuda ışıkları söndürme.** DIMM slotları S3'te self-refresh için beslenmeye devam
   eder ve ENE DRAM denetleyicisi son rengi tutar, yani bir şey açıkça siyah basmazsa
   RAM RGB'si uykuda **yanık kalır**. Çözüm: OpenRGB'nin **suspend/resume autoload**
   profilleri — uykuda `OFF`, uyanışta `Green`.

## Donanım (DESKTOP-T0D7LKC)

32 GB'a çıkarken 2× Corsair Vengeance RGB PRO (CMR16GX4M2C3200C16) eklendi, mevcut
2× Thermaltake ToughRAM (R009D408GX2-3200C16A) yerinde kaldı — dördü de RGB, dördü de
OpenRGB'de ayrı denetleyici olarak görünüyor:

| Denetleyici | Ne |
| --- | --- |
| `ASUS PRIME B550M-A` | anakart onboard (HID) |
| `ENE DRAM` ×2 | Thermaltake ToughRAM, SMBus `0x72` / `0x73` (PawnIO) |
| `Corsair Vengeance RGB` ×2 | Corsair Vengeance RGB PRO, SMBus `0x58` / `0x59` |
| `NVIDIA RTX 3060 Ti` | GPU |

## İçindekiler

| Dosya | Ne |
| --- | --- |
| `Green.orp` | Ana renk profili (yeşil statik). Logon'da ve uyanışta uygulanır. Kopyalanacağı yer: `%APPDATA%\OpenRGB\Green.orp` |
| `OFF.orp` | Tüm cihazlar siyah (Direct, `000000`). Uykuya girerken uygulanır → ışıklar söner. Kopyalanacağı yer: `%APPDATA%\OpenRGB\OFF.orp` |
| `OpenRGB.json` | OpenRGB'nin tam ayar dosyası (bu makinedeki hali). İlgili anahtarlar aşağıda. `%APPDATA%\OpenRGB\OpenRGB.json` |
| `install.ps1` | `"OpenRGB Green Profile"` zamanlanmış görevini kurar (logon + gecikme, yükseltilmiş), iki profili `%APPDATA%` içine kopyalar ve `OpenRGB.json` içindeki suspend/resume anahtarlarını yazar. Kendini elevate eder (bir UAC). |

### `OpenRGB.json` içindeki kritik anahtarlar

```jsonc
"AutoStart": { "enabled": false },          // kendi "Start At Login"'i kapalı (görevle çakışmasın)
"Drivers":   { "smbus_sleep_mode": 2 },     // SMBus'ı uyku boyunca canlı tut (resume'da renk hızlı gelsin)
"UserInterface": {
  "minimize_on_close": true,                // X ile kapatınca tray'de kalır (power event'leri yakalar)
  "autoload_profiles": {
    "suspend_profile": { "enabled": true,  "name": "OFF"   },
    "resume_profile":  { "enabled": true,  "name": "Green" },
    "exit_profile":    { "enabled": false, "name": "Green" }
  }
}
```

## Neden zamanlanmış görev, OpenRGB'nin kendi "Start At Login"'i değil

OpenRGB'nin dahili "Start At Login" seçeneği Startup klasörüne düz bir kısayol koyar,
o da **yükseltilmemiş** çalışır. Aura DDR4 modüllerini SMBus / PawnIO üzerinden sürmek
için bu yetmiyor — yükseltilmemiş başlatma `0x800702E4` (`ELEVATION_REQUIRED`) döndürüyor
ve RAM Rainbow'da kalıyor. Zamanlanmış görev **RunLevel Highest** ile kayıtlı, yani
OpenRGB logon'dan birkaç saniye sonra **sessizce yükseltilmiş** başlıyor (UAC istemi yok).

Suspend/resume profilleri o **tray'de kalan** örneğe bağlı: `minimize_on_close: true`
olduğu için X'e basınca kapanmaz, Windows'un power broadcast mesajlarını yakalar ve
uykuya girerken `OFF`, uyanınca `Green` uygular.

## Kurulum

1. OpenRGB'yi kur (bu makinede portable: `C:\Tools\Apps\OpenRGB\`).
2. Bir kez aç. Kendi profillerin yoksa `Green` ve `OFF`'u OpenRGB içinde oluştur
   (`OFF` = tüm cihazlar Direct + `000000`), ya da `.orp` dosyalarını `%APPDATA%\OpenRGB\`
   içine kopyala (script de yapıyor). Profil listesinde ikisi de görünmeli.
3. Scripti çalıştır:
   ```powershell
   .\install.ps1                       # varsayılan: logon +5 sn, resume=Green, suspend=OFF
   .\install.ps1 -DelaySeconds 12
   .\install.ps1 -ResumeProfile "Green" -SuspendProfile "OFF"
   ```
   OpenRGB başka yoldaysa: `.\install.ps1 -OpenRGBExe "D:\path\OpenRGB.exe"`
4. **Elle tek adım:** OpenRGB → Settings → **"Start At Login" işaretini KALDIR**
   (veya `%APPDATA%\OpenRGB\OpenRGB.json` içinde `AutoStart.enabled = false`). Yoksa
   OpenRGB kısayolu tekrar yaratır ve açılışta ikisi birden tetiklenir.
5. **OpenRGB'yi bir kez yeniden başlat** ki yeni `OpenRGB.json`'u okusun.
6. Test:
   - Logon: `Start-ScheduledTask -TaskName "OpenRGB Green Profile"`
   - Uyku: PC'yi uyut → RAM RGB sönmeli, uyandır → `Green` geri gelmeli.

## Gecikmeyi ayarlama

Varsayılan **5 sn**. Cold boot'ta SMBus geç uyanırsa RAM ara sıra Rainbow'da kalabilir.
Bir sonraki tam kapat-aç'tan sonra kontrol et:

```powershell
$log = Get-ChildItem "$env:APPDATA\OpenRGB\logs\*.log" | Sort LastWriteTime -Desc | Select -First 1
Get-Content $log.FullName | Select-String 'ENE DRAM|Corsair Vengeance RGB|Profile loading'
```

İki `ENE DRAM ... Registering` **ve** iki `Corsair Vengeance RGB ... Registering` satırı,
dördü için de `Profile loading: Succeeded` varsa gecikme yeterli. RAM satırları eksikse
10-15 sn'ye çıkar:

```powershell
.\install.ps1 -DelaySeconds 15
```

## Bilinen sınırlar

- **Cold boot'ta kısa Rainbow:** görev tetiklenene kadar (~gecikme kadar) fabrika
  Rainbow'u görünür. Yazılım tarafında tutulduğu sürece kaçınılmaz. Tamamen gitmesi
  için OpenRGB'de sade bir statik mod seçip cihaza flash'lamak gerekir (disket ikonu →
  "Save to device") — o da per-LED custom / yazılım efektlerini bitirir.
- **Uyanışta renk geç gelirse:** resident örnek power event'i geç alıyor olabilir.
  O durumda ek bir zamanlanmış görev: tetik System log, kaynak `Kernel-Power`,
  **Event ID 107** → `OpenRGB.exe --profile "Green" --noautoconnect`, RunLevel Highest,
  5-10 sn delay.

## Kaldırma

```powershell
.\install.ps1 -Uninstall
```

Görevi siler; profil dosyalarına ve `OpenRGB.json`'daki suspend/resume ayarına dokunmaz.

## İlgili

Vault kaydı: `🛠️ 600-Arsenal/Makine-DESKTOP-T0D7LKC.md` → "Kurulan araçların
yapılandırmaları".
