//==============================================================================
//  theme.nss  --  Catppuccin Mocha / Mauve
//==============================================================================
//  MENUNUN YUKARI KAYMASI HAKKINDA  (arastirma sonucu)
//------------------------------------------------------------------------------
//  Nilesoft Shell'de menuyu imlece gore kaydiran bir ayar YOKTUR.
//  Dogrulandi:
//    - settings blogunda position/offset/align turu bir ozellik yok
//      (sadece showdelay, exclude, tip.*, modify.*, new.*)
//    - theme.layout.popup var ama YATAY'dir: alt menuleri sola/saga kaydirir,
//      dikey konumla ilgisi yok
//    - theme.shadow.offset golgenin kendi kaymasidir, menuyu tasimaz
//    - moudey/Shell deposunda "imlece gore kayma" diye acilmis bir hata kaydi yok
//
//  Yani kayma temadan degil, Windows'un kendi davranisindan geliyor:
//  klasik popup menu imlecin ALTINA acilir; ekranin altina sigmiyorsa
//  Windows menuyu imlecin USTUNE ters cevirir. Menu ne kadar uzunsa
//  bu o kadar sik olur.
//
//  Eski konfigurasyonda kok seviyede cok fazla oge vardi -> menu uzundu ->
//  surekli yukari donuyordu. Bu konfigurasyonda kok seviye 7 gruba
//  indirildi ve asagidaki "view = compact" ile satir yuksekligi kisaldi.
//  Ikisi birlikte menuyu belirgin sekilde kisaltir.
//
//  Hala rahatsiz ediyorsa denenecek iki ayar (ikisi de asagida isaretli):
//    1) view = small     -> satirlari daha da kisaltir
//    2) shadow.enabled = false + border.radius = 0
//       -> pencere etrafindaki seffaf golge/yuvarlatma payini kaldirir,
//          menunun ilk satiri imlece birkac piksel daha yakin oturur
//==============================================================================

theme
{
    name = "modern"
    dark = true

    // (1) MENU YUKSEKLIGI AYARI -- kayma yasarsan "small" dene
    view = "compact"        // auto | compact | small | medium | large | wide

    background
    {
        color   = #1e1e2e   // Base
        opacity = 95
        effect  = 2         // 0:kapali 1:seffaf 2:blur 3:acrylic
    }

    image.align = 2

    item
    {
        opacity = 100
        prefix  = 1

        text
        {
            normal          = #cdd6f4   // Text
            select          = #cba6f7   // Mauve  <- vurgu rengi
            normal-disabled = #6c7086   // Overlay0
            select-disabled = #6c7086
        }

        back
        {
            select          = #45475a   // Surface1
            select-disabled = #313244   // Surface0
        }
    }

    border
    {
        enabled = true
        size    = 1
        color   = #cba6f7   // Mauve
        opacity = 100
        radius  = 8         // (2) kayma denemesi icin 0 yap
    }

    separator
    {
        size  = 1
        color = #313244     // Surface0
    }

    shadow
    {
        enabled = true      // (2) kayma denemesi icin false yap
        size    = 5
        offset  = 2
        opacity = 50
    }
}
