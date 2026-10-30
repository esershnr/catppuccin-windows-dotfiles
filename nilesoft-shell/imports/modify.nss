//==============================================================================
//  modify.nss  --  Windows'un KENDI menu ogelerini yeniden duzenler
//------------------------------------------------------------------------------
//  Buradaki kurallar yeni oge OLUSTURMAZ; registry'den / kabuk uzantilarindan
//  gelen mevcut ogeleri tasir, gizler, ikonlarini degistirir.
//
//  Sistemde GERCEKTEN kurulu olanlara gore yazildi:
//    VAR  : Antigravity IDE, 7-Zip, Git, File Converter, Windows Terminal
//    YOK  : VS Code, Notepad++ (kurulu degil -- portable), PowerToys, Warp
//  Eski konfigurasyondaki VS Code / Notepad++ / PowerToys / Warp kurallari
//  bu yuzden kaldirildi (olu kurallardi).
//==============================================================================


//------------------------------------------------------------------------------
//  1) ANTIGRAVITY IDE  --  ASIL COZULEN CAKISMA
//------------------------------------------------------------------------------
//  Antigravity kurulumu su 4 registry anahtarini olusturmustu:
//     HKCU\Software\Classes\Directory\shell\Antigravity
//     HKCU\Software\Classes\Directory\Background\shell\Antigravity
//     HKCU\Software\Classes\Drive\shell\Antigravity
//     HKCU\Software\Classes\*\shell\Antigravity          <-- HER dosyada
//
//  Sonuc: "Antigravity IDE ile Ac" kok seviyede, klasorde + bos alanda +
//  surucude + her tek dosyada (jpg, mp3 dahil) goruntuleniyordu.
//
//  Registry'e DOKUNULMADI (Explorer disi programlarda da calismaya devam
//  etsin diye). Bunun yerine oge burada "Gelistirme" menusunun altina
//  tasiniyor -- kok seviye temiz kaliyor, islevsellik aynen duruyor.
//------------------------------------------------------------------------------
modify(find="*Antigravity*" menu='Geliştirme')


//------------------------------------------------------------------------------
//  2) Terminal  --  Git'in kabuk ogeleri
//------------------------------------------------------------------------------
//  HKLM\...\Directory\shell altinda git_shell ve git_gui var.
//  GERCEK baslıklari (registry'den dogrulandi):
//     git_shell -> "Open Git Ba&sh here"
//     git_gui   -> "Open Git &GUI here"
//
//  DIKKAT: Basliklarda Windows kisayol-tusu isareti (&) KELIME ICINDE geciyor.
//  Bu yuzden "*Git Bash*" kalibi ESLESMEZ ("Ba&sh" yaziyor).
//  Onun yerine & isaretinden ONCEKI kisma gore eslestiriyoruz.
//------------------------------------------------------------------------------
modify(find="Open Git*" menu='Terminal')


//------------------------------------------------------------------------------
//  3) Geliştirme  --  varsa diger editorler
//------------------------------------------------------------------------------
//  Notepad++ winget ile kurulu (bootstrap): kendi "Edit with Notepad++" kaydi
//  asagidaki kuralla Gelistirme altina tasinir; develop.nss'teki oge de ayrica
//  var (paths.nss'teki p_npp).
//------------------------------------------------------------------------------
modify(find="*Notepad++*|*Not Defteri ile Düzenle*|*Edit with*|*Visual Studio Code*|*Code ile Aç*" menu='Geliştirme')


//------------------------------------------------------------------------------
//  4) Araçlar  --  yardimci programlar
//------------------------------------------------------------------------------
modify(find="*File Converter*|*Dönüştür*"                          menu='Araçlar')
modify(find="*kalıcı sil*|*Permanently delete*"                    menu='Araçlar')
modify(find="*PowerRename*|*Locksmith*|*Dosya Çilingiri*|*Unlock with*"  menu='Araçlar')
modify(find="*Resize*|*Yeniden boyutlandır*"                       menu='Araçlar')

