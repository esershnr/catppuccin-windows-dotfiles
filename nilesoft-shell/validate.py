# -*- coding: utf-8 -*-
"""shell.nss dogrulayici -- kurmadan ONCE calistir.
Nilesoft ayrıştırıcısının sessizce reddettigi hatalari yakalar."""
import io, re, glob, sys

files = ['shell.nss'] + sorted(glob.glob('imports/*.nss'))
bad = 0
for p in files:
    if p.endswith('images.nss'): continue
    s = io.open(p, encoding='utf-8').read()

    # 1) HAM PUA karakteri -- ikonlar '' METNI olmali, karakterin kendisi degil
    for i, line in enumerate(s.split('\n'), 1):
        for j, c in enumerate(line):
            if 0xE000 <= ord(c) <= 0xF8FF:
                print("HAM PUA      %s satir %d sutun %d (%s)" % (p, i, j+1, hex(ord(c)))); bad += 1

    # 2) Kontrol karakteri (python kacislarindan sizan NUL vb.)
    for i, line in enumerate(s.split('\n'), 1):
        for j, c in enumerate(line):
            if ord(c) < 32 and c != '\t':
                print("KONTROL KAR. %s satir %d sutun %d (%s)" % (p, i, j+1, hex(ord(c)))); bad += 1

    # 3) Bos image=
    for m in re.finditer(r'image=(?=\)|\s|$)', s):
        print("BOS image=   %s satir %d" % (p, s[:m.start()].count('\n')+1)); bad += 1

    # 4) Parantez dengesi (string ve yorumlar cikarilarak)
    t = re.sub(r"'[^'\n]*'", "''", s)
    t = re.sub(r'"[^"\n]*"', '""', t)
    t = re.sub(r'//[^\n]*', '', t)
    for o, c in [('(', ')'), ('{', '}'), ('[', ']')]:
        if t.count(o) != t.count(c):
            print("DENGESIZ %s%s  %s  %d vs %d" % (o, c, p, t.count(o), t.count(c))); bad += 1

print("\nSORUN: %d" % bad)
sys.exit(1 if bad else 0)
