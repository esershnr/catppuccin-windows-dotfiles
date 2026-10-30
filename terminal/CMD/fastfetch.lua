-- ============================================================
-- Clink + fastfetch entegrasyonu
-- Bu dosyayi %LOCALAPPDATA%\clink\ klasorune kopyala
-- (ornek: C:\Users\Zesha\AppData\Local\clink\fastfetch.lua)
-- ============================================================
-- fastfetch'i SADECE terminal acilisinda bir kere calistirir,
-- her komut girisinde tekrar tekrar calismaz.

local fastfetch_shown = false

local function show_fastfetch_once()
    if not fastfetch_shown then
        fastfetch_shown = true
        os.execute("fastfetch")
    end
end

clink.onbeginedit(show_fastfetch_once)