//  7-Zip: kendi alt menusu zaten duzenli, kok seviyede kalsin -- sadece ikon
//  Ikon kendi dotfiles setimizden geliyor:
//    C:\Dev\Dotfiles\catppuccin-windows-dotfiles\icons\svg\7-zip.svg
//  Dosya bulunamazsa veya cizilemezse yedek olarak gomulu glyph kullanilir
//  (fermuarli klasor). Yedege donmek icin alttaki satiri yorum yap,
//  ustteki yorumu ac.
//  Ikon: kendi SVG'miz, yedegi gomulu glyph.
//
//  TESHIS SONUCU: image.svgf() calisiyor, ama SVG'nin Nilesoft'un kendi
//  images.nss uslubunda olmasi gerekiyor -- xmlns / width / height /
//  <title> etiketleri varsa dosya SESSIZCE cizilmiyor.
//  Dotfiles'taki orijinal 7-zip.svg'de ucu de vardi; icons/7-zip.svg
//  bunlardan arindirilmis surumdur.
//
//  @if fallback SADECE dosya yoksa devreye girer (cizim hatasini yakalamaz).
modify(find="7-Zip" image=@if(io.file.exists(p_ikon_7zip), image.svgf(p_ikon_7zip), \uE0AA))

//  7-Zip'in kendi CRC SHA alt menusu en alta
modify(find="*Sağlama Toplamları*|*CRC SHA*" image=\uE10B pos="bottom")


//------------------------------------------------------------------------------
//  4b) HASH DOGRULAMA  --  ContextMenuHashChecker
//------------------------------------------------------------------------------
//  Kaynak : C:\Dev\Repos\ContextMenuHashChecker
//  Kurulum: %LOCALAPPDATA%\ContextMenuHashChecker\HashChecker.exe
//
//  Bu program sag tik menusunu KENDI kuruyor:
//     HKCU\Software\Classes\*\shell\Checksum
//       MUIVerb     = "Checksum"
//       SubCommands = ""          <- basamakli (cascading) menu
//       shell\01MD5 ... 08CRC32  <- 8 algoritma alt ogesi
//
//  ONCEKI KURALIM NEDEN TUTMADI:
//  "*Checksums*" yazmistim (COGUL). Gercek MUIVerb "Checksum" (TEKIL).
//  Kalip hicbir zaman eslesmedi, oge duzenlenmeden kok seviyede kaldi.
//  Asagidaki kalip artik tekil ada gore eslesiyor.
//------------------------------------------------------------------------------
modify(find="Checksum" menu='Araçlar' image=\uE10B)


//------------------------------------------------------------------------------
//  5) Diğer Seçenekler  --  kalabaligi tek catida topla
//------------------------------------------------------------------------------
modify(mode=mode.multiple
	where=this.id(
		id.share,
		id.send_to,
		id.create_shortcut,
		id.set_as_desktop_background,
		id.rotate_left,
		id.rotate_right,
		id.map_network_drive,
		id.disconnect_network_drive,
		id.format,
		id.eject,
		id.give_access_to,
		id.include_in_library,
		id.print
	)
	pos=1 menu=title.more_options)

//  id.share tutmazsa isimle yakala
modify(find="Paylaş|Share" menu=title.more_options)


//------------------------------------------------------------------------------
//  6) Gereksiz ogeleri kaldir
//------------------------------------------------------------------------------
modify(find="*Hızlı erişime sabitle*|*Pin to Quick access*|*Sık kullanılanlara ekle*" vis=vis.remove)

//  NOT: "Visual Studio ile Aç" icin gizleme kurali YOK. O oge registry'den
//  (HKLM\...\Directory\{,Background\}shell\AnyCode -> MSEnv\VSLauncher.exe)
//  geliyordu; tam IDE kaldirilinca olu kalmisti. AnyCode anahtarlari
//  2026-09-03'te silindi, oge kaynagindan kalkti -- NSS tarafinda is yok.


//------------------------------------------------------------------------------
//  7) Sistem ogelerine eksik ikon ekle
//------------------------------------------------------------------------------
//  "Geri Al" (ve varsa "Yinele") tek basina ikonsuz kaliyordu -- Nilesoft
//  bu iki ogeyi otomatik ikon setine katmiyor. images.nss'te SVG'leri
//  (@undo / @redo) hazir, sadece baglamak gerek. Hem id hem baslikla
//  yakaliyoruz (id tutmazsa Turkce/Ingilizce baslik yedegi).
modify(where=this.id==id.undo  image=image.undo)
modify(where=this.id==id.redo  image=image.redo)
modify(find="Geri Al*|Undo*"   image=image.undo)
modify(find="Yinele*|Redo*"    image=image.redo)


//------------------------------------------------------------------------------
//  8) Özellikler her zaman en altta
//------------------------------------------------------------------------------
//  Bu kural en SONDA olmali: yukaridaki pos="bottom" kurallarindan sonra
//  calisir, boylece Ozellikler en alta, Saglama Toplamlari onun ustune oturur.
//------------------------------------------------------------------------------
modify(where=this.id==id.properties pos="bottom")
