Usage
-------------

Move catppuccin-mocha.xml to NotePad++ theme directory (default: %AppData%\Notepad++\themes if it's not portable).
Select the desired editor theme in Settings > Style Configurator
Modify the Global Styles > Default Style to pick a typeface and adjust default font size to your liking

Non Editor Area Guide
-------------

• Preferences > Editing 1
	Apply custom color to selected text foreground
• Preferences > Editing 2
	EOL (CRLF) > Custom Color
	Non-Printing Characters > Appearance > Custom Color
	Non-Printing Characters > Apply Appearance to C0, C1, EOL
• Preferences > Toolbar > Pick an icon theme
	Pick "Complete" or "Partial" Colorization
	Color choice > Custom
• Preferences > Margins/Border/Edge > Pick what you like

• You can theme the UI elements by modifying a line in the config file (Default: %AppData%/Notepad++/config.xml)
	Replace the line beginning with <GUIConfig name="DarkMode" ...> with the code below.
	
CODE: 
------------
<GUIConfig name="DarkMode" enable="yes" colorTone="32" customColorTop="3022366" customColorMenuHotTrack="5916485" customColorActive="2431000" customColorMain="1773841" customColorError="11045875" customColorText="16045773" customColorDarkText="14598842" customColorDisabledText="13151654" customColorLinkText="16430217" customColorEdge="10257535" customColorHotEdge="11704723" customColorDisabledEdge="8810604" enableWindowsMode="no" darkThemeName="catppuccin-mocha.xml" darkToolBarIconSet="0" darkTbFluentColor="9" darkTbFluentCustomColor="16230091" darkTbFluentMono="no" darkTabIconSet="2" darkTabUseTheme="yes" lightThemeName="catppuccin-mocha.xml" lightToolBarIconSet="0" lightTbFluentColor="9" lightTbFluentCustomColor="15677832" lightTbFluentMono="no" lightTabIconSet="2" lightTabUseTheme="yes" />
	