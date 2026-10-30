# Terminal Kurulum Rehberi

Bu rehber, `terminal/` klasörü altındaki tüm dosyaları kullanarak
**Windows Terminal + PowerShell + CMD + Git Bash** için fastfetch, anifetch ve
oh-my-posh kurulumunu adım adım anlatır.

## Klasör Yapısı

```
terminal/
├── bash/
│   ├── .bash_profile
│   ├── .bashrc
│   └── .minttyrc
├── CMD/
│   ├── cmd_fastfetch_ohmyposh_kurulum.md
│   └── fastfetch.lua
├── WindowsPowerShell/
│   └── Microsoft.PowerShell_profile.ps1
├── anifetch/
│   └── video.mp4
├── fastfetch/
│   ├── ascii.txt
│   └── config.jsonc
├── ohmyposh/
│   ├── esershnr-mauve.omp.json   (güncel: Catppuccin Mocha mauve)
│   └── esershnr.omp.json         (eski tema, yedek)
├── PowerShell - Fastfetch - Anifetch Kurulum.txt
├── settings.json
└── sync.ps1                      (-Backup / -Restore, tüm config'leri iki yönlü kopyalar)
```

> Bu dosya, yukarıdaki iki ayrı kurulum dosyasının (`PowerShell - Fastfetch
>
> - Anifetch Kurulum.txt`ve`CMD/cmd_fastfetch_ohmyposh_kurulum.md`) tek
>   bir yerden takip edilebilmesi için hazırlanmış kapsayıcı rehberdir. Detaylı
>   adımlar için ilgili dosyaya da bakabilirsin, ama buradan sırayla ilerlemen
>   yeterli.

---

## Format Sonrası Hızlı Kurulum

Temiz bir Windows'ta bu terminal düzenini (PowerShell, CMD ve Git Bash'te aynı
Catppuccin Mocha mauve oh-my-posh teması, fastfetch, Windows Terminal ayarları)
sırayla şunlarla geri kur. Bölüm 1-3B aynı adımları tek tek anlatır, takıldığın
yerde oraya bak.

1. **Font** (önce, yoksa ikonlar boş kutu çıkar):

   ```powershell
   winget install --id DEVCOM.JetBrainsMonoNerdFont
   ```

   Tüm varyantlar kurulur. Windows Terminal `JetBrainsMono NFP`, Git Bash
   (mintty) `JetBrainsMono NFM` kullanır. Ayrıntı: [`fonts/README.md`](../fonts/README.md).

2. **Programlar** (her biri ayrı komut):

   ```powershell
   winget install Git.Git
   winget install JanDeDobbeleer.OhMyPosh --source winget
   winget install Fastfetch-cli.Fastfetch
   winget install chrisant996.Clink
   ```

   `btop`, `fd`, `fzf`, `yazi` ve anifetch isteğe bağlıdır (Bölüm 4 ve 2.5).

3. **Script izni** (PowerShell profilinin yüklenmesi için):

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Repoyu klonla ve config'leri geri yükle** (repo 🔒 private, GitHub girişi gerekir):

   ```powershell
   git clone https://github.com/esershnr/catppuccin-windows-dotfiles.git
   cd catppuccin-windows-dotfiles\terminal
   .\sync.ps1 -Restore -WhatIf   # önce neyin nereye yazılacağına bak
   .\sync.ps1 -Restore
   ```

   `-Restore` şunları yerine koyar: PowerShell profili, oh-my-posh temaları,
   fastfetch config (kullanıcı adı otomatik yazılır), Windows Terminal
   `settings.json`, Clink `fastfetch.lua`, Git Bash `.bashrc` / `.bash_profile` /
   `.minttyrc`. Clink'i de ayarlar: sessiz autorun, oh-my-posh prompt'u, mauve tema.

5. **Tüm terminalleri kapat, yenilerini aç** (Git Bash penceresi dahil, mintty
   ayarı yalnız yeni pencerede devreye girer) ve doğrula:

   - PowerShell: fastfetch, sonra üç satırlı mauve prompt
   - CMD: banner yok, fastfetch bir kere, aynı prompt
   - Git Bash: aynı prompt, shell adı `bash`, ikonlar kutu değil

Config'i sonradan değiştirirsen makineden repoya almak için `.\sync.ps1 -Backup`,
sonra `git diff` ile bakıp commit'le.

---

## Bölüm 1 — Windows Terminal Ayarları

