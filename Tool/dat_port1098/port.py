"""Porta tapetes/pisos do 10.98 para o dat/spr 8.00 do TVP, trocando no lugar (mesmo client id)."""
import struct, sys, shutil, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dat800, dat1098

ROOT = r'C:/Users/roger/Downloads/TVP/TVP-Ravenor-Client/TVP-Ravenor-Client/data/things/800/'
DAT, SPR = ROOT + 'Tibia.dat', ROOT + 'Tibia.spr'
SPR1098 = dat1098.DAT.replace('Tibia.dat', 'Tibia.spr')
OFFSET = 23  # client = server - 23 nesta faixa

FLOOR, CARPET = 'floor', 'carpet'
MAP = {  # server id pbOT: (server id 10.98, tipo, nome)
    7699: (23717, FLOOR, 'white marble floor'),
    7700: (26376, FLOOR, 'polished marble floor'),
    7701: (25548, FLOOR, 'black marble floor'),
    7702: (24081, FLOOR, 'gray ornamented floor'),
    7703: (26374, FLOOR, 'light parquet floor'),
    7704: (23259, FLOOR, 'cream marble floor'),
    7705: (24066, FLOOR, 'mosaic stone floor'),
    7706: (23083, FLOOR, 'brown marble floor'),
    7707: (22566, FLOOR, 'iron floor'),
    7709: (23029, FLOOR, 'herringbone parquet floor'),
    7710: (20217, FLOOR, 'wooden plank floor'),
    7793: (26375, FLOOR, 'dark parquet floor'),
    7742: (26371, CARPET, 'crimson carpet'),
    7751: (26109, CARPET, 'yalaharian carpet'),
    7760: (26373, CARPET, 'emerald carpet'),
    7769: (26372, CARPET, 'azure carpet'),
    7778: (25392, CARPET, 'rift carpet'),
    7784: (26193, CARPET, 'void carpet'),
}

def decode_rgba(spr, sid):
    px = [None] * 1024
    if sid == 0: return px
    off = struct.unpack_from('<I', spr, 8 + (sid - 1) * 4)[0]
    if off == 0: return px
    size = struct.unpack_from('<H', spr, off + 3)[0]; i = off + 5; end = i + size; p = 0
    while i < end:
        t, c = struct.unpack_from('<HH', spr, i); i += 4; p += t
        for _ in range(c):
            px[p] = tuple(spr[i:i+4]); i += 4; p += 1
    return px

def encode_rgb(px):
    """RLE 8.00 sem alpha: pixel com alpha < 128 vira transparente."""
    solid = [x is not None and x[3] >= 128 for x in px]
    if not any(solid): return None
    out = bytearray(); p = 0; last = max(i for i, s in enumerate(solid) if s)
    while p <= last:
        t = 0
        while p <= last and not solid[p]: t += 1; p += 1
        cols = bytearray()
        while p <= last and solid[p]: cols += bytes(px[p][:3]); p += 1
        out += struct.pack('<HH', t, len(cols) // 3) + cols
    return b'\xff\x00\xff' + struct.pack('<H', len(out)) + out

def main(apply):
    s2c98 = dat1098.otb_map(dat1098.SRV); items98, _, _ = dat1098.read_items(dat1098.DAT)
    spr98 = open(SPR1098, 'rb').read()
    dat, items, (sig, ni, no, ne, nm), _ = dat800.read(DAT)
    spr = open(SPR, 'rb').read()
    ssig, scount = struct.unpack_from('<II', spr, 0)

    new_sprites = []; remap = {}
    def add_sprite(sid98):
        if sid98 == 0: return 0
        if sid98 not in remap:
            blob = encode_rgb(decode_rgba(spr98, sid98))
            if blob is None: remap[sid98] = 0
            else:
                new_sprites.append(blob); remap[sid98] = scount + len(new_sprites)
        return remap[sid98]

    entries = {}
    for sid, (src, kind, name) in sorted(MAP.items()):
        cid = sid - OFFSET; old = items[cid]; it = items98[s2c98[src]]
        assert it['w'] == 1 and it['h'] == 1 and it['frames'] == 1 and it['pz'] == 1, (sid, src)
        if kind == FLOOR:
            assert 0 in old['flags'], ('slot nao e chao', sid)
            attr = struct.pack('<BH', 0, old['flags'][0]) + bytes([14]) + struct.pack('<BH', 29, old['flags'].get(29, 129)) + bytes([31, 255])
        else:
            assert 1 in old['flags'], ('slot nao e borda/tapete', sid)
            attr = bytes([1, 14, 255])
        base = it['sprites'][::it['layers']]  # so a camada 0
        sprites = [add_sprite(x) for x in base]
        group = bytes([1, 1, 1, it['px'], it['py'], 1, 1]) + struct.pack('<%dI' % len(sprites), *sprites)
        entries[cid] = attr + group
        print('%d (cid %d) <- %d %-26s pat %dx%d spr %s' % (sid, cid, src, name, it['px'], it['py'], sprites))

    # dat: troca as entradas no lugar (de tras pra frente para nao invalidar offsets)
    out = bytearray(dat)
    for cid in sorted(entries, reverse=True):
        a0 = items[cid]['attr'][0]; g1 = items[cid]['group'][1]
        out[a0:g1] = entries[cid]

    # spr: tabela cresce len(new) entradas -> offsets antigos andam 4*len(new)
    n = len(new_sprites); shift = 4 * n
    old_tab = struct.unpack_from('<%dI' % scount, spr, 8)
    body = spr[8 + 4 * scount:]
    tab = [o + shift if o else 0 for o in old_tab]
    pos = 8 + 4 * (scount + n) + len(body); extra = bytearray()
    for b in new_sprites:
        tab.append(pos + len(extra)); extra += b
    new_spr = struct.pack('<II', ssig, scount + n) + struct.pack('<%dI' % len(tab), *tab) + body + extra
    print('sprites novos:', n, '| spr', scount, '->', scount + n)

    if apply:
        for f in (DAT, SPR):
            bak = f + '.bak-antes-tapetes1098'
            if not os.path.exists(bak): shutil.copy2(f, bak)
        open(DAT, 'wb').write(out); open(SPR, 'wb').write(new_spr)
        print('gravado (backups *.bak-antes-tapetes1098)')

if __name__ == '__main__':
    main('--apply' in sys.argv)
