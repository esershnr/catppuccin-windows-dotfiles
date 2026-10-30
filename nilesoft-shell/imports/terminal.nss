//==============================================================================
//  terminal.nss  --  "Terminal" menusu
//------------------------------------------------------------------------------
//  SHIFT basili tutarak tikla  ->  yonetici olarak calisir.
//  Kurulu olmayan terminaller menude hic gorunmez (io.file.exists korumasi).
//  Yollar imports/paths.nss icinde tanimlidir.
//==============================================================================

menu(type='*'
     where=(sel.count || type.back || wnd.is_taskbar || wnd.is_edit)
     title='Terminal'
     sep='top'
     image=icon.run_with_powershell)
{
	$tip_admin = ["\xE1A7 Yonetici olarak calistirmak icin SHIFT tusuna basili tutun", tip.warning, 1.0]
	$as_admin  = key.shift() || key.rbutton()

	item(title='Komut İstemi'
	     tip=tip_admin admin=as_admin image
	     cmd='cmd.exe'
	     args='/K TITLE Komut İstemi &ver& PUSHD "@sel_dir"')

	item(title='Windows PowerShell'
	     tip=tip_admin admin=as_admin image
	     cmd='powershell.exe'
	     args='-noexit -command Set-Location -LiteralPath "@sel_dir"')

	item(where=io.file.exists(p_pwsh7)
	     title='PowerShell 7'
	     tip=tip_admin admin=as_admin image='@p_pwsh7'
	     cmd='@p_pwsh7'
	     args='-NoExit -Command Set-Location -LiteralPath "@sel_dir"')

	item(where=package.exists("WindowsTerminal")
	     title='Windows Terminal'
	     tip=tip_admin admin=as_admin
	     image='@package.path("WindowsTerminal")\WindowsTerminal.exe'
	     cmd='wt.exe'
	     args='-d "@sel_dir"')

	item(where=io.file.exists(p_gitbash)
	     title='Git Bash'
	     sep='before'
	     tip=tip_admin admin=as_admin image='@p_gitbash'
	     cmd='@p_gitbash'
	     args='--cd="@sel_dir"')
}