1. JetBrainsMono Nerd Font yüklü olsun.
2. Masaüstündeyken `Win + R` tuşuna bas, ardından `CMD` yazıp `Enter` tuşuna
   bas ve `CTRL + ,` ile ayarlara gir. En sol alttaki "Open JSON file" yazan
   "⚙️" simgesine tıkla ve `terminal/settings.json` dosyasının içeriğini
   kopyala, açılan yere yapıştır.

---

## Bölüm 2 — PowerShell Kurulumu (fastfetch + anifetch + oh-my-posh)

### 2.1. Script Çalıştırma İznini Ver ve Profil Dosyasını Oluştur

Windows varsayılan olarak PowerShell scriptlerinin (`.ps1`) çalışmasını engeller (`Restricted` modu). Format sonrası profil dosyasının ve scriptlerin sorunsuz çalışabilmesi için önce çalıştırma iznini verip ardından profili oluşturun:

Masaüstündeyken `Win + R` → `Powershell` → `Enter`, terminale sırasıyla şunları yazın:

```powershell
# Script çalıştırma izni ver (Yönetici yetkisi gerektirmez, sadece kendi kullanıcınızı etkiler)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Profil dosyasını oluştur
New-Item -ItemType File -Path $PROFILE -Force
```

### 2.2. PSReadLine Modülünü Güncelle (Önemli / Predictive IntelliSense)

Profil dosyasındaki modern satır içi komut tamamlama/öneri (`-PredictionSource History`, `-PredictionViewStyle InlineView`) ve geçmiş arama tuşlarının çalışabilmesi için **PSReadLine** modülünün güncel (v2.2.0+) olması gerekir. Windows ile gelen dahili sürüm eskidir ve profil yüklenirken `NamedParameterNotFound` hatası verir.

> **Önemli (Admin Yetkisi):** Modül ve paket sağlayıcı yükleme işlemleri için PowerShell'i **Yönetici Olarak Çalıştırın (Run as Administrator)**.

PowerShell'i **Yönetici olarak** açıp şu komutu çalıştırın:

```powershell
Install-Module -Name PSReadLine -Force -SkipPublisherCheck
```

> **Format Sonrası / Temiz Kurulum Notu:**
> Yeni format atılmış bir bilgisayarda ilk kez `Install-Module` çalıştırıldığında PowerShell şu onayları soracaktır:
> 1. **NuGet Provider:** `NuGet provider is required to continue... [Y]es [N]o` uyarısı gelirse **`Y`** (Yes) tuşuna basıp onaylayın.
> 2. **Untrusted Repository:** `You are installing the modules from an untrusted repository (PSGallery)... [Y]es [A]ll` uyarısı gelirse **`A`** (Yes to All) veya **`Y`** (Yes) tuşuna basarak devam edin.
>
> *(İsteğe bağlı)* Bu soruların hiç sorulmadan sessiz/otomatik kurulmasını isterseniz modülü kurmadan önce şu komutları da çalıştırabilirsiniz:
> ```powershell
> # NuGet sağlayıcısını otomatik yükle
> Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
> 
> # PSGallery'yi güvenilir depo yap (onay sorusunu engeller)
> Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
> ```

### 2.3. Profil Klasörünü Yerleştir

`terminal/WindowsPowerShell/` klasörünü kopyala
`C:\Users\<kullanıcı_adı>\Documents\` içine yapıştır.

### 2.4. Fastfetch'i Kur ve Yapılandır

```powershell
winget install fastfetch
```

Yükleme bitince terminali kapat.

`terminal/fastfetch/` klasörünü kopyalayıp
`C:\Users\<kullanıcı_adı>\.config\` içine yapıştır (`.config` klasörü yoksa
oluştur).

İçindeki `config.jsonc` dosyasını bir metin editörüyle aç,
`<kullanıcı_adı>` geçen kısımları kendi kullanıcı adınla değiştir
(`ascii.txt` yolunu gösteren satır).

PowerShell profiline aşağıdaki komut bloğunu ekle (Kopyala/Yapıştır yaptıysan zaten ekli senin bir şey yapmana gerek yok):

```powershell
# fastfetch: SADECE gercek/bagimsiz terminalde calissin (Windows Terminal, conhost vb.)
# Editor terminallerinde (VSCode, Antigravity) gosterilmesin.
if ($Host.Name -eq 'ConsoleHost' -and -not $script:IsEditorTerminal) {
    try {
        fastfetch -c "$HOME/.config/fastfetch/config.jsonc"
    }
    catch {
        Write-Warning "Fastfetch yuklenemedi!"
    }
}
```

Profili kaydet, terminali yeniden aç — fastfetch görünmesi gerekiyor.

> **Olası hata 1:** `... is not digitally signed. You cannot run this
script on the current system.`
> Çözüm (admin gerekmez, sadece kendi kullanıcı hesabını etkiler):
>
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```
>
> Hata devam ederse dosya "internetten indirildi" olarak işaretli olabilir:
>
> ```powershell
> Get-Item $PROFILE -Stream Zone.Identifier -ErrorAction SilentlyContinue
> Unblock-File $PROFILE
> ```
>
> **Olası hata 2:** `. $PROFILE` çalıştırınca `is not recognized as the
name of a cmdlet...` hatası. Bu, dosyanın `$PROFILE`'ın gösterdiği yolda
> olmadığı anlamına gelir. Doğrula:
>
> ```powershell
> Test-Path $PROFILE
> $PROFILE.CurrentUserCurrentHost
> ```
>
> **Olası hata 3:** `Set-PSReadLineOption : A parameter cannot be found that matches parameter name 'PredictionSource'` veya `'PredictionViewStyle'`
> Bu hata sistemdeki PSReadLine sürümünün eski olduğunu gösterir. Çözüm için PowerShell'i **Yönetici olarak** açıp **2.2** adımındaki `Install-Module -Name PSReadLine -Force -SkipPublisherCheck` komutunu çalıştırın.

