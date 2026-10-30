//==============================================================================
//  develop.nss  --  "Geliştirme" menusu
//------------------------------------------------------------------------------
//  ANTIGRAVITY NOTU:
//  Antigravity IDE'nin registry kayitlari (Directory / Background / Drive / *)
//  silinmedi -- modify.nss icinde bu menunun altina TASINIR.
//  Asagidaki kendi ogemiz ise registry kaydinin ulasamadigi durumlar
//  (coklu secim vb.) icin yedektir; ikisi ayni anda gorunurse
//  shell.nss'deki  modify.remove.duplicate=1  fazlaligi temizler.
//==============================================================================

menu(type='file|dir|drive|back'
     mode="multiple"
     title='Geliştirme'
     sep='top'
     image=\uE26E)
{
	//--- Editorler ------------------------------------------------------------
	//  NOT: "Antigravity IDE ile Ac" ogesi BURADA TANIMLI DEGIL.
	//  O oge Antigravity'nin kendi registry kaydindan geliyor ve
	//  modify.nss tarafindan bu menunun altina tasiniyor.
	//  Daha once burada ayrica bir "Antigravity IDE" ogesi vardi;
	//  ikisi ayni isi yaptigi icin mukerrer olan kaldirildi.

	//  SADECE dosya: Notepad++ klasor/surucu/bos-alan acamaz, o yuzden
	//  menunun type='file|dir|drive|back' kapsamini burada 'file'e daraltiyoruz.
	//  (Onceden klasore sag tiklayinca da "Notepad++" cikiyordu.)
	item(where=io.file.exists(p_npp)
	     type='file'
	     title='Notepad++'
	     image='@p_npp'
	     cmd='@p_npp'
	     args='"@sel.path"'
	     invoke="multiple")

	item(type='file' mode="single"
	     title='Not Defteri'
	     image
	     cmd='@sys.bin\notepad.exe'
	     args='"@sel.path"')

	//--- CLI ajanlari ---------------------------------------------------------
	//  agy.exe'de GOMULU IKON YOK (0 adet RT_GROUP_ICON kaynagi) --
	//  bu yuzden Windows jenerik exe ikonunu gosteriyordu.
	//  Ikonu IDE'nin exe'sinden aliyoruz, komut yine agy.exe'yi calistiriyor.
	item(where=io.file.exists(p_agy)
	     title='Antigravity CLI'
	     sep='before'
	     image='@p_antigravity'
	     cmd='cmd.exe'
	     args='/K TITLE Antigravity CLI & PUSHD "@sel_dir" & "@p_agy"')

	item(where=io.file.exists(p_claude)
	     title='Claude CLI'
	     image='@p_claude'
	     cmd='cmd.exe'
	     args='/K TITLE Claude CLI & PUSHD "@sel_dir" & "@p_claude"')

	//--- Git: sadece bir git deposu icindeysek gorunur ------------------------
	menu(where=io.file.exists(p_git) && io.directory.exists(path.join(sel_dir, '.git'))
	     title='Git'
	     sep='before'
	     image=\uE17A)
	{
		item(title='status' image=\uE149
		     cmd='cmd.exe' args='/K PUSHD "@sel_dir" & "@p_git" status')
		item(title='log (grafik)'
		     cmd='cmd.exe' args='/K PUSHD "@sel_dir" & "@p_git" log --oneline --graph --decorate -30')
		item(title='diff'
		     cmd='cmd.exe' args='/K PUSHD "@sel_dir" & "@p_git" diff')
		separator
		item(title='pull' image=\uE11F
		     cmd='cmd.exe' args='/K PUSHD "@sel_dir" & "@p_git" pull')
		item(title='fetch --all --prune'
		     cmd='cmd.exe' args='/K PUSHD "@sel_dir" & "@p_git" fetch --all --prune')
		separator
		item(title='branch -a'
		     cmd='cmd.exe' args='/K PUSHD "@sel_dir" & "@p_git" branch -a')
		item(title='stash list'
		     cmd='cmd.exe' args='/K PUSHD "@sel_dir" & "@p_git" stash list')
	}

	//--- Git deposu OLMAYAN klasorde: init ------------------------------------
	item(where=io.file.exists(p_git) && type.back && !io.directory.exists(path.join(sel_dir, '.git'))
	     title='Git deposu başlat  (git init)'
	     sep='before'
	     image=\uE143
	     cmd='cmd.exe'
	     args='/K PUSHD "@sel_dir" & "@p_git" init')
}
