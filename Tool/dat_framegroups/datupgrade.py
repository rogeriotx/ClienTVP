"""Converte Tibia.dat 8.00 (extended, SEM frame-durations e SEM frame-groups) para
frame-durations + frame-groups, ja com outfits em Idle(1 frame) + Moving(passos).

Duracoes padrao iguais as do Object Builder: itens 500 ms, outfits 300 ms, efeitos/misseis 100 ms.
Outfits AnimateAlways ou de 1 frame ficam com um grupo so (Moving), como o Object Builder grava.

uso: python -I datupgrade.py <Tibia.dat antigo> <saida>
"""
import struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from datscan import R, U16

ANIMATE_ALWAYS_RAW = 28

def read_attrs_raw(r):
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

def read_plain(r):
    g = {'w': r.u8(), 'h': r.u8()}
    g['real'] = r.u8() if (g['w'] > 1 or g['h'] > 1) else None
    g['layers'], g['px'], g['py'], g['pz'], g['ph'] = r.u8(), r.u8(), r.u8(), r.u8(), r.u8()
    g['block'] = g['w'] * g['h'] * g['layers'] * g['px'] * g['py'] * g['pz']
    g['spr'] = [r.u32() for _ in range(g['block'] * g['ph'])]
    return g

def write_group(g, ms, gtype=None):
    out = bytearray()
    if gtype is not None: out.append(gtype)
    out += struct.pack('<BB', g['w'], g['h'])
    if g['real'] is not None: out.append(g['real'])
    out += struct.pack('<BBBBB', g['layers'], g['px'], g['py'], g['pz'], g['ph'])
    if g['ph'] > 1:
        out += struct.pack('<Bib', 0, 0, 0)  # async, loop infinito, comeca no frame 0
        out += struct.pack('<II', ms, ms) * g['ph']
    out += struct.pack('<%dI' % len(g['spr']), *g['spr'])
    return out

def main(src, dst):
    b = open(src, 'rb').read(); r = R(b)
    sig = r.u32(); counts = [r.u16() for _ in range(4)]
    ni, no, ne, nm = counts
    out = bytearray(struct.pack('<IHHHH', sig, *counts))
    for cid in range(100, ni + 1):
        raw, _ = read_attrs_raw(r); out += raw + write_group(read_plain(r), 500)
    conv = 0
    for cid in range(1, no + 1):
        raw, aa = read_attrs_raw(r); g = read_plain(r); out += raw
        if g['ph'] >= 2 and not aa:
            blk = g['block']
            idle = dict(g, ph=1, spr=g['spr'][:blk])
            moving = dict(g, ph=g['ph'] - 1, spr=g['spr'][blk:])
            out.append(2); out += write_group(idle, 300, 0) + write_group(moving, 300, 1); conv += 1
        else:
            out.append(1); out += write_group(g, 300, 1)
    for cid in range(1, ne + nm + 1):
        raw, _ = read_attrs_raw(r); out += raw + write_group(read_plain(r), 100)
    if r.p != len(b):
        sys.exit('ERRO: sobraram %d bytes, formato inesperado' % (len(b) - r.p))
    open(dst, 'wb').write(out)
    print('itens', ni - 99, '| outfits', no, '(separados', conv, ') | efeitos', ne, '| misseis', nm)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
