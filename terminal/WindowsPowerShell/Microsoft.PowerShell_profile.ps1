# ============================================================
# PowerShell Profili - Optimize Edilmiş Versiyon
# ============================================================

# --- SORUN GIDERME GECMISI (basimiza gelenler, ileride lazim olursa) ---
#
# 1) ". $PROFILE" calismadi - "is not recognized as the name of a cmdlet..."
#    Sebep: Profil dosyasi $PROFILE'in gosterdigi yolda YOKTU (farkli bir
#    yere/isimde kaydedilmisti). Cozum: dosyanin gercek yolunu $PROFILE
#    degiskeninden teyit ettik, yoksa New-Item ile $PROFILE yolunda olusturduk.
#       Test-Path $PROFILE
#       New-Item -ItemType File -Path $PROFILE -Force
#
# 2) "...is not digitally signed. You cannot run this script..." (UnauthorizedAccess)
#    Sebep: Windows'un varsayilan Execution Policy'si imzasiz scriptleri
#    engelliyor. Cozum: kullanici bazinda RemoteSigned'a cektik (admin gerekmez,
#    sadece kendi local scriptlerimize izin verir, internetten gelenler hala
#    imza ister):
#       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#    Policy dogru gorundugu halde hata devam ederse, dosyanin "internetten
#    indirildi" olarak isaretlenmis olabilecegini kontrol ettik (Zone.Identifier
#    / Mark of the Web) ve gerekirse unblock ettik:
#       Get-Item $PROFILE -Stream Zone.Identifier -ErrorAction SilentlyContinue
#       Unblock-File $PROFILE
#
# 3) VSCode/Antigravity terminalinde anifetch ve oh-my-posh hala gozukuyordu
#    Sebep A: Ilk kontrolde operator onceligi/parantez eksikti, ayrica
#    Antigravity da PowerShell 5.1 + ayni $PROFILE yolunu kullaniyordu, bunu
#    once teyit ettik:
#       $PSVersionTable.PSVersion
#       $PROFILE.CurrentUserCurrentHost
#    Sebep B (asil sebep): Dosyayi guncelledikten sonra hala ESKI icerik
#    calisiyordu - degisiklikler $PROFILE dosyasina gercekten kopyalanmamisti.
#    Kontrol ettigimiz komut:
#       Get-Content $PROFILE | Select-String "oh-my-posh"
#    Cozum: notepad $PROFILE ile acip icerigi tamamen guncel haliyle degistirdik,
#    kaydettik, ardindan "reload" DEGIL, tamamen YENI bir terminal sekmesi actik
#    (prompt fonksiyonu eski oturumda bellekte kalmis olabiliyor).
#
# Genel ders: ortam degiskeni kontrolu ($env:TERM_PROGRAM, $env:VSCODE_PID vb.)
# dogru calissa da, asil dosyanin $PROFILE yoluyla eslesip eslesmedigini ve
# en guncel halinin diske yazilip yazilmadigini her zaman once dogrula.
# ------------------------------------------------------------------------


# 1. UTF-8 Ayarları
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# Not: Console encoding zaten UTF8 ayarlandigi icin chcp 65001 genelde gereksiz.
# Sorun yasarsan asagidaki satiri yorumdan cikar:
# try { chcp 65001 > $null } catch {}

# 2. Ekrani Temizle
Clear-Host

# 3. Ucuncu Parti Araclar
# VSCode, Antigravity, Cursor gibi editor-icine-gomulu terminalleri tespit et.
# Bu editorler genelde VSCODE_PID / TERM_PROGRAM ortam degiskenlerini set eder.
$script:IsEditorTerminal = [bool]($env:VSCODE_PID) -or ($env:TERM_PROGRAM -eq 'vscode')
# Debug: profil yuklenirken durumu gormek istersen yorumdan cikar:
# Write-Host "IsEditorTerminal: $script:IsEditorTerminal" -ForegroundColor Magenta

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

# anifetch: SADECE gercek/bagimsiz terminalde calissin (Windows Terminal, conhost vb.)
# Editor terminallerinde (VSCode, Antigravity) gosterilmesin.
# if ($Host.Name -eq 'ConsoleHost' -and -not $script:IsEditorTerminal) {
#     try {
#         anifetch video.mp4 -W 45 -H 25 -ca "--symbols braille --fg-only"
#     }
#     catch {
#         Write-Warning "Anifetch yuklenemedi! Videoyu onbellege almak icin ilk once video bulunan klasore gidip; anifetch video.mp4 -W 45 -H 25 -ca '--symbols braille --fg-only' komutunu calistirmalisin."
#     }
# }

# oh-my-posh: SADECE bagimsiz terminalde calissin, editor terminalinde (VSCode/Antigravity) kapali.
if (-not $script:IsEditorTerminal) {
    try {
        oh-my-posh init pwsh --config "$HOME\.config\ohmyposh\esershnr-mauve.omp.json" | Invoke-Expression
    }
    catch {
        Write-Warning "Oh My Posh config yuklenemedi!"
    }
}

# 4. Alias ve Fonksiyonlar

function Reload-Profile {
    . $PROFILE
    Write-Host "Profile reloaded successfully!" -ForegroundColor Green
}
Set-Alias -Name reload -Value Reload-Profile


# 5. PowerShell Optimizasyonlari
# PSReadLine, PowerShell 5.1+ ile zaten birlikte gelir; ekstra modul kontrolu kaldirildi.
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# 6. (Opsiyonel) Profil yukleme suresini olcmek icin:
# Measure-Command { . $PROFILE }

