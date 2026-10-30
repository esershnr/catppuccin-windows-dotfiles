//==============================================================================
//  goto.nss  --  "Git" menusu  (hizli klasor / ayar erisimi)
//------------------------------------------------------------------------------
//  Eski konfigurasyonda bu modul de yorum satiriydi.
//  "Git" burada FIIL anlamindadir (git = go to). Git surum kontrolu
//  komutlari "Gelistirme > Git" altindadir.
//==============================================================================

menu(type='*'
     where=window.is_taskbar || sel.count || type.back
     mode=mode.multiple
     title='Git'
     sep=sep.both
     image=\uE14A)
{
	//--- Sik kullandigim klasorler -------------------------------------------
	menu(title='Çalışma Klasörlerim' image=\uE1F4)
	{
		item(where=io.directory.exists('C:\Dev')        title='C:\Dev'        image=inherit cmd='C:\Dev')
		item(where=io.directory.exists('C:\Dev\Labs')   title='C:\Dev\Labs'   image=inherit cmd='C:\Dev\Labs')
		item(where=io.directory.exists('C:\Tools')      title='C:\Tools'      image=inherit cmd='C:\Tools')
		item(where=io.directory.exists('C:\Tools\Apps') title='C:\Tools\Apps' image=inherit cmd='C:\Tools\Apps')
	}

	//--- Kullanici klasorleri -------------------------------------------------
	menu(title='Kullanıcı' image=\uE1F4)
	{
		item(title='Masaüstü'   image=inherit cmd=user.desktop)
		item(title='İndirilenler' image=inherit cmd=user.downloads)
		item(title='Belgeler'   image=inherit cmd=user.documents)
		item(title='Resimler'   image=inherit cmd=user.pictures)
		separator
		item(title='Profil'     image=inherit cmd=user.dir)
		item(title='AppData'    image=inherit cmd=user.appdata)
		item(title='Başlat Menüsü' image=inherit cmd=user.startmenu)
		item(title='Temp'       image=inherit cmd=user.temp)
	}

	//--- Sistem klasorleri ----------------------------------------------------
	menu(title='Sistem' image=\uE1F4)
	{
		item(title='Windows'          image=inherit cmd=sys.dir)
		item(title='System32'         image=inherit cmd=sys.bin)
		item(title='Program Files'    image=inherit cmd=sys.prog)
		item(title='Program Files x86' image=inherit cmd=sys.prog32)
		item(title='ProgramData'      image=inherit cmd=sys.programdata)
		item(title='Kullanıcılar'     image=inherit cmd=sys.users)
		separator
		item(title='Uygulamalar'      image=inherit cmd='shell:appsfolder')
	}

	separator

	//--- Sistem araclari ------------------------------------------------------
	item(title='Denetim Masası' image=\uE0F3 cmd='shell:::{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}')
	item(title='Tüm Denetim Masası Öğeleri' image=\uE0F3 cmd='shell:::{ED7BA470-8E54-465E-825C-99712043E01C}')
	item(title='Çalıştır' image=\uE14B cmd='shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}')

	//--- Windows Ayarlari -----------------------------------------------------
	menu(where=sys.ver.major >= 10 title='Ayarlar' sep=sep.before image=\uE0F3)
	{
		item(title='Ayarlar (ana sayfa)' image=inherit cmd='ms-settings:')
		item(title='Sistem hakkında'     image=inherit cmd='ms-settings:about')
		item(title='Sistem bilgisi'      image=inherit cmd-line='/K systeminfo')
		separator
		item(title='Windows Update'      image=inherit cmd='ms-settings:windowsupdate')
		item(title='Windows Defender'    image=inherit cmd='ms-settings:windowsdefender')
		item(title='USB'                 image=inherit cmd='ms-settings:usb')

		menu(title='Uygulamalar' image=inherit)
		{
			item(title='Uygulamalar ve özellikler' image=inherit cmd='ms-settings:appsfeatures')
			item(title='Varsayılan uygulamalar'    image=inherit cmd='ms-settings:defaultapps')
			item(title='İsteğe bağlı özellikler'   image=inherit cmd='ms-settings:optionalfeatures')
			item(title='Başlangıç uygulamaları'    image=inherit cmd='ms-settings:startupapps')
		}

		menu(title='Kişiselleştirme' image=inherit)
		{
			item(title='Kişiselleştirme' image=inherit cmd='ms-settings:personalization')
			item(title='Arka plan'       image=inherit cmd='ms-settings:personalization-background')
			item(title='Renkler'         image=inherit cmd='ms-settings:colors')
			item(title='Temalar'         image=inherit cmd='ms-settings:themes')
			item(title='Kilit ekranı'    image=inherit cmd='ms-settings:lockscreen')
			item(title='Başlat'          image=inherit cmd='ms-settings:personalization-start')
			item(title='Görev çubuğu'    image=inherit cmd='ms-settings:taskbar')
		}

		menu(title='Ağ' image=inherit)
		{
			item(title='Durum'      image=inherit cmd='ms-settings:network-status')
			item(title='Ethernet'   image=inherit cmd='ms-settings:network-ethernet')
			item(title='Bağlantılar' image=inherit cmd='shell:::{7007ACC7-3202-11D1-AAD2-00805FC1270E}')
		}
	}
}
