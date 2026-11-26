"""Port 4: monstros do Hellgrave (10.98) sem sprite no dat 8.00 + corpses.
- Outfits vazios no 8.00 sao trocados no lugar pelo outfit 10.98 de mesmo id.
- Cada cadeia de corpse (fresco -> ... -> ultimo estagio) vira itens NOVOS no fim do otb/dat
  (server ids a partir do primeiro livre, client = server - 23) e entra no items.xml com decayTo remapeado.
Uso: python port_monsters.py [--apply]   (backups *.bak-antes-monstros)"""
import struct, sys, os, re, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dat800, dat1098, port, outfits
from port_potions import otb_node, OTB, OFFSET

DAT, SPR = port.DAT, port.SPR
XML = 'X:/data/items/items.xml'
XML98 = 'C:/Users/roger/Desktop/Server + Client + All Sources/Server/data/items/items.xml'
BAK = '.bak-antes-monstros'

OUTFITS = [308, 291]  # werewolf, wyrm
CORPSES = [  # (nome, cadeia de server ids 10.98 na ordem do decay)
    ('werewolf', [20607, 20604, 20605, 20606]),
    ('werebear', [24666, 24667, 24668, 24669]),
    ('wereboar', [24722, 24724, 24725, 24726]),
    ('elder wyrm', [21283, 21284, 21285, 21286]),
    ('grim reaper', [8955, 8956, 8957, 8958]),
    ('wyrm', [8941, 8942, 8943, 8944]),
]
# dat 8.00 raw
RAW = {'Container': 4, 'ForceUse': 6, 'NotMoveable': 14, 'LyingCorpse': 27}
OTB_MOVEABLE, GROUP_CONTAINER = 0x40, 2


def xml_items(path):
    x = open(path, encoding='latin-1').read(); out = {}
    for m in re.finditer(r'<item id="(\d+)"([^>]*?)(?:/>|>(.*?)</item>)', x, re.S):
        out[int(m.group(1))] = (m.group(2), re.findall(r'key="(\w+)" value="([^"]*)"', m.group(3) or ''))
    return out


def main(apply):
    s2c98 = dat1098.otb_map(dat1098.SRV); items98, _, _ = dat1098.read_items(dat1098.DAT)
    spr98 = open(port.SPR1098, 'rb').read()
    dat, items, (sig, ni, no, ne, nm), _ = dat800.read(DAT)
    _, _, _, o8 = outfits.read(DAT, '800'); _, _, _, o98 = outfits.read(dat1098.DAT, '1098')
    spr = open(SPR, 'rb').read(); ssig, scount = struct.unpack_from('<II', spr, 0)
    otb = open(OTB, 'rb').read(); s2c = dat1098.otb_map(OTB)
    x98 = xml_items(XML98)

    new_sprites = []; remap = {}
    def add_sprite(sid98):
        if sid98 == 0: return 0
        if sid98 not in remap:
            blob = port.encode_rgb(port.decode_rgba(spr98, sid98))
            if blob is None: remap[sid98] = 0
            else: new_sprites.append(blob); remap[sid98] = scount + len(new_sprites)
        return remap[sid98]

    # outfits: troca no lugar
    out_repl = {}
    for oid in OUTFITS:
        assert not any(s for g in o8[oid]['groups'] for s in g['spr']), ('outfit %d ja tem sprite' % oid)
        body = bytearray(o8[oid]['raw_attr']) + bytes([len(o98[oid]['groups'])])
        for g in o98[oid]['groups']:
            body += outfits.write_group(dict(g, spr=[add_sprite(s) for s in g['spr']]))
        out_repl[oid] = body
        print('outfit %d <- 10.98 grupos %s' % (oid, [(g['type'], g['ph']) for g in o98[oid]['groups']]))

    # corpses: itens novos
    first = max(s2c) + 1
    assert ni == first - 1 - OFFSET, (ni, first)
    newid = {}; order = []
    for name, chain in CORPSES:
        for src in chain:
            newid[src] = first + len(order); order.append((name, src))
    dat_entries = bytearray(); otb_nodes = bytearray(); xml_out = []
    for name, src in order:
        sid = newid[src]; cid = sid - OFFSET; it = items98[s2c98[src]]; f = it['flags']
        attr = bytes(RAW[k] for k in ('Container', 'ForceUse', 'NotMoveable', 'LyingCorpse') if f.get(k)) + b'\xff'
        group = bytes([it['w'], it['h']]) + (bytes([it['exact']]) if it['w'] > 1 or it['h'] > 1 else b'')
        group += bytes([it['layers'], it['px'], it['py'], it['pz'], it['frames']]) + it['anim']
        sprites = [add_sprite(s) for s in it['sprites']]
        dat_entries += attr + group + struct.pack('<%dI' % len(sprites), *sprites)
        otb_nodes += otb_node(sid, cid, 0 if f.get('NotMoveable') else OTB_MOVEABLE, GROUP_CONTAINER if f.get('Container') else 0)
        head, attrs = x98[src]
        lines = ['\t<item id="%d"%s>' % (sid, head)]
        for k, v in attrs:
            if k == 'decayTo': v = str(newid.get(int(v), 0))
            lines.append('\t\t<attribute key="%s" value="%s" />' % (k, v))
        xml_out.append('\n'.join(lines + ['\t</item>']))
        print('%d (cid %d) <- %d %-12s %dx%d %s' % (sid, cid, src, name, it['w'], it['h'], dict(attrs).get('decayTo')))

    # dat: corpses no fim dos itens, outfits trocados de tras pra frente
    item_end = items[ni]['group'][1]
    out = bytearray(dat)
    for oid in sorted(out_repl, reverse=True):
        a, b = o8[oid]['span']; out[a:b] = out_repl[oid]
    out[item_end:item_end] = dat_entries
    struct.pack_into('<H', out, 4, ni + len(order))

    k = len(new_sprites); shift = 4 * k
    tab = [o + shift if o else 0 for o in struct.unpack_from('<%dI' % scount, spr, 8)]
    body = spr[8 + 4 * scount:]; pos = 8 + 4 * (scount + k) + len(body); extra = bytearray()
    for b in new_sprites: tab.append(pos + len(extra)); extra += b
    new_spr = struct.pack('<II', ssig, scount + k) + struct.pack('<%dI' % len(tab), *tab) + body + extra
    new_otb = otb[:-1] + bytes(otb_nodes) + b'\xff'

    xs = open(XML, 'rb').read().decode('latin-1'); nl = '\r\n' if '\r\n' in xs else '\n'
    assert 'id="%d"' % first not in xs
    xs = xs.replace('</items>', nl.join(xml_out).replace('\n', nl) + nl + '</items>')

    print('corpses', len(order), '(%d-%d) | sprites novos %d' % (first, first + len(order) - 1, k))
    print('ids:', {n: newid[c[0]] for n, c in CORPSES})
    if apply:
        for f in (DAT, SPR, OTB, XML):
            if not os.path.exists(f + BAK): shutil.copy2(f, f + BAK)
        open(DAT, 'wb').write(out); open(SPR, 'wb').write(new_spr); open(OTB, 'wb').write(new_otb)
        open(XML, 'wb').write(xs.encode('latin-1'))
        _, _, _, chk = outfits.read(DAT, '800'); m2 = dat1098.otb_map(OTB)
        assert all(any(s for g in chk[o]['groups'] for s in g['spr']) for o in OUTFITS)
        assert all(m2[newid[c]] == newid[c] - OFFSET for _, c in order)
        print('gravado e relido OK (backups *%s)' % BAK)


if __name__ == '__main__':
    main('--apply' in sys.argv)
