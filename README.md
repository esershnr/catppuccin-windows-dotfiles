# catppuccin-windows-dotfiles

Windows 11 dotfiles — pencere yöneticisi, status bar, medya oynatıcı, sağ tık menüsü,
kabuk özelleştirmeleri ve terminal. Ağırlıklı olarak **Catppuccin Mocha** / choco-bitter
paleti.

> Kişisel kurulum. Kopyala, kendine göre kırp. Sırlar repoda **yok** —
> `.example` / placeholder olarak bırakıldı, aşağıda hangileri olduğu yazıyor.

## İçindekiler

| Klasör | Ne |
| --- | --- |
| `komorebi/` | [komorebi](https://github.com/LGUG2Z/komorebi) tiling window manager config + `komorebi.sbz` kısayolları |
| `yasb/` | [YASB](https://github.com/amnweb/yasb) status bar — 3 varyant (`latest_fav_config`, `latest_fav_pyth`, `old_rosepine_config`) |
| `mpv/` | mpv + [uosc](https://github.com/tomasklaen/uosc) + thumbfast + videoclip, portable config |
| `nilesoft-shell/` | [Nilesoft Shell](https://nilesoft.org/) sağ tık menüsü (`shell.nss` + `imports/`) |
| `windhawk/` | [Windhawk](https://windhawk.net/) tam durum yedeği — `HKLM\SOFTWARE\Windhawk` reg export'u + `ModsSource/` + `userprofile.json` + `sync.ps1` (`-Backup` / `-Restore`). Detay: [`windhawk/README.md`](windhawk/README.md) |
| `openrgb/` | [OpenRGB](https://openrgb.org/) — Armoury Crate yerine: açılışta `Green` profilini uygulayan zamanlanmış görev + uykuda `OFF` / uyanışta `Green` suspend-resume profilleri + `install.ps1` |
| `flowlauncher/` | Flow Launcher temaları (`*.xaml`) + izlenen ayar JSON'ları (`Settings.json`, Explorer & Program eklenti ayarları) + `sync.ps1` (`-Backup` / `-Restore`). Detay: [`flowlauncher/README.md`](flowlauncher/README.md) |
| `terminal/` | Windows Terminal `settings.json`, PowerShell profili, Git Bash `.bashrc`, [oh-my-posh](https://ohmyposh.dev/) teması, fastfetch + `sync.ps1` (`-Backup` / `-Restore`, format sonrası hızlı kurulum: [`terminal/README.md`](terminal/README.md)) |
| `notepad++/` | Notepad++ Catppuccin teması |
| `cursor/` | İmleç setleri (dark, neon) |
| `fonts/` | Font dosyası yok — [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases/) kısayolu + kurulum notu ([`fonts/README.md`](fonts/README.md)). Gereken: JetBrainsMono Nerd Font |
| `ytm-desktop/`, `stylus - browser extension/` | YouTube Music masaüstü + tarayıcı userstyle |
| `bootstrap/` | Temiz makinede tek komutla kurulum: winget ile programlar + config'ler, seçmeli menü (`install.ps1`) |

## Kurulum

Temiz bir Windows 11'de en hızlı yol `bootstrap/install.ps1`: winget ile programları kurar,
config'leri yerine kopyalar, kullanıcı yollarını o makineye göre düzeltir. Yönetici olarak:

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap\install.ps1
```

Açılan menüde neyin kurulacağını seçersin (Boşluk işaretler, Enter başlatır). Elle yapılması
gerekenler en sonda "left for you" listesinde çıkar. Elle kurmak istersen aşağıdaki tablo
hangi dosyanın nereye gittiğini gösteriyor.

### 0. Önce fontu kur

> ⚠️ **Her şeyden önce [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/)
> kurulmalı.** yasb, Windows Terminal, komorebi ve oh-my-posh config'leri font ailesini
> adıyla (`JetBrainsMono Nerd Font Mono`, `JetBrainsMono NFP`) çağırıyor — font yoksa
> config'ler yüklenir ama **ikonlar kutu/soru işareti olarak görünür** ve hizalama bozulur.
> Config kurmaya başlamadan önce kur, sonra uygulamaları yeniden başlat.

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont
```

Detay ve alternatif kurulum yolları: [`fonts/README.md`](fonts/README.md).

### 1. Sonra program + config

Aşağıdaki tablo o denemenin en işe yarar çıktısı: **hangi dosya nereye gidiyor.** Daha önce
`yasb/` ve `mpv/` için bu hiçbir yerde yazılı değildi.

### Program → config yolu tablosu

| Modül | Program (winget id) | Repodaki dosya | Makinedeki hedef |
| --- | --- | --- | --- |
| `yasb/` | YASB (`AmN.yasb`) | `config.yaml`, `styles.css` | `%USERPROFILE%\.config\yasb\` |
| `yasb/` | — | `.env.example` → `.env` | `%USERPROFILE%\.config\yasb\.env` (repoya **girmez**) |
| `komorebi/` | komorebi (`LGUG2Z.komorebi`) | `komorebi.json`, `applications.json` | `%USERPROFILE%\` (kökü) |
| `mpv/` | mpv (`shinchiro.mpv`) | `portable_config\` içeriği | portable: `mpv.exe`'nin yanına `portable_config\` |
| `nilesoft-shell/` | Nilesoft Shell (`Nilesoft.Shell`) | `shell.nss`, `imports\`, `icons\` | portable kurulum klasörü (ör. `C:\Tools\Apps\NileSoft-Shell_portable\`) |
| `terminal/` | Windows Terminal (`Microsoft.WindowsTerminal`) | `settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `terminal/` | — | `WindowsPowerShell\Microsoft.PowerShell_profile.ps1` | `%USERPROFILE%\Documents\WindowsPowerShell\` |
| `terminal/` | fastfetch (`Fastfetch-cli.Fastfetch`) | `fastfetch\` | `%USERPROFILE%\.config\fastfetch\` |
| `terminal/` | oh-my-posh (`JanDeDobbeleer.OhMyPosh`) | `ohmyposh\` | `%USERPROFILE%\.config\ohmyposh\` |
| `terminal/` | clink (`chrisant996.Clink`) | `CMD\fastfetch.lua` | `%LOCALAPPDATA%\clink\fastfetch.lua` |
| `terminal/` | Git for Windows (`Git.Git`) | `bash\.bashrc`, `bash\.bash_profile`, `bash\.minttyrc` | `%USERPROFILE%\` |
| `flowlauncher/` | Flow Launcher (`Flow-Launcher.Flow-Launcher`) | `*.xaml` | kurulum klasörü → `app-<sürüm>\UserData\Themes\` |
| `flowlauncher/` | — | `UserData\Settings\*.json` | [`flowlauncher/sync.ps1 -Restore`](flowlauncher/README.md) → `app-<sürüm>\UserData\Settings\` (Flow Launcher kapalıyken) |
| `notepad++/` | Notepad++ (`Notepad++.Notepad++`) | `catppuccin-mocha.xml` | portable: `<kurulum>\themes\` · normal kurulum: `%APPDATA%\Notepad++\themes\` |
| `openrgb/` | OpenRGB (`OpenRGB.OpenRGB`) | `Green.orp`, `OFF.orp`, `OpenRGB.json` | `%APPDATA%\OpenRGB\` — sonra [`openrgb/install.ps1`](openrgb/install.ps1) |
| `windhawk/` | Windhawk (`RamenSoftware.Windhawk`) | — | [`windhawk/sync.ps1 -Restore`](windhawk/README.md) (registry + `%ProgramData%\Windhawk\`) |
| `ytm-desktop/` | YouTube Music Desktop (`Ytmdesktop.Ytmdesktop`) | `mocha.css` | **kopyalama yok** — uygulama ayarındaki `customCSSPath` repodaki dosyayı gösterir |
| `cursor/` | — | `dark\Install.inf` | sağ tık → Install (`%WINDIR%\Cursors\` + `HKCU`) |
| `stylus - browser extension/` | — | `import.json` | Stylus → Manage → Import (dosya sistemi config'i yok) |
| `fonts/` | JetBrainsMono NF | — | [`fonts/README.md`](fonts/README.md) |

**Symlink notu:** bir config'i kopyalamak yerine repoya symlink'lersen (`New-Item -ItemType
SymbolicLink`, dosya için admin gerekir; klasör için `Junction`, admin gerekmez) repo tek
doğruluk kaynağı olur. Ama bu **her modülde çalışmaz** — aşağıdakiler uygulamanın kendi
dosyayı yeniden yazması yüzünden symlink'i koparır, onları kopyalamak gerekir:

| Symlink olmaz | Neden |
| --- | --- |
| `openrgb/OpenRGB.json` + `.orp` | OpenRGB çalışırken JSON'u, profil kaydında `.orp`'yi kendi yeniden yazıyor |
| `windhawk/` | State `HKLM` registry'de; `ModsSource` servis tarafından yeniden derleniyor |
| Windows Terminal `settings.json` | Kendi profil parçalarını enjekte edip dosyayı atomik yeniden yazıyor |
| Notepad++ `config.xml` | Çıkışta yeniden yazıyor (tema `.xml`'i güvenli, o linklenebilir) |
| `cursor/` | INF `%WINDIR%` + registry'ye yazıyor |
| `stylus` | Dosya yok, stiller tarayıcı veritabanında |


## Sırlar

Repoda gerçek sır yok. Kendi değerlerini koyman gereken yerler:

| Dosya | Alan | Nereden |
| --- | --- | --- |
| `~/.config/yasb/.env` | `yasb/.env.example`'daki anahtarlar (hava durumu key'i, widget yolları) | `.env.example`'ı `~/.config/yasb/.env`'e kopyala, değerleri doldur; `config.yaml` bunları `$env:AD` ile okur |

`.gitignore`: `.venv/`, `__pycache__/`, mpv `cache/` ve `watch_later/` (izlenen dosya
yollarını sızdırır), `fonts/**` (README ve `.url` hariç — ~280 MB font) takip edilmez.

## Lisans

Config dosyaları serbestçe kullanılabilir. Üçüncü parti araçların (komorebi, yasb, mpv,
uosc, Nilesoft Shell, Windhawk…) kendi lisansları geçerlidir.
