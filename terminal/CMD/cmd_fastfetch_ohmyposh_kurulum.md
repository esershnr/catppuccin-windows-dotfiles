# CMD için Fastfetch + Oh My Posh Kurulumu

Bu kılavuz, Windows CMD (Command Prompt) açıldığında otomatik olarak
**fastfetch** (sistem bilgisi) ve **oh-my-posh** (özel prompt teması)
göstermesini sağlar. Hiçbir şey kurulu olmadığı varsayılarak yazılmıştır.

CMD'nin PowerShell'deki `$PROFILE` gibi bir profil dosyası YOKTUR. Bu yüzden
**Clink** adlı bir araç kullanarak CMD'ye bash/zsh tarzı bir script katmanı
ekliyoruz; oh-my-posh ve fastfetch bu katman üzerinden tetiklenir.

---

## 0. Ön Gereksinimler

Aşağıdakilerin zaten kurulu olduğunu varsayıyoruz (kurulu değilse winget ile
kurulabilir):

```cmd
winget install JanDeDobbeleer.OhMyPosh
winget install fastfetch
```

Kurulumdan sonra terminali kapat, yeni bir CMD aç, kontrol et:

```cmd
oh-my-posh --version
fastfetch --version
```

---

## 1. Adım: Clink'i Kur

CMD'ye readline-tarzı düzenleme ve script desteği ekleyen araç.

```cmd
winget install clink
```

Kurulduktan sonra **terminali tamamen kapat**, yeni bir CMD penceresi aç
(PATH güncellemesi için gerekli). Doğrula:

```cmd
where clink
clink --version
```

---

## 2. Adım: Clink'i Otomatik Başlat (Autorun)

Her CMD açıldığında Clink'in otomatik devreye girmesi için:

```cmd
clink autorun install
```

Kontrol etmek istersen:

```cmd
clink autorun show
```

Şuna benzer bir çıktı görmen gerekir:

```
Current AutoRun values
  Current user:
    native : "C:\Program Files (x86)\clink\clink.bat" inject --autorun
```

---

## 3. Adım: Clink Başlangıç Banner'ını Kapat

Clink varsayılan olarak her açılışta kendi telif hakkı banner'ını basar
(`Clink v1.9.x ... Copyright (c) ...`). Bunu susturmak için autorun'u
**quiet** modla yeniden kuruyoruz:

```cmd
clink autorun uninstall
clink autorun install -- --quiet
```

Yeni bir CMD penceresi aç, banner'ın artık görünmediğini doğrula.

---

## 4. Adım: Oh My Posh Promptunu Aktifleştir

Clink'in kendi yerleşik oh-my-posh entegrasyonunu kullanıyoruz (manuel Lua
scriptine gerek yok):

```cmd
clink config prompt use oh-my-posh
clink set ohmyposh.theme "%USERPROFILE%\.config\ohmyposh\esershnr-mauve.omp.json"
```

> Not: Tema dosyasının yolu, PowerShell profilinde kullandığın
> `esershnr-mauve.omp.json` ile aynı — böylece görünüm tutarlı kalır. Kendi tema
> dosyan farklı bir konumdaysa yolu ona göre değiştir.

Yeni bir CMD penceresi aç, oh-my-posh prompt'unun göründüğünü doğrula.

---

## 5. Adım: Fastfetch'i Açılışta Bir Kere Çalıştır

Fastfetch'i Clink üzerinden, terminal her açıldığında **sadece bir kere**
çalışacak şekilde ekliyoruz (her komutta tekrar tekrar değil).

**5.1.** Aşağıdaki içerikle bir `fastfetch.lua` dosyası oluştur:

```lua
-- ============================================================
-- Clink + fastfetch entegrasyonu
-- fastfetch'i SADECE terminal acilisinda bir kere calistirir.
-- ============================================================

local fastfetch_shown = false

local function show_fastfetch_once()
    if not fastfetch_shown then
        fastfetch_shown = true
        os.execute("fastfetch")
    end
end

clink.onbeginedit(show_fastfetch_once)
```

**5.2.** Bu dosyayı Clink'in script klasörüne kopyala:

```cmd
copy "indirdigin_yol\fastfetch.lua" "%LOCALAPPDATA%\clink\fastfetch.lua"
```

> Script klasörünün gerçek yolunu doğrulamak istersen: `clink info` çalıştır,
> çıktıdaki `scripts` satırına bak.

---

## 6. Adım: Test Et

Tüm adımları tamamladıktan sonra **tamamen yeni** bir CMD penceresi aç
(mevcut pencerede `clink reset` yetmez, gerçekten yeni pencere/sekme aç).

Sırasıyla şunları görmen gerekiyor:
1. Hiçbir Clink banner'ı YOK (sessiz mod)
2. Fastfetch sistem bilgisi (bir kere, en üstte)
3. Oh-my-posh özel prompt teması

---

## Sorun Giderme

- **Clink hiç tepki vermiyor:** `clink autorun show` ile autorun'un kurulu
  olduğunu doğrula. Kurulu değilse 2. adımı tekrar yap.
- **oh-my-posh görünmüyor:** `clink config prompt show` ile aktif prompt
  modunu kontrol et, `oh-my-posh` olarak ayarlı olmalı.
- **fastfetch görünmüyor:** `clink info` ile script klasörünün doğru yolunu
  teyit et, `fastfetch.lua` dosyasının tam o klasörde ve doğru isimde
  (`.lua.txt` değil) olduğunu kontrol et. Ayrıca `where fastfetch` ile
  PATH'te olduğunu doğrula.
- **Hem PowerShell hem CMD'de farklı görünüm istiyorsan:** İkisi ayrı
  sistemler (PowerShell `$PROFILE`, CMD `Clink`), birini değiştirmek
  diğerini etkilemez.
