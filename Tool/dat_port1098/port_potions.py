"""Port 3: acrescenta potions do Hellgrave (10.98) como itens NOVOS no fim do items.otb / Tibia.dat / Tibia.spr.
Server ids 8000+ (client = server - 23, mesma regra da faixa 7691-7999). Nao mexe em nenhum item existente.
Uso: python port_potions.py            -> so mostra o que faria
     python port_potions.py --apply    -> grava (backups *.bak-antes-potions)"""
import struct, sys, os, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dat800, dat1098, port

OTB = 'X:/data/items/items.otb'
DAT, SPR = port.DAT, port.SPR
OFFSET = 23
BAK = '.bak-antes-potions'

# (server id pbOT, server id Hellgrave, nome)
NEW = [
    (8000, 7588, 'strong health potion'),
    (8001, 7589, 'strong mana potion'),
    (8002, 7590, 'great mana potion'),
    (8003, 7591, 'great health potion'),
    (8004, 12328, 'interdimensional potion'),
    (8005, 26029, 'ultimate mana potion'),
    (8006, 26030, 'ultimate spirit potion'),
    (8007, 26031, 'supreme health potion'),
    (8008, 28095, 'double exp potion'),
    (8009, 28096, 'reset deck cards potion'),
]

# dat 8.00 raw flags / otb flags
DAT_FLAG = {'Stackable': 5, 'MultiUse': 7, 'Pickupable': 17}
OTB_USEABLE, OTB_PICKUPABLE, OTB_MOVEABLE, OTB_STACKABLE = 0x10, 0x20, 0x40, 0x80


def otb_escape(b):
    out = bytearray()
    for x in b:
        if x in (0xFD, 0xFE, 0xFF): out.append(0xFD)
        out.append(x)
    return bytes(out)


def otb_node(sid, cid, flags):
    props = struct.pack('<I', flags)
    props += struct.pack('<BHH', 0x10, 2, sid) + struct.pack('<BHH', 0x11, 2, cid)
    props += struct.pack('<BH', 0x20, 16) + b'\x00' * 16
    return b'\xfe\x00' + otb_escape(props) + b'\xff'


def main(apply):
    s2c98 = dat1098.otb_map(dat1098.SRV); items98, _, _ = dat1098.read_items(dat1098.DAT)
    spr98 = open(port.SPR1098, 'rb').read()
    dat, items, (sig, ni, no, ne, nm), _ = dat800.read(DAT)
    spr = open(SPR, 'rb').read()
    ssig, scount = struct.unpack_from('<II', spr, 0)
    otb = open(OTB, 'rb').read()
    s2c = dat1098.otb_map(OTB)

    first = NEW[0][0]
    assert max(s2c) == first - 1, ('otb ja tem itens >= %d (max %d): ja aplicado?' % (first, max(s2c)))
    assert ni == first - 1 - OFFSET, ('dat nao termina em %d (ni=%d)' % (first - 1 - OFFSET, ni))

    new_sprites = []; remap = {}
    def add_sprite(sid98):
        if sid98 == 0: return 0
        if sid98 not in remap:
            blob = port.encode_rgb(port.decode_rgba(spr98, sid98))
            if blob is None: remap[sid98] = 0
            else: new_sprites.append(blob); remap[sid98] = scount + len(new_sprites)
        return remap[sid98]

    dat_entries = bytearray(); otb_nodes = bytearray()
    for n, (sid, src, name) in enumerate(NEW):
        cid = sid - OFFSET
        assert cid == ni + 1 + n
        it = items98[s2c98[src]]; f = it['flags']
        assert it['w'] == 1 and it['h'] == 1 and it['layers'] == 1 and it['px'] == it['py'] == it['pz'] == 1, (sid, src)
        attr = bytes(DAT_FLAG[k] for k in ('Stackable', 'MultiUse', 'Pickupable') if f.get(k)) + b'\xff'
        sprites = [add_sprite(x) for x in it['sprites']]
        group = bytes([1, 1, 1, 1, 1, 1, it['frames']]) + it['anim'] + struct.pack('<%dI' % len(sprites), *sprites)
        dat_entries += attr + group
        of = OTB_MOVEABLE | OTB_PICKUPABLE
        if f.get('Stackable'): of |= OTB_STACKABLE
        if f.get('MultiUse'): of |= OTB_USEABLE
        otb_nodes += otb_node(sid, cid, of)
        print('%d (cid %d) <- %5d %-24s frames %2d otb 0x%02x spr %s' % (sid, cid, src, name, it['frames'], of, sprites[:3]))

    # dat: itens novos entram no fim da secao de itens (antes dos outfits)
    item_end = items[ni]['group'][1]
    out = bytearray(dat[:item_end]) + dat_entries + dat[item_end:]
    struct.pack_into('<H', out, 4, ni + len(NEW))

    # spr: tabela cresce -> offsets antigos andam 4*n
    k = len(new_sprites); shift = 4 * k
    old_tab = struct.unpack_from('<%dI' % scount, spr, 8)
    body = spr[8 + 4 * scount:]
    tab = [o + shift if o else 0 for o in old_tab]
    pos = 8 + 4 * (scount + k) + len(body); extra = bytearray()
    for b in new_sprites:
        tab.append(pos + len(extra)); extra += b
    new_spr = struct.pack('<II', ssig, scount + k) + struct.pack('<%dI' % len(tab), *tab) + body + extra

    # otb: nos novos antes do 0xFF final da raiz
    assert otb[-1] == 0xFF
    new_otb = otb[:-1] + bytes(otb_nodes) + b'\xff'

    print('dat itens', ni, '->', ni + len(NEW), '| sprites novos', k, '| spr', scount, '->', scount + k)
    if apply:
        for f in (DAT, SPR, OTB):
            if not os.path.exists(f + BAK): shutil.copy2(f, f + BAK)
        open(DAT, 'wb').write(out); open(SPR, 'wb').write(new_spr); open(OTB, 'wb').write(new_otb)
        # confere releitura
        _, it2, hdr2, _ = dat800.read(DAT); m2 = dat1098.otb_map(OTB)
        assert hdr2[1] == ni + len(NEW) and all(m2[s] == s - OFFSET for s, _, _ in NEW)
        print('gravado e relido OK (backups *%s)' % BAK)


if __name__ == '__main__':
    main('--apply' in sys.argv)
