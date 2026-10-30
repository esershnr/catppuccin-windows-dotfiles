# Fonts

Font dosyaları repoda **tutulmuyor** (~280 MB yer kaplıyordu). `.ttf` dosyaları
`.gitignore`'da — bu klasöre indirirsen takip edilmez.

## Gerekli

| Font | Nerede kullanılıyor | Aile adı (config'lerde) |
| --- | --- | --- |
| **JetBrainsMono Nerd Font** | Windows Terminal, YASB, komorebi | `JetBrainsMono Nerd Font Mono`, `JetBrainsMono NFP` |
| **JetBrainsMono Nerd Font Mono** | Git Bash penceresi (mintty, `~/.minttyrc`) | `JetBrainsMono NFM` |

Aynı fontun üç ailesi var: `NF` (normal), `NFM` (Mono, ikonlar tek hücreye sabit),
`NFP` (Propo, ikonlar kendi genişliğinde). Hepsi tek pakette gelir. Mintty fontu
GDI ile aradığı için uzun adı (`... Nerd Font Mono`) tanımaz, "Font not found"
der: kısa adı (`NFM`) yaz. Prompt temasındaki pill kenarları ve ikonlar Mono'da
en sağlam durur.

`FiraCode` eskiden buradaydı ama artık hiçbir config referans vermiyor — istersen atla.

## Kurulum

`Nerd Fonts.url` → <https://github.com/ryanoasis/nerd-fonts/releases/> — son release'ten
`JetBrainsMono.zip`'i indir, aç, `.ttf`'leri seç → sağ tık → **Install for all users**.

Ya da paket yöneticisiyle:

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont
# veya
scoop bucket add nerd-fonts; scoop install JetBrainsMono-NF
```

Kurulumdan sonra Terminal / YASB / komorebi yeniden başlat.
