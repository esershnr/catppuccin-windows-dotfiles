local utils = require('mp.utils')
local msg = require('mp.msg')

local themes = {
    {
        id = 'catppuccin-mocha',
        title = '🐱 Catppuccin Mocha',
        hint = 'Koyu Mor & Pembe',
        color = 'foreground=cba6f7,foreground_text=11111b,background=1e1e2e,background_text=cdd6f4,curtain=181825,success=a6e3a1,error=f38ba8'
    },
    {
        id = 'catppuccin-macchiato',
        title = '🌊 Catppuccin Macchiato',
        hint = 'Koyu Mavi & Gri',
        color = 'foreground=8aadf4,foreground_text=181926,background=24273a,background_text=cad3f5,curtain=1e2030,success=a6da95,error=ed8796'
    },
    {
        id = 'tokyo-night',
        title = '🌃 Tokyo Night',
        hint = 'Gece Mavisi & Mor',
        color = 'foreground=7aa2f7,foreground_text=1a1b26,background=1a1b26,background_text=a9b1d6,curtain=16161e,success=9ece6a,error=f7768e'
    },
    {
        id = 'nord',
        title = '❄️ Nord',
        hint = 'Kutup Mavisi & Buz',
        color = 'foreground=88c0d0,foreground_text=2e3440,background=2e3440,background_text=eceff4,curtain=242933,success=a3be8c,error=bf616a'
    },
    {
        id = 'dracula',
        title = '🧛 Dracula',
        hint = 'Canlı Mor & Pembe',
        color = 'foreground=bd93f9,foreground_text=282a36,background=282a36,background_text=f8f8f2,curtain=21222c,success=50fa7b,error=ff5555'
    },
    {
        id = 'catppuccin-latte',
        title = '🍦 Catppuccin Latte',
        hint = 'Açık Beyaz & Mavi',
        color = 'foreground=1e66f5,foreground_text=ffffff,background=eff1f5,background_text=4c4f69,curtain=e6e9ef,success=40a02b,error=d20f39'
    },
    {
        id = 'default-white',
        title = '⚪ Default White',
        hint = 'Klasik Beyaz',
        color = 'foreground=ffffff,foreground_text=000000,background=000000,background_text=ffffff,curtain=111111,success=a5e075,error=ff616e'
    }
}

local current_theme_id = 'catppuccin-mocha'

local function update_conf_file(color_str)
    local conf_path = mp.command_native({'expand-path', '~~/script-opts/uosc.conf'})
    local f = io.open(conf_path, 'r')
    if not f then return end
    local content = f:read('*a')
    f:close()

    local new_content
    if content:find('color=') then
        new_content = content:gsub('color=[^\r\n]*', 'color=' .. color_str)
    else
        new_content = content .. '\ncolor=' .. color_str
    end

    f = io.open(conf_path, 'w')
    if f then
        f:write(new_content)
        f:close()
    end
end

local function apply_theme(theme_id)
    local selected = nil
    for _, t in ipairs(themes) do
        if t.id == theme_id then
            selected = t
            break
        end
    end
    if not selected then return end

    current_theme_id = theme_id
    update_conf_file(selected.color)
    mp.commandv('change-list', 'script-opts', 'append', 'uosc-color=' .. selected.color)
    mp.commandv('show-text', 'Tema Değiştirildi: ' .. selected.title)
end

local function open_theme_menu()
    local items = {}
    for _, t in ipairs(themes) do
        table.insert(items, {
            title = t.title,
            hint = t.hint,
            active = (t.id == current_theme_id),
            value = 'script-message-to theme_switcher set-theme ' .. t.id
        })
    end

    local menu = {
        type = 'theme_menu',
        title = 'Themes (Temalar)',
        items = items
    }

    local json_str = utils.format_json(menu)
    mp.commandv('script-message-to', 'uosc', 'open-menu', json_str)
end

mp.add_key_binding(nil, 'open-menu', open_theme_menu)
mp.register_script_message('open-menu', open_theme_menu)
mp.register_script_message('set-theme', apply_theme)
