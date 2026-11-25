"""Converte outfits de um grupo (parado+passos juntos) em Idle(1 frame) + Moving(N-1 frames).

Formato: Tibia.dat 8.00, extended (sprites u32), frame-durations e frame-groups ligados.
Outfits AnimateAlways e com grupo Idle ja existente ficam como estao.
"""
import struct, sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from datscan import R, read_attrs

ANIMATE_ALWAYS_RAW = 28  # 8.00: raw 28 -> OTC ThingAttrAnimateAlways (27)

def attrs_raw(r):
    from datscan import U16
    start = r.p; flags = []
    while True:
        a = r.u8()
        if a == 255: break
        flags.append(a)
        if a == 8: continue
        x = a - 1 if a > 8 else a
        if x in U16: r.u16()
        elif x in (21, 24): r.u16(); r.u16()
        elif x == 33: r.skip(6); n = r.u16(); r.skip(n); r.skip(4)
        elif x == 38: r.skip(16)
    return r.b[start:r.p], ANIMATE_ALWAYS_RAW in flags

def read_group_raw(r):
    g = {}
    g['type'] = r.u8()
    g['w'], g['h'] = r.u8(), r.u8()
    g['real'] = r.u8() if (g['w'] > 1 or g['h'] > 1) else None
    g['layers'], g['px'], g['py'], g['pz'], g['ph'] = r.u8(), r.u8(), r.u8(), r.u8(), r.u8()
    g['anim'] = None
    if g['ph'] > 1:
        mode = r.u8(); loop = r.i32(); start = r.i8()
        g['anim'] = (mode, loop, start, [(r.u32(), r.u32()) for _ in range(g['ph'])])
    g['block'] = g['w'] * g['h'] * g['layers'] * g['px'] * g['py'] * g['pz']
    g['spr'] = [r.u32() for _ in range(g['block'] * g['ph'])]
    return g

def write_group(g):
    out = bytearray(struct.pack('<BBB', g['type'], g['w'], g['h']))
    if g['real'] is not None: out.append(g['real'])
    out += struct.pack('<BBBBB', g['layers'], g['px'], g['py'], g['pz'], g['ph'])
    if g['ph'] > 1:
        mode, loop, start, dur = g['anim']
        out += struct.pack('<Bib', mode, loop, start)
        for mn, mx in dur: out += struct.pack('<II', mn, mx)
    out += struct.pack('<%dI' % len(g['spr']), *g['spr'])
    return out

def main(src, dst):
    b = open(src, 'rb').read(); r = R(b)
    r.u32(); ni, no, ne, nm = r.u16(), r.u16(), r.u16(), r.u16()
    from datscan import read_group
    for cid in range(100, ni + 1):
        read_attrs(r); read_group(r, False)
    out = bytearray(b[:r.p])
    conv = skip_aa = skip_other = 0
    for cid in range(1, no + 1):
        raw, aa = attrs_raw(r)
        n = r.u8()
        groups = [read_group_raw(r) for _ in range(n)]
        out += raw
        if n == 1 and groups[0]['ph'] >= 2 and not aa:
            g = groups[0]; blk = g['block']
            idle = dict(g, type=0, ph=1, anim=None, spr=g['spr'][:blk])
            mph = g['ph'] - 1
            anim = None
            if mph > 1:
                mode, loop, start, dur = g['anim']
                anim = (mode, loop, 0, dur[1:])
            moving = dict(g, type=1, ph=mph, anim=anim, spr=g['spr'][blk:])
            groups = [idle, moving]; conv += 1
        elif aa and n == 1 and groups[0]['ph'] >= 2:
            skip_aa += 1
        else:
            skip_other += 1
        out.append(len(groups))
        for g in groups: out += write_group(g)
    out += b[r.p:]  # efeitos e misseis sem mudanca
    open(dst, 'wb').write(out)
    print('convertidos', conv, '| animate-always mantidos', skip_aa, '| outros mantidos', skip_other)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
