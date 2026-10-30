//==============================================================================
//  taskbar.nss  --  Gorev cubugu sag tik menusu
//------------------------------------------------------------------------------
//  Shell yonetimi:  SHIFT + gorev cubuguna sag tikla
//  Konfigurasyonu duzenlemek icin en hizli yol budur.
//==============================================================================

//--- Shell'in kendi yonetim menusu (SHIFT ile) --------------------------------
menu(type="taskbar" vis=key.shift() || key.lbutton() pos=0 title=app.name image=\uE249)
{
	item(title='Konfigürasyonu düzenle' image=\uE10A cmd='"@app.cfg"')
	item(title='Konfigürasyon klasörü'  image=\uE0E8 cmd='"@app.dir"')
	item(title='Shell yöneticisi'       image=\uE0F3 admin cmd='"@app.exe"')
	separator
	item(title="Sürüm\t" + @app.ver vis=label col=1)
	item(title='Belgeler' image=\uE1C4 cmd='https://nilesoft.org/docs')
}

//--- Normal gorev cubugu menusu ------------------------------------------------
menu(where=@(this.count == 0) type='taskbar' image=icon.settings expanded=true)
{
	menu(title='Uygulamalar' image=\uE254)
	{
		item(where=io.file.exists(p_antigravity) title='Antigravity IDE' image='@p_antigravity' cmd='@p_antigravity')
		item(where=io.file.exists(p_npp)  title='Notepad++'   image='@p_npp'   cmd='@p_npp')
		separator
		item(where=io.file.exists(p_7zip)   title='7-Zip'                image='@p_7zip'   cmd='@p_7zip')
		separator
		item(title='Hesap Makinesi' image=\uE1E7 cmd='calc.exe')
		item(title='Paint'          image=\uE116 cmd='mspaint')
		item(title='Kayıt Defteri'  image=\uE0F3 admin cmd='regedit.exe')
	}

	menu(title='Pencereler' image=\uE1FB)
	{
		item(title='Basamakla'          cmd=command.cascade_windows)
		item(title='Yığılmış göster'    cmd=command.Show_windows_stacked)
		item(title='Yan yana göster'    cmd=command.Show_windows_side_by_side)
		separator
		item(title='Tümünü simge durumuna küçült' cmd=command.minimize_all_windows)
		item(title='Tümünü geri yükle'  cmd=command.restore_all_windows)
	}

	item(title='Masaüstünü göster' image=icon.desktop cmd=command.toggle_desktop)
	item(title='Ayarlar'      image=icon.settings(auto, image.color1) cmd='ms-settings:')
	item(title='Görev Yöneticisi' sep=both image=icon.task_manager cmd='taskmgr.exe')
	item(title='Görev çubuğu ayarları' sep=both image=inherit cmd='ms-settings:taskbar')
	item(vis=key.shift() title="Explorer yeniden başlat" cmd=command.restart_explorer)
}
