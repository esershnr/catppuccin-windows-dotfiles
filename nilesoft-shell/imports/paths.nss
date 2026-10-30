//==============================================================================
//  paths.nss  --  TEK KAYNAK: butun harici uygulama yollari burada tanimlanir.
//------------------------------------------------------------------------------
//  Bir uygulamayi tasidiginda / yeniden kurdugunda SADECE bu dosyayi degistir.
//  Menu dosyalarinin hicbirinde sabit yol (hardcoded path) yoktur.
//
//  Her menu ogesi io.file.exists() ile korunur:
//  uygulama yoksa oge menude hic gorunmez, olu/kirik girdi olusmaz.
//  (Eski konfigurasyonun problemi buydu: VS Code ve Notepad++ silinmisti
//   ama menude durmaya devam ediyordu.)
//==============================================================================

//--- Editorler / IDE -----------------------------------------------------------
$p_antigravity = 'C:\Users\esershnr\AppData\Local\Programs\Antigravity IDE\Antigravity IDE.exe'
$p_agy         = 'C:\Users\esershnr\AppData\Local\agy\bin\agy.exe'
$p_npp         = 'C:\Program Files\Notepad++\notepad++.exe'

//--- CLI ajanlari --------------------------------------------------------------
$p_claude      = 'C:\Users\esershnr\.local\bin\claude.exe'

//--- Hash dogrulama -----------------------------------------------------------
//  ContextMenuHashChecker kendini %LOCALAPPDATA% altina kurar ve sag tik
//  menusunu KENDI olusturur (HKCU\...Classes\*\shell\Checksum).
//  Buradaki yol sadece ikon icin; menu ogesi modify.nss'te duzenleniyor.
$p_hashcheck   = 'C:\Users\esershnr\AppData\Local\ContextMenuHashChecker\HashChecker.exe'

//--- Terminaller ---------------------------------------------------------------
$p_gitbash     = 'C:\Program Files\Git\git-bash.exe'
$p_git         = 'C:\Program Files\Git\cmd\git.exe'
$p_pwsh7       = 'C:\Program Files\PowerShell\7\pwsh.exe'   // kurulu degil, kurulunca otomatik gelir

//--- Araclar -------------------------------------------------------------------
$p_7zip        = 'C:\Program Files\7-Zip\7zFM.exe'

//--- Ozel ikonlar --------------------------------------------------------------
//  Kendi Catppuccin dotfiles setinden gelen SVG ikonlar.
//  Yeni ikon eklersen buraya bir satir ekle, sonra menude
//  image=image.svgf('@p_ikon_xxx') seklinde kullan.
//  @app.dir = Shell'in kendi klasoru. Sabit yol yazmiyoruz ki
//  Shell'i tasidiginda ikonlar da onunla birlikte gelsin.
$p_ikon_dir  = '@app.dir\icons'
$p_ikon_7zip = '@p_ikon_dir\7-zip.svg'

//==============================================================================
//  Kolaylik kisayollari
//------------------------------------------------------------------------------
//  @sel_dir : secili ogenin bulundugu klasor (dosya seciliyse ust klasoru,
//             bos alana tiklandiysa acik olan klasor). Terminal acmak icin.
//  @sel_one : secili tek ogenin tam yolu. Editorde acmak icin.
//==============================================================================
$sel_dir = @if(sel.count, sel.dir, sel.path)
$sel_one = @if(sel.count, sel.path, sel.dir)