### 2.5. Anifetch'i Kur (Opsiyonel)

Python kurulu olmalı. Kurulum için:

```powershell
winget install Python.Python.3.13
```

Python kurulduktan sonra:

```powershell
winget install chafa ffmpeg
pip install anifetch-cli
```

Yükleme bitince terminali kapat, `terminal/anifetch/video.mp4` dosyasının
bulunduğu klasörde (veya video path'ini tam vererek herhangi bir yerden) yeni bir terminal
açıp aşığdaki komutu yaz ve enter'a bas:

```powershell
anifetch video.mp4 -W 45 -H 25 -ca "--symbols braille --fg-only"
```

Profildeki fastfetch komut bloğunu "CTRL + Ö" ile yorum içine al ya da sil, yerine varsayılan
olarak yorum satırı haline getirip bıraktığım aşağıdaki gibi gözüken anifetch kodunu yorum satırından çıkar.

```powershell
if ($Host.Name -eq 'ConsoleHost' -and -not $script:IsEditorTerminal) {
    try {
        anifetch video.mp4 -W 45 -H 25 -ca "--symbols braille --fg-only"
    }
    catch {
        Write-Warning "Anifetch yuklenemedi! Videoyu onbellege almak icin ilk once video bulunan klasore gidip; anifetch video.mp4 -W 45 -H 25 -ca '--symbols braille --fg-only' komutunu calistirmalisin."
    }
}
```

Kaydet, yeni terminal aç — animasyonlu görünüm gelecek.

### 2.6. Oh My Posh'u Kur

```powershell
winget install JanDeDobbeleer.OhMyPosh --source winget
```

Güncelleme için: `winget upgrade JanDeDobbeleer.OhMyPosh --source winget`

`terminal/ohmyposh/` klasörünü kopyalayıp
`C:\Users\<kullanıcı_adı>\.config\` içine yapıştır.

Kopyaladığımız Powershell profilinin içinde aşağıdaki gibi bir kod bulunuyor, eğer
kullanılmayacaksa yorum satırına al:

```powershell
# oh-my-posh: SADECE bagimsiz terminalde calissin, editor terminalinde (VSCode/Antigravity) kapali.
if (-not $script:IsEditorTerminal) {
    try {
        oh-my-posh init pwsh --config "$HOME\.config\ohmyposh\esershnr-mauve.omp.json" | Invoke-Expression
    }
    catch {
        Write-Warning "Oh My Posh config yuklenemedi!"
    }
}
```

### 2.7. (Opsiyonel) Editör Terminalinde Gizleme

VSCode, Antigravity gibi editörlerin içine gömülü terminalinde fastfetch /
anifetch / oh-my-posh'un görünmesini istemiyorsan, profilin en üstüne şu
kontrolü ekle(Kopyala/Yapıştır yaptıysan zaten ekli):

```powershell
$script:IsEditorTerminal = [bool]($env:VSCODE_PID) -or ($env:TERM_PROGRAM -eq 'vscode')
```

Sonrasında ilgili komutları şu şekilde sarmala:

```powershell
if (-not $script:IsEditorTerminal) {
    # fastfetch / anifetch / oh-my-posh init satırları buraya
}
```

> **Önemli:** Profilde değişiklik yaptıktan sonra `reload` yerine
> tamamen **yeni** bir terminal penceresi/sekmesi aç. Prompt fonksiyonu
> bazı durumlarda bellekte kalabilir ve `reload` bunu yansıtmaz.

---

## Bölüm 3 — CMD Kurulumu (fastfetch + oh-my-posh)

> Detaylı adımlar: `CMD/cmd_fastfetch_ohmyposh_kurulum.md`. CMD'nin
> PowerShell'deki `$PROFILE` gibi bir profil dosyası YOKTUR — bunun yerine
> **Clink** ile bash/zsh tarzı bir script katmanı ekliyoruz.

### 3.1. Clink'i Kur

```cmd
winget install clink
```

Terminali tamamen kapat, yeni bir CMD aç, doğrula:

```cmd
clink --version
```

### 3.2. Clink'i Otomatik Başlat ve Banner'ı Sustur

```cmd
clink autorun install
clink autorun uninstall
clink autorun install -- --quiet
```

> İlk `install` ile autorun kurulur, ikinci `uninstall` + `install --
--quiet` ile Clink'in açılışta bastığı telif hakkı banner'ı susturulur.
> Doğrulamak için: `clink autorun show`

### 3.3. Oh My Posh Promptunu Aktifleştir

Clink'in yerleşik oh-my-posh entegrasyonunu kullan (manuel `.lua` scriptine
gerek yok):

```cmd
clink config prompt use oh-my-posh
clink set ohmyposh.theme "%USERPROFILE%\.config\ohmyposh\esershnr-mauve.omp.json"
```

> Tema dosyası PowerShell'de kullanılan `esershnr-mauve.omp.json` ile aynı,
> görünüm tutarlı kalır.

### 3.4. Fastfetch'i Açılışta Bir Kere Çalıştır

`CMD/fastfetch.lua` dosyasını Clink'in script klasörüne kopyala:

```cmd
copy "terminal\CMD\fastfetch.lua" "%LOCALAPPDATA%\clink\fastfetch.lua"
```

> Script klasörünün gerçek yolunu doğrulamak istersen: `clink info`
> çalıştır, çıktıdaki `scripts` satırına bak.

### 3.5. Test Et

Tamamen yeni bir CMD penceresi aç (mevcut pencerede `clink reset` yetmez).
Sırasıyla görmen gerekenler:

1. Hiçbir Clink banner'ı yok (sessiz mod)
2. Fastfetch sistem bilgisi (bir kere, en üstte)
3. Oh-my-posh özel prompt teması

### 3.6. Sorun Giderme

- **Clink hiç tepki vermiyor:** `clink autorun show` ile autorun'un kurulu
  olduğunu doğrula.
- **oh-my-posh görünmüyor:** `clink config prompt show` ile aktif prompt
  modunun `oh-my-posh` olduğunu kontrol et.
- **fastfetch görünmüyor:** `clink info` ile script klasörünün doğru yolunu
  teyit et, `fastfetch.lua` dosyasının tam o klasörde ve doğru isimde
  (`.lua.txt` değil) olduğunu kontrol et, `where fastfetch` ile PATH'te
  olduğunu doğrula.

---

## Bölüm 3B: Git Bash Kurulumu (oh-my-posh)

Git Bash'te prompt `~/.bashrc` içindeki tek bir `oh-my-posh init bash` satırıyla
özelleştirilir. PowerShell ve CMD ile aynı tema dosyasını kullanır, görünüm
her yerde tutarlı kalır. Kaynak: [Oh My Posh, Customize](https://ohmyposh.dev/docs/installation/customize).

### 3B.1. Ön Gereksinim

- Git for Windows (Git Bash)
- oh-my-posh kurulu (Bölüm 2.6)
- Tema dosyası `~/.config/ohmyposh/esershnr-mauve.omp.json` yerinde (Bölüm 2.6)

### 3B.2. Dosyaları Yerleştir

`bash/` klasöründeki üç dosyayı ev dizinine kopyala (Git Bash'te, repo kökünden):

```bash
cp terminal/bash/.bashrc ~/.bashrc
cp terminal/bash/.bash_profile ~/.bash_profile
cp terminal/bash/.minttyrc ~/.minttyrc
```

> Ev dizininde bu dosyalar zaten varsa üzerine yazma, `.bashrc` içindeki
> `if ... fi` bloğunu mevcut dosyanın sonuna ekle.

- **`.bashrc`**: oh-my-posh'u yükler. Tema yolu `$HOME` ile tam yola açılır
  (dokümana göre göreli yol ve `~` Git Bash'te sorun çıkarabilir).
- **`.bash_profile`**: Git Bash giriş kabuğu olarak açıldığında (mintty, Windows
  Terminal profili) `~/.bashrc`'yi kendisi okumaz, bu dosya onu elle yükler.
- **`.minttyrc`**: Git Bash'i kendi penceresinde (mintty) açtığında font burada
  seçilir, Windows Terminal ayarları mintty'yi etkilemez. Font Nerd Font Mono
  olmazsa prompt'taki ikonlar ve pill kenarları boş kutu çıkar. Mintty fontu
  GDI ile arar, bu yüzden uzun ad (`JetBrainsMono Nerd Font Mono`) değil kısa ad
  gerekir: `Font=JetBrainsMono NFM`. Uzun adı yazarsan "Font not found" uyarısı
  çıkar. Pencereyi kapatıp yeniden aç, ayar yeni pencerede devreye girer.

### 3B.3. Neden Yalnız Etkileşimli Kabukta

`.bashrc` içindeki `[[ $- == *i* ]]` koşulu, prompt'u yalnız elle açılan
kabukta yükler. Ajan ve araç kabukları (Claude Code'un Bash aracı gibi)
etkileşimsiz açılır, prompt kaçış kodları komut çıktısına karışmasın diye
orada yüklenmez. Bu, PowerShell profilindeki "editör terminalinde kapalı"
mantığının Git Bash karşılığıdır.

### 3B.4. Test Et

Yeni bir Git Bash penceresi aç ya da mevcutta `exec bash` çalıştır.
Prompt'un üç satırlı mauve temayla geldiğini ve shell adının `bash` yazdığını
doğrula. Hızlı kontrol:

```bash
type -t _omp_hook        # "function" dönmeli
oh-my-posh print primary --shell bash
```

### 3B.5. Sorun Giderme

- **Prompt değişmedi:** `echo $-` çıktısında `i` olmalı, `type -t _omp_hook`
  boşsa `~/.bash_profile` ile `~/.bashrc` yerinde mi bak.
- **İkonlar boş kutu:** Git Bash mintty penceresinde açıldıysa `~/.minttyrc`
  içinde `Font=JetBrainsMono NFM` olmalı (Windows Terminal'de açıyorsan profilin
  fontuna bak). "Font not found" uyarısı geliyorsa ad yanlıştır, kısa GDI adını
  yaz. Font hiç yüklü değilse `fonts/README.md`'deki adımla kur.
- **İkonlar kırık ya da kenarlar kayık:** terminal fontu Nerd Font olmalı. Propo
  (`JetBrainsMono NFP`) ikon genişliğini tek hücreye sabitlemez ve pill
  kenarlarını bozar, `JetBrainsMono Nerd Font Mono` kullan.
- **`oh-my-posh: command not found`:** Git Bash PATH'i Windows PATH'inden
  gelir, oh-my-posh'u kurduktan sonra Git Bash'i tamamen kapatıp aç.

---

## Genel Not

PowerShell (`$PROFILE`), CMD (`Clink`) ve Git Bash (`~/.bashrc`) birbirinden
tamamen ayrı sistemlerdir. Birini değiştirmek diğerini etkilemez, her birini
ayrı ayrı yapılandırman gerekir. Aynı şekilde VSCode/Antigravity gibi editörlerin
gömülü terminali de PowerShell 5.1 + aynı `$PROFILE` yolunu kullanabilir,
bu yüzden "editörde gizleme" ayarını (Bölüm 2.7) yaparken hangi shell'i
kullandığını (`$PSVersionTable.PSVersion`, `$PROFILE.CurrentUserCurrentHost`)
önce doğrulamak işini kolaylaştırır.

---

## Bölüm 4 — Diğer Kullanışlı CLI Araçları (btop, fd, fzf, yazi)

Terminal deneyimini zenginleştirmek için aşağıdaki popüler araçları da kurabilirsin:

### 4.1. Kurulum Komutları

```powershell
# btop (Gelişmiş sistem kaynak izleyici)
winget install aristocratos.btop

# fd (Hızlı ve modern dosya arama aracı)
winget install sharkdp.fd

# fzf (Bulanık/fuzzy arama ve filtreleme aracı)
winget install junegunn.fzf

# yazi (Terminal tabanlı hızlı dosya yöneticisi)
winget install sxyazi.yazi
```

### 4.2. Araçları Çalıştırma

Kurulumlar tamamlandıktan sonra terminali kapatıp yeni bir pencere açarak şu komutlarla araçları çalıştırabilirsin:

- **btop**: `btop`
- **fd**: `fd <aranacak_kelime>`
- **fzf**: `fzf`
- **yazi**: `yazi`