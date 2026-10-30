# flowlauncher/

[Flow Launcher](https://www.flowlauncher.com/) — portable kurulum
(`C:\Tools\Apps\Flow-Launcher-Portable`).

## İçerik

| Dosya | Ne | Hedef |
| --- | --- | --- |
| `*.xaml` | Temalar (Catppuccin Mocha, Rosé Pine) | `app-<sürüm>\UserData\Themes\` |
| `UserData\Settings\Settings.json` | Hotkey, tema, açılış, eklenti aç/kapa + action keyword'ler | `sync.ps1` |
| `UserData\Settings\Plugins\...Explorer\Settings.json` | Quick Access linkleri + Everything'in index/path/content motoru olarak seçimi | `sync.ps1` |
| `UserData\Settings\Plugins\...Program\Settings.json` | Program Sources (`C:\Tools\Apps` portable-exe taraması) | `sync.ps1` |

## Neden symlink değil, kopya

Portable Flow Launcher config'i sürüm bumplayan bir klasörde tutuyor:
`FlowLauncher\app-<sürüm>\UserData\Settings\`. Her güncellemede bu yol yeni
`app-<sürüm>`'e taşınıyor, symlink kopuyor. Bu yüzden modül `terminal/` ve `openrgb/`
gibi **kopya** stratejisinde: `sync.ps1` iki yönlü kopyalar, `app-*`'i glob'la çözer.

## Kullanım

```powershell
# Makinedeki ayarları repoya al (ayar penceresinde değişiklik yaptıktan sonra)
.\sync.ps1 -Backup

# Repodaki ayarları makineye yaz — Flow Launcher KAPALI olmalı
.\sync.ps1 -Restore
```

`-Restore` Flow Launcher çalışırken çalışmaz (çıkışta dosyaları geri ezer); `-Force` ile
zorlanır. Farklı kurulum yolu için `-FlowLauncherRoot`.

## Notlar

- Sadece yukarıdaki üç JSON izleniyor. Eklenti binary'leri, cache, log, pencere
  koordinatları `.gitignore`'da hariç.
- `Settings.json` bazı gürültülü alanlar taşıyor (`ActivateTimes`, pencere konumu,
  `ReleaseNotesVersion`) — `-Backup` sonrası küçük diff gürültüsü normal, commit'ten
  önce `git diff`'e bak.
- Güncelleme sonrası (`app-2.1.3` → sonraki): UserData yeni `app-*` klasörüne taşınır,
  gerekirse `sync.ps1 -Restore` ile repodan geri yaz.
