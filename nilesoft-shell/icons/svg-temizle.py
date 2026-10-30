# -*- coding: utf-8 -*-
"""
svg-temizle.py  --  SVG'yi Nilesoft Shell'in kabul ettigi bicime cevirir.

Nilesoft SVG'yi kendi motoruyla cizer ve fazlalik iceren dosyalari
SESSIZCE reddeder -- shell.log'a hata bile yazmaz. Bu script,
Shell'in kendi images.nss dosyasindaki uslubu uygular:
viewBox kalir, gerisi silinir, her sekle acik fill yazilir.

Kullanim:
    python svg-temizle.py girdi.svg
    python svg-temizle.py girdi.svg cikti.svg
    python svg-temizle.py girdi.svg cikti.svg --renk 000000=cdd6f4
"""

import io
import os
import re
import sys

# Nilesoft'un cizemedigi / gereksiz bulunan seyler
SILINECEK_NITELIK = ('xmlns', 'xmlns:xlink', 'width', 'height',
                     'class', 'style', 'id', 'data-name')
SILINECEK_ETIKET = ('title', 'desc', 'metadata')

BOYANABILIR = ('path', 'circle', 'rect', 'ellipse', 'polygon', 'polyline')


def temizle(svg, renk_map=None):
    rapor = []

    # 1) yorumlar
    svg, n = re.subn(r'<!--.*?-->', '', svg, flags=re.S)
    if n:
        rapor.append('%d yorum silindi' % n)

    # 2) <title>, <desc>, <metadata>
    for etiket in SILINECEK_ETIKET:
        svg, n = re.subn(r'<%s\b[^>]*>.*?</%s>' % (etiket, etiket), '', svg, flags=re.S)
        svg, n2 = re.subn(r'<%s\b[^>]*/>' % etiket, '', svg)
        if n + n2:
            rapor.append('<%s> silindi' % etiket)

    # 3) <svg> etiketindeki fazlalik nitelikler
    m = re.search(r'<svg\b([^>]*)>', svg)
    if not m:
        raise SystemExit('HATA: <svg> etiketi bulunamadi')
    nitelikler = m.group(1)

    viewbox = re.search(r'viewBox\s*=\s*"([^"]+)"', nitelikler)
    if not viewbox:
        # width/height'tan viewBox uretmeyi dene
        w = re.search(r'\bwidth\s*=\s*"([\d.]+)', nitelikler)
        h = re.search(r'\bheight\s*=\s*"([\d.]+)', nitelikler)
        if w and h:
            vb = '0 0 %s %s' % (w.group(1), h.group(1))
            rapor.append('viewBox yoktu, width/height ile uretildi: %s' % vb)
        else:
            raise SystemExit('HATA: viewBox yok ve width/height ile uretilemedi')
    else:
        vb = viewbox.group(1)

    for nit in SILINECEK_NITELIK:
        if re.search(r'\b%s\s*=' % re.escape(nit), nitelikler):
            rapor.append('<svg> icinden %s silindi' % nit)

    yeni_svg = '<svg viewBox="%s">' % vb
    svg = svg[:m.start()] + yeni_svg + svg[m.end():]

    # 4) ic etiketlerdeki xmlns kalintilari
    svg, n = re.subn(r'\s+xmlns(:\w+)?\s*=\s*"[^"]*"', '', svg)
    if n:
        rapor.append('%d ic xmlns silindi' % n)

    # 5) her sekle acik fill
    eksik = [0]

    def fill_ekle(mm):
        etiket, govde = mm.group(1), mm.group(2)
        if re.search(r'\bfill\s*=', govde):
            return mm.group(0)
        eksik[0] += 1
        return '<%s fill="#000000"%s' % (etiket, govde)

    svg = re.sub(r'<(%s)\b([^>]*)' % '|'.join(BOYANABILIR), fill_ekle, svg)
    if eksik[0]:
        rapor.append('%d sekle fill="#000000" eklendi (SVG varsayilani siyahtir)' % eksik[0])

    # 6) renk degistirme
    if renk_map:
        for eski, yeni in renk_map.items():
            svg, n = re.subn(r'(?i)#' + re.escape(eski) + r'\b', '#' + yeni, svg)
            if n:
                rapor.append('#%s -> #%s (%d yer)' % (eski, yeni, n))

    # 7) tek satira indir
    svg = re.sub(r'>\s+<', '><', svg).strip()
    svg = re.sub(r'\s{2,}', ' ', svg)

    return svg, rapor


def main():
    args = [a for a in sys.argv[1:]]
    renk_map = {}
    if '--renk' in args:
        i = args.index('--renk')
        for esle in args[i + 1].split(','):
            eski, yeni = esle.split('=')
            renk_map[eski.lstrip('#')] = yeni.lstrip('#')
        del args[i:i + 2]

    if not args:
        print(__doc__)
        raise SystemExit(1)

    girdi = args[0]
    cikti = args[1] if len(args) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(girdi)),
        os.path.splitext(os.path.basename(girdi))[0] + '.temiz.svg')

    ham = io.open(girdi, encoding='utf-8').read()
    svg, rapor = temizle(ham, renk_map)

    io.open(cikti, 'w', encoding='utf-8').write(svg)

    print('girdi : %s  (%d bayt)' % (girdi, len(ham)))
    print('cikti : %s  (%d bayt)' % (cikti, len(svg)))
    print('')
    if rapor:
        print('yapilanlar:')
        for r in rapor:
            print('   - ' + r)
    else:
        print('dosya zaten temizdi')

    renkler = sorted(set(re.findall(r'fill="(#[0-9a-fA-F]{3,8})"', svg)))
    print('')
    print('kullanilan renkler: ' + (', '.join(renkler) if renkler else 'yok'))
    print('')
    print('menude kullanmak icin:')
    print("   $p_ikon_x = '@p_ikon_dir\\%s'" % os.path.basename(cikti))
    print('   image=image.svgf(p_ikon_x)')


if __name__ == '__main__':
    main()
