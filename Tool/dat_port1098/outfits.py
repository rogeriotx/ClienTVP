"""Leitura das secoes de outfits do Tibia.dat 8.00 (TVP) e 10.98 (Hellgrave).
Os dois usam frame-groups em outfits: attrs, u8 nGroups, por grupo: u8 tipo + grupo com anim."""
import struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dat800, dat1098


def read_group(d, i):
    t = d[i]; i += 1
    w, h = d[i], d[i+1]; i += 2
    real = None
    if w > 1 or h > 1: real = d[i]; i += 1
    layers, px, py, pz, ph = d[i:i+5]; i += 5
    anim = b''
    if ph > 1: anim = d[i:i + 6 + 8 * ph]; i += len(anim)
    n = w*h*layers*px*py*pz*ph
    spr = list(struct.unpack_from('<%dI' % n, d, i)); i += 4*n
    return dict(type=t, w=w, h=h, real=real, layers=layers, px=px, py=py, pz=pz, ph=ph, anim=anim, spr=spr), i


def write_group(g):
    out = bytearray([g['type'], g['w'], g['h']])
    if g['real'] is not None: out.append(g['real'])
    out += bytes([g['layers'], g['px'], g['py'], g['pz'], g['ph']]) + g['anim']
    return out + struct.pack('<%dI' % len(g['spr']), *g['spr'])


def attrs_800(d, i):
    f, j = dat800.parse_attrs(d, i); return f, j


def attrs_1098(d, i):
    f = {}
    while True:
        a = d[i]; i += 1
        if a == 255: return f, i
        if a in dat1098.U16: f[dat1098.NAMES[a]] = struct.unpack_from('<H', d, i)[0]; i += 2
        elif a in dat1098.U16x2: f[dat1098.NAMES[a]] = struct.unpack_from('<HH', d, i); i += 4
        elif a == 34: ln = struct.unpack_from('<H', d, i + 6)[0]; i += 8 + ln + 4
        else: f[dat1098.NAMES.get(a, a)] = True


def read(path, kind):
    """kind '800' ou '1098'. Retorna (bytes, header, item_end, outfits{id: dict(attr=(a0,a1), raw_attr, groups, span)})"""
    d = open(path, 'rb').read()
    if kind == '800':
        _, items, hdr, i = dat800.read(path); ni, no = hdr[1], hdr[2]; attrs = attrs_800
    else:
        _, (ni, no, ne, nm), i = dat1098.read_items(path); hdr = (None, ni, no, ne, nm); attrs = attrs_1098
    item_end = i; out = {}
    for oid in range(1, no + 1):
        a0 = i; flags, i = attrs(d, i); a1 = i
        n = d[i]; i += 1; groups = []
        for _ in range(n):
            g, i = read_group(d, i); groups.append(g)
        out[oid] = dict(flags=flags, raw_attr=d[a0:a1], groups=groups, span=(a0, i))
    return d, hdr, item_end, out
