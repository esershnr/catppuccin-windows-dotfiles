# Windhawk — tam durum yedeği (mod + her ayar)

[Windhawk](https://windhawk.net/) tek bir config dosyası tutmuyor. Her şey üç yerde:

| Kaynak | İçerik |
| --- | --- |
| `HKLM\SOFTWARE\Windhawk` (registry) | hangi mod açık/kapalı **ve her mod ayarı** — styler'ların dev YAML blob'ları dahil |
| `%ProgramData%\Windhawk\ModsSource\*.wh.cpp` | mod kaynak kodu; kopyası olunca yeni makine **çevrimdışı** derleyebiliyor, elle düzenlenmiş / özel modlar korunuyor |
| `%ProgramData%\Windhawk\userprofile.json` | kurulu mod listesi + sürüm sabitlemeleri, Windhawk bunlara göre uzlaştırıyor |

`Engine\Mods\{32,64}` altındaki derlenmiş DLL'ler de repoda tutuluyor (`Engine/Mods/`).
Her modun registry girdisi kendi DLL'inin adını taşıyor (`LibraryFileName`). Windhawk servis
açılışında ModsSource'tan **derlemiyor**: temiz bir VM'de (2026-10-30) DLL'ler olmadan
modlar yüklü görünüp UI'dan tek tek güncellenene kadar çalışmadı.

Modların çoğu C++ çalışma zamanını aynı klasörden `libc++.whl` / `libunwind.whl` olarak
import ediyor. Windhawk bunları oraya kurulumda koymuyor: UI, editör eklentisi açılınca
`Compiler\<hedef>\bin\libc++.dll`'i `Engine\Mods\{32,64}\libc++.whl` olarak kopyalıyor.
Yalnız tepsi çalışmış temiz bir makinede bu dosyalar yok ve modlar `0x8007007E` (modül
bulunamadı) ile yüklenmiyor. `-Restore` bunları kurulu Windhawk'ın derleyicisinden aynı
şekilde kopyalıyor (repoda tutulmuyor, kurulu sürümle eşleşsin diye).

Yöntem [`ramensoftware/windhawk#195`](https://github.com/ramensoftware/windhawk/issues/195) /
[`discussions#155`](https://github.com/ramensoftware/windhawk/discussions/155) kaynaklı,
**Windhawk 1.7.3'te (2026) hâlâ geçerli**.

## İçindekiler

| Dosya | Ne |
| --- | --- |
| `sync.ps1` | `-Backup`: makinedeki canlı durumu repoya alır. `-Restore`: repoyu makineye uygular (registry import + servis restart), kendini elevate eder (bir UAC). |
| `settings/windhawk.reg` | `HKLM\SOFTWARE\Windhawk` export'u. `sync.ps1 -Backup` üretir. `reg export`'un yazdığı hâliyle (UTF-16LE + BOM + CRLF) byte-byte tutulur — Türkçe harf / emoji / Nerd Font glyph içerdiğinden `reg import` başka encoding kabul etmiyor. `.gitattributes`'ta `binary`, yani git diff'i opak. |
| `ModsSource/*.wh.cpp` | mod kaynakları (bu makinedeki hali). |
| `userprofile.json` | kurulu mod + sürüm listesi. |
| `Engine/Mods/{32,64}/*.dll` | derlenmiş modlar; `-Backup` aynalar, `-Restore` makinede olmayanları kopyalar (aynı ad aynı derleme, kilitli olabileceği için üstüne yazılmaz). |
| `reference/` | styler ayarlarının elle yapıştırılmış okunur kopyaları (`*.yml`, `Optional Mods I Use.txt`). Kaynak-of-truth artık `windhawk.reg`; bunlar sadece insan-okuru referans. |

## Kullanım

### Ayar değiştirdikten sonra yedekle

Windhawk UI'da bir mod ekledin / ayar oynadın →

```powershell
cd windhawk
.\sync.ps1 -Backup      # reg export + ModsSource + userprofile.json + Engine\Mods -> repo
git diff                # settings/windhawk.reg diff'ini gözden geçir
git add windhawk && git commit
```

`-Backup` reg export için elevate ister (bir UAC).

### Yeni makinede geri yükle

```powershell
winget install RamenSoftware.Windhawk    # önce Windhawk kurulu olmalı
cd windhawk
.\sync.ps1 -Restore
```

`-Restore` sırayla: `ModsSource`, `userprofile.json`, derlenmiş DLL'leri ve modların C++
çalışma zamanını (`libc++.whl`, `libunwind.whl`, kurulu derleyiciden) `%ProgramData%\Windhawk`'e
kopyalar → `windhawk.reg`'i import eder → `Windhawk` servisini restart eder (modları yükler,
Windows'u yeniden başlatmak gerekmez). HKLM import + servis restart için elevate ister (bir UAC).

Bitince Windhawk UI'ı aç, her modun yüklendiğini doğrula. Winget çok daha yeni bir Windhawk
kurduysa eski derlenmiş modlar uyumsuz kalabilir; o zaman o modu UI'dan güncelle.

## Bilinen sınırlar

- **`.reg` diff'i opak:** git'te `binary`. Ne değiştiğini görmek için
  `Get-Content windhawk\settings\windhawk.reg` (PowerShell UTF-16'yı otomatik çözer)
  ya da `-Backup`'ı yeniden çalıştırıp dosyayı oku. Not: `SettingsChangeTime` gibi
  zaman damgaları ayar değişmese de oynar; anlamlı olan `Settings` alt anahtarları
  ve `Disabled` bayrağı.
- **Sürüm kayması:** `userprofile.json` sürüm sabitliyor ama store'daki mod daha
  yeniyse Windhawk restore'dan sonra güncelleyebilir. Kritikse ilgili modu UI'da
  "pin"le.
- **Özel / mağaza-dışı modlar:** kaynağı `ModsSource/`'ta olduğu sürece taşınır;
  registry'deki `LibraryFileName` derleme sonrası eşleşir.

## İlgili

Vault kaydı: `🛠️ 600-Arsenal/Makine-DESKTOP-T0D7LKC.md` → "Kurulan araçların
yapılandırmaları".
