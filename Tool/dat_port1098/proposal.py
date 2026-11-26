import sys, struct, re, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dat800, dat1098
from PIL import Image, ImageDraw
BG = (90, 90, 96)
s2c = dat1098.otb_map(dat1098.SRV); it98, _, _ = dat1098.read_items(dat1098.DAT)
spr98 = open(dat1098.DAT.replace('Tibia.dat', 'Tibia.spr'), 'rb').read()
_, it8, _, _ = dat800.read(); spr8 = open(dat800.DAT.replace('Tibia.dat', 'Tibia.spr'), 'rb').read()
def spr(s, sid, alpha):
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    if sid == 0: return img
    off = struct.unpack_from('<I', s, 8 + (sid - 1) * 4)[0]
    if not off: return img
    size = struct.unpack_from('<H', s, off + 3)[0]; i = off + 5; end = i + size; p = 0; bpp = 4 if alpha else 3
    while i < end:
        t, c = struct.unpack_from('<HH', s, i); i += 4; p += t
        for _ in range(c):
            img.putpixel((p % 32, p // 32), tuple(s[i:i+3]) + ((s[i+3],) if alpha else (255,))); i += bpp; p += 1
    return img
def render(t, s, alpha, tiles=1):
    w, h, L = t['w'], t['h'], t['layers']
    if tiles > 1 and w == 1 and h == 1:  # chao em 3x3 com pattern
        im = Image.new('RGBA', (96, 96), BG + (255,))
        for y in range(3):
            for x in range(3):
                idx = ((y % t['py']) * t['px'] + (x % t['px'])) * L
                im.alpha_composite(spr(s, t['sprites'][idx], alpha), (x*32, y*32))
        return im
    im = Image.new('RGBA', (32*w, 32*h), BG + (255,))
    for y in range(h):
        for x in range(w):
            im.alpha_composite(spr(s, t['sprites'][(h-1-y)*w + (w-1-x)], alpha), (x*32, y*32))
    return im
def old(sid, tiles=1): return render(it8[sid - 23], spr8, False, tiles)
def new(sid, tiles=1): return render(it98[s2c[sid]], spr98, True, tiles)
def sheet(path, rows):
    cell = 300; W = 4 * cell; H = ((len(rows) + 3) // 4) * 150
    out = Image.new('RGB', (W, H), (40, 40, 44)); d = ImageDraw.Draw(out)
    for k, (label, o, n, tiles) in enumerate(rows):
        x = (k % 4) * cell + 6; y = (k // 4) * 150 + 6
        a = old(o, tiles); out.paste(a.convert('RGB').resize((a.width*96//max(a.size), a.height*96//max(a.size)), Image.NEAREST) if max(a.size) > 96 else a.convert('RGB'), (x, y))
        xx = x + 110
        for sid in (n if isinstance(n, (list, tuple)) else [n]):
            b = new(sid, tiles); 
            if max(b.size) > 96: b = b.resize((b.width*96//max(b.size), b.height*96//max(b.size)), Image.NEAREST)
            out.paste(b.convert('RGB'), (xx, y)); xx += b.width + 4
        d.text((x, y + 100), label, fill=(240, 240, 240)); d.text((x, y + 116), '%d -> %s' % (o, n), fill=(170, 170, 255))
    out.save(path); print(out.size)
