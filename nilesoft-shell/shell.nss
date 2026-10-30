//==============================================================================
//  shell.nss  --  Nilesoft Shell ana konfigurasyonu
//  esershnr  /  2026-08-28  /  sifirdan kuruldu
//------------------------------------------------------------------------------
//  KOK SEVIYE MENU DUZENI (yukaridan asagiya):
//     Terminal          -> imports/terminal.nss
//     Geliştirme        -> imports/develop.nss     (+ Antigravity registry ogesi)
//     Dosya İşlemleri   -> imports/file-manage.nss
//     Git               -> imports/goto.nss        (hizli klasor erisimi)
//     Araçlar           -> asagida tanimli, modify.nss doldurur
//     Sabitle / Kaldır  -> asagida tanimli
//     Diğer Seçenekler  -> asagida tanimli, modify.nss doldurur
//
//  DOSYA SORUMLULUKLARI:
//     paths.nss   Butun harici uygulama yollari. Bir sey tasindiysa
//                 SADECE bu dosyayi duzenle.
//     theme.nss   Gorunum + menunun yukari kaymasi hakkinda arastirma notlari.
//     modify.nss  Windows'un kendi ogelerini tasir/gizler. Antigravity
//                 registry cakismasi burada cozuluyor.
//     images.nss  Nilesoft'un hazir SVG ikon kutuphanesi (degistirilmedi).
//==============================================================================

settings
{
	priority = 1

	//  Shell'i yalnizca Explorer icinde calistir
	exclude.where = !process.is_explorer

	showdelay = 200

	//  Sistem ogelerinin degistirilmesine izin ver (modify.nss bunu kullanir)
	modify.remove.duplicate = 1

	tip.enabled = true
}

//==============================================================================
//  1. Temel: yollar, tema, ikonlar
//------------------------------------------------------------------------------
//  paths.nss EN BASTA gelmeli -- diger butun dosyalar onun degiskenlerini
//  ($p_antigravity, $sel_dir ...) kullaniyor.
//==============================================================================
import 'imports/paths.nss'
import 'imports/theme.nss'
import 'imports/images.nss'

//==============================================================================
//  2. Kok seviye menu ISKELETI
//------------------------------------------------------------------------------
//  Bu bos menuler once tanimlanir ki modify.nss sistem ogelerini
//  iclerine tasiyabilsin. Icine hicbir sey tasinmazsa menu otomatik
//  olarak gizlenir -- bos kutu gorunmez.
//==============================================================================
menu(mode="multiple" title='Araçlar' image=\uE194) { }

menu(mode="multiple" title='Sabitle / Kaldır' image=icon.pin) { }

menu(mode="multiple" title=title.more_options image=icon.more_options) { }

//==============================================================================
//  3. Sistem ogelerini yeniden duzenle
//------------------------------------------------------------------------------
//  ISKELETTEN SONRA gelmeli: modify kurallari yukarida tanimlanan
//  menulerin icine tasima yapiyor.
//==============================================================================
import 'imports/modify.nss'

//==============================================================================
//  4. Kendi menulerim
//==============================================================================
import 'imports/terminal.nss'
import 'imports/develop.nss'
import 'imports/file-manage.nss'
import 'imports/goto.nss'

//==============================================================================
//  5. Gorev cubugu
//==============================================================================
import 'imports/taskbar.nss'
