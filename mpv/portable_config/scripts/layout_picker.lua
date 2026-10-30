local utils = require('mp.utils')
local msg = require('mp.msg')

local default_glassy_opacity = 'timeline=0.8,position=1,chapters=0.8,slider=0.8,slider_gauge=1,controls=0,speed=0.6,menu=0.88,submenu=0.5,border=1,title=1,tooltip=0.9,thumbnail=1,curtain=0.7'
local solid_opaque_opacity = 'timeline=1,position=1,chapters=1,slider=1,slider_gauge=1,controls=1,speed=1,menu=1,submenu=1,border=1,title=1,tooltip=1,thumbnail=1,curtain=1'

local layouts = {
    {
        id = 'modern-balanced',
        title = '✨ Modern Dengeli (Buzlu Cam)',
        hint = 'Piksel hizalı, 28px zarif ikonlar, yarı saydam',
        opts = {
            controls = 'menu,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,gap:6.3,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen',
            controls_size = '28',
            timeline_style = 'line',
            timeline_line_width = '3',
            border_radius = '10',
            opacity = default_glassy_opacity,
            top_bar = 'always',
            top_bar_controls = 'right'
        }
    },
    {
        id = 'solid-opaque',
        title = '⬛ Opak Koyu Barlar (Saydam Değil)',
        hint = 'Üst ve alt barlar tam siyah/opak (saydamlık yok)',
        opts = {
            controls = 'menu,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,gap:6.3,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen',
            controls_size = '28',
            timeline_style = 'bar',
            timeline_line_width = '3',
            border_radius = '6',
            opacity = solid_opaque_opacity,
            top_bar = 'always',
            top_bar_controls = 'right'
        }
    },
    {
        id = 'classic-bar',
        title = '📊 Bar İlerleme Çubuğu',
        hint = 'Kalın dolgulu seekbar tarzı',
        opts = {
            controls = 'menu,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,gap:6.3,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen',
            controls_size = '32',
            timeline_style = 'bar',
            timeline_size = '40',
            border_radius = '8',
            opacity = default_glassy_opacity,
            top_bar = 'always',
            top_bar_controls = 'right'
        }
    },
    {
        id = 'minimalist',
        title = '🍃 Ultra Minimalist',
        hint = 'Sadece temel kontroller, 24px küçük ikonlar',
        opts = {
            controls = 'menu,gap,space,speed,space,prev,items,next,gap,fullscreen',
            controls_size = '24',
            timeline_style = 'line',
            timeline_line_width = '2',
            border_radius = '6',
            opacity = default_glassy_opacity,
            top_bar = 'always',
            top_bar_controls = 'right'
        }
    },
    {
        id = 'full-loaded',
        title = '🎛️ Zengin & Gelişmiş',
        hint = '32px büyük ikonlar, detaylı kontroller',
        opts = {
            controls = 'menu,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,gap:6.3,space,speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen',
            controls_size = '32',
            timeline_style = 'line',
            timeline_line_width = '4',
            border_radius = '12',
            opacity = default_glassy_opacity,
            top_bar = 'always',
            top_bar_controls = 'right'
        }
    }
}

local current_layout_id = 'modern-balanced'

local function update_conf_file(opts)
    local conf_path = mp.command_native({'expand-path', '~~/script-opts/uosc.conf'})
    local f = io.open(conf_path, 'r')
    if not f then return end
    local content = f:read('*a')
    f:close()

    local new_content = content
    for key, val in pairs(opts) do
        local exact_pattern = '([\r\n])' .. key .. '=[^\r\n]*'
        if new_content:find('[\r\n]' .. key .. '=') then
            new_content = new_content:gsub(exact_pattern, '%1' .. key .. '=' .. val)
        elseif new_content:find('^' .. key .. '=') then
            new_content = new_content:gsub('^' .. key .. '=[^\r\n]*', key .. '=' .. val)
        else
            new_content = new_content .. '\n' .. key .. '=' .. val
        end
    end

    f = io.open(conf_path, 'w')
    if f then
        f:write(new_content)
        f:close()
    end
end

local function apply_layout(layout_id)
    local selected = nil
    for _, l in ipairs(layouts) do
        if l.id == layout_id then
            selected = l
            break
        end
    end
    if not selected then return end

    current_layout_id = layout_id
    update_conf_file(selected.opts)

    for key, val in pairs(selected.opts) do
        mp.commandv('change-list', 'script-opts', 'append', 'uosc-' .. key .. '=' .. val)
    end

    mp.commandv('show-text', 'Düzen Değiştirildi: ' .. selected.title)
end

local function open_layout_menu()
    local items = {}
    for _, l in ipairs(layouts) do
        table.insert(items, {
            title = l.title,
            hint = l.hint,
            active = (l.id == current_layout_id),
            value = 'script-message-to layout_picker set-layout ' .. l.id
        })
    end

    local menu = {
        type = 'layout_menu',
        title = 'Layouts (Arayüz Düzenleri)',
        items = items
    }

    local json_str = utils.format_json(menu)
    mp.commandv('script-message-to', 'uosc', 'open-menu', json_str)
end

mp.add_key_binding(nil, 'open-menu', open_layout_menu)
mp.register_script_message('open-menu', open_layout_menu)
mp.register_script_message('set-layout', apply_layout)
