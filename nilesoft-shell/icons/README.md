# Nilesoft Shell'e yeni ikon ekleme

Bu klasör menüde kullanılan özel SVG ikonları tutar. Shell çalışırken buradan
okur — `paths.nss` içinde dizin `@app.dir\icons` olarak tanımlıdır, yani Shell
klasörünü taşırsan ikonlar da onunla birlikte gider.

---

## Önce bilmen gereken tek kural

**Nilesoft, fazlalık içeren SVG'leri sessizce reddeder.** Hata vermez,
`shell.log`'a bir şey yazmaz — ikon sadece görünmez. Kabul ettiği biçim,
Shell'in kendi `imports/images.nss` dosyasındaki üsluptur:

```xml
<svg viewBox="0 0 512 512"><path fill="#ffffff" d="..."/><path fill="#11111b" d="..."/></svg>
```

Yani: `viewBox` kalır, **gerisi silinir**, her şekilde **açık `fill`** olur.

Reddedilme sebebi olan tipik fazlalıklar:

| Fazlalık | Örnek |
|---|---|
| `xmlns` | `<svg xmlns="http://www.w3.org/2000/svg" ...>` |
| `width` / `height` | `width="1em" height="1em"` |
| `<title>` / `<desc>` | `<title xmlns="">7-zip</title>` |
| Eksik `fill` | `<path d="..."/>` — SVG varsayılanı siyahtır, koyu menüde kaybolur |

Bu dört madde, `7-zip.svg`'nin ilk denemede neden görünmediğinin cevabıdır.

---

## Adım adım

### 1. SVG'yi temizle

```bash
python svg-temizle.py kaynak.svg cikti.svg
```

Script fazlalıkları siler, eksik `fill`'leri tamamlar, tek satıra indirir ve
ne yaptığını raporlar:

```
yapilanlar:
   - <title> silindi
   - <svg> icinden xmlns silindi
   - <svg> icinden width silindi
   - <svg> icinden height silindi
   - 1 sekle fill="#000000" eklendi (SVG varsayilani siyahtir)

kullanilan renkler: #000000, #fff
```

Renkleri aynı anda Catppuccin paletine çevirmek istersen:

```bash
python svg-temizle.py kaynak.svg cikti.svg --renk fff=ffffff,000000=11111b
```

### 2. Dosyayı bu klasöre koy

```
icons/yeni-ikon.svg
```

### 3. `paths.nss`'e bir satır ekle

```nss
$p_ikon_yeni = '@p_ikon_dir\yeni-ikon.svg'
```

### 4. Menüde kullan

```nss
item(title='Bir şey' image=image.svgf(p_ikon_yeni) cmd='...')
```

Dosya kaybolursa gömülü bir glyph'e düşsün istiyorsan:

```nss
image=@if(io.file.exists(p_ikon_yeni), image.svgf(p_ikon_yeni), \uE0AA)
```

> Bu fallback **yalnızca dosya yoksa** devreye girer. Dosya var ama
> çizilemiyorsa koşul yine "var" der ve ikon boş çıkar — çizim hatası için
> Nilesoft'ta yakalanabilir bir sinyal yok. Yani fallback taşınma/silinme
> senaryosunu korur, bozuk SVG'yi değil.

### 5. Kur ve dene

```bash
cp icons/*.svg "C:/Tools/Apps/NileSoft-Shell_portable/icons/"
```

Register etmeye gerek yok; Explorer'ı yeniden başlatmak yeterli.

---

## Catppuccin Mocha paleti

Menü teması bu renkleri kullanıyor, ikonları da bunlara uydurmak tutarlı durur:

| Renk | Kod | Nerede |
|---|---|---|
| Base | `#1e1e2e` | menü arka planı |
| Crust | `#11111b` | en koyu, ikon içi kontrast |
| Surface0 | `#313244` | ayraç |
| Surface1 | `#45475a` | seçili satır zemini |
| Text | `#cdd6f4` | normal yazı |
| Mauve | `#cba6f7` | vurgu, kenarlık, seçili yazı |

Bir ikonun hem açık hem koyu temada okunur olması gerekiyorsa Nilesoft'un
kendi `icon.*` setini tercih et — onlar temaya göre kendiliğinden renk
değiştirir, senin SVG'lerin sabit renklidir.

---

## İkon nereden gelebilir — dört kaynak

```nss
image=icon.copy_path                    // images.nss'teki hazır set (temaya uyar)
image=\uE0AA                            // Shell'in gömülü glyph'i, 0xE001-0xE29C
image=image.mdl(\uE8B7)                 // Windows Segoe MDL2 / Fluent fontu
image=image.svgf(p_ikon_yeni)           // kendi SVG dosyamız
image='@p_antigravity'                  // bir exe/dll/ico'nun kendi ikonu
```


Shell'in gömülü 668 glyph'i: <https://nilesoft.org/glyphs>

---

## İkon görünmüyorsa

1. **`shell.log`'a bak** — `C:\Tools\Apps\NileSoft-Shell_portable\shell.log`.
   Ayrıştırma hatası varsa satır ve sütun numarasıyla yazar. Hata yoksa
   konfigürasyon yüklenmiştir ve sorun SVG'dedir.

2. **Test menüsü kur.** Aynı ikonu farklı yöntemlerle yükleyip hangisinin
   tuttuğunu görmek en hızlı yol:

   ```nss
   menu(type='file|dir|back' title='IKON TESTI' image=\uE0AA)
   {
       item(title='A - orijinal'  image=image.svgf('C:\yol\orijinal.svg'))
       item(title='B - temiz'     image=image.svgf('C:\yol\temiz.svg'))
       item(title='C - gömülü'    image=image.svg('<svg viewBox="0 0 16 16">...</svg>'))
       item(title='D - kontrol'   image=\uE0AA)
   }
   ```

   D görünmüyorsa menünün kendisinde sorun var. D görünüp diğerleri
   görünmüyorsa sorun SVG yükleme tarafında.

3. **`image.res()` kullanma.** O sadece exe/dll/ico okur, SVG okumaz.
   SVG için `image.svgf()` (dosyadan) veya `image.svg()` (gömülü) kullan.

---

## Kayıtlı ikonlar

| Dosya | Nerede kullanılıyor |
|---|---|
| `7-zip.svg` | `modify.nss` — 7-Zip menüsü (beyaz zemin, orijinal logo) |
| `7-zip-mocha.svg` | Alternatif: mor zeminli Catppuccin varyantı |
