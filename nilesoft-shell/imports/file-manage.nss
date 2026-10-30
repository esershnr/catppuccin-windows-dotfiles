//==============================================================================
//  file-manage.nss  --  "Dosya İşlemleri" menusu
//------------------------------------------------------------------------------
//  Eski konfigurasyonda bu modul yorum satiriydi, hic aktif degildi.
//  En cok ise yarayan kisim "Yolu kopyala" ve "Sahipligi al".
//==============================================================================

menu(where=sel.count>0 || type.back
     type='file|dir|drive|namespace|back'
     mode="multiple"
     title='Dosya İşlemleri'
     image=\uE253)
{
	//--- Yol kopyalama --------------------------------------------------------
	menu(separator="after" title='Yolu kopyala' image=icon.copy_path)
	{
		item(where=sel.count > 1
		     title='Seçili @sel.count öğeyi kopyala'
		     cmd=command.copy(sel(false, "\n")))

		item(mode="single" title=@sel.path tip=sel.path cmd=command.copy(sel.path))
		separator
		item(mode="single" where=@sel.parent.len>3
		     title='Üst klasör:  @sel.parent'
		     cmd=@command.copy(sel.parent))
		separator
		item(mode="single" type='file|dir|back.dir'
		     title='Dosya adı:  @sel.file.name'
		     cmd=command.copy(sel.file.name))
		item(mode="single" type='file' where=sel.file.len != sel.file.title.len
		     title='Uzantısız ad:  @sel.file.title'
		     cmd=command.copy(sel.file.title))
		item(mode="single" type='file' where=sel.file.ext.len>0
		     title='Uzantı:  @sel.file.ext'
		     cmd=command.copy(sel.file.ext))
	}

	//--- Uzanti degistir ------------------------------------------------------
	item(mode="single" type="file"
	     title='Uzantıyı değiştir'
	     image=\uE0B5
	     cmd=if(input("Uzantıyı değiştir", "Yeni uzantıyı yazın"),
	            io.rename(sel.path, path.join(sel.dir, sel.file.title + "." + input.result))))

	//--- Secim ----------------------------------------------------------------
	menu(separator="after" image=\uE290 title='Seçim')
	{
		item(title='Tümünü seç'    image=icon.select_all        cmd=command.select_all)
		item(title='Seçimi tersle' image=icon.invert_selection  cmd=command.invert_selection)
		item(title='Seçimi kaldır' image=icon.select_none       cmd=command.select_none)
	}

	//--- Sahiplik -------------------------------------------------------------
	item(type='file|dir|back.dir|drive'
	     title='Sahipliği al'
	     tip=["Bu dosya/klasorun sahipligini alir ve tam yetki verir. Yonetici gerekir.", tip.warning, 1.0]
	     image=[\uE194,#f00] admin
	     cmd args='/K takeown /f "@sel.path" @if(sel.type==1,null,"/r /d y") && icacls "@sel.path" /grant *S-1-5-32-544:F @if(sel.type==1,"/c /l","/t /c /l /q")')

	separator

	//--- Goster / Gizle -------------------------------------------------------
	menu(title='Göster / Gizle' image=icon.show_hidden_files)
	{
		item(title='Sistem dosyaları'   image=inherit                    cmd='@command.togglehidden')
		item(title='Dosya uzantıları'   image=icon.show_file_extensions  cmd='@command.toggleext')
	}

	//--- Oznitelikler ---------------------------------------------------------
	menu(type='file|dir|back.dir' mode="single" title='Öznitelikler' image=icon.properties)
	{
		$atrr = io.attributes(sel.path)

		item(title='Gizli'        checked=io.attribute.hidden(atrr)
		     cmd args='/c ATTRIB @if(io.attribute.hidden(atrr),"-","+")H "@sel.path"' window=hidden)
		item(title='Sistem'       checked=io.attribute.system(atrr)
		     cmd args='/c ATTRIB @if(io.attribute.system(atrr),"-","+")S "@sel.path"' window=hidden)
		item(title='Salt okunur'  checked=io.attribute.readonly(atrr)
		     cmd args='/c ATTRIB @if(io.attribute.readonly(atrr),"-","+")R "@sel.path"' window=hidden)
		item(title='Arşiv'        checked=io.attribute.archive(atrr)
		     cmd args='/c ATTRIB @if(io.attribute.archive(atrr),"-","+")A "@sel.path"' window=hidden)
		separator
		item(title='Oluşturulma'  keys=io.dt.created(sel.path, 'y/m/d')  vis=label)
		item(title='Değiştirilme' keys=io.dt.modified(sel.path, 'y/m/d') vis=label)
		item(title='Erişim'       keys=io.dt.accessed(sel.path, 'y/m/d') vis=label)
	}

	//--- DLL kaydi ------------------------------------------------------------
	menu(mode="single" type='file' find='.dll|.ocx' separator="before"
	     title='Sunucu kaydı' image=\uEA86)
	{
		item(title='Kaydet'       admin cmd='regsvr32.exe' args='@sel.path.quote'    invoke="multiple")
		item(title='Kaydı kaldır' admin cmd='regsvr32.exe' args='/u @sel.path.quote' invoke="multiple")
	}

	//--- Bos alanda: yeni dosya / klasor --------------------------------------
	menu(mode="single" type='back' expanded=true)
	{
		menu(separator="before" title='Yeni Klasör' image=icon.new_folder)
		{
			item(title='Tarih-saat adıyla' cmd=io.dir.create(sys.datetime("ymdHMSs")))
			item(title='GUID adıyla'       cmd=io.dir.create(str.guid))
		}

		menu(title='Yeni Dosya' image=icon.new_file)
		{
			$dt = sys.datetime("ymdHMSs")
			item(title='TXT'  cmd=io.file.create('@(dt).txt',  'Merhaba Dünya!'))
			item(title='MD'   cmd=io.file.create('@(dt).md',   '# Başlık'))
			item(title='JSON' cmd=io.file.create('@(dt).json', '{}'))
			item(title='XML'  cmd=io.file.create('@(dt).xml',  '<root></root>'))
			item(title='HTML' cmd=io.file.create('@(dt).html', "<html>\n\t<head>\n\t</head>\n\t<body>\n\t</body>\n</html>"))
		}
	}

	item(where=!wnd.is_desktop
	     title='Klasör seçenekleri'
	     image=icon.folder_options
	     cmd=command.folder_options)
}
