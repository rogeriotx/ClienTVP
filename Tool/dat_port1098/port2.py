"""Port 2: substitui pisos, bordas e mobilia da store House pelos itens 10.98 (mesmos IDs do pbOT).
- floor:  1 slot (chao). Flags de comportamento do slot antigo, visual do 10.98.
- border: cadeia de 12 pecas. Cada peca nova vai para a peca antiga de formato mais parecido.
- furn:   cadeia de N pecas; as M pecas novas ocupam as M primeiras (rotacao ciclica entre elas).
Flags que afetam servidor/ordem de pilha (otb) vem sempre do slot antigo; do 10.98 so Light/Displacement."""
import struct, sys, os, re, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dat800, dat1098, port

XML = 'X:/data/items/items.xml'
OFF = 23
SPEC = [
    # (slot, tipo, [ids 10.98], nome)
    (7708, 'floor', [19824], 'terracotta floor'),
    (7711, 'floor', [14931], 'cracked temple floor'),
    (7712, 'floor', [27995], 'stone ground'),
    (7713, 'floor', [17625], 'basalt floor'),
    (7716, 'floor', [21605], 'grey sand'),
    (7717, 'floor', [10398], 'pavement'),
    (7919, 'floor', [12238], 'rutted earth'),
    (7879, 'floor', [19596], 'cobbled pavement'),
    (7802, 'floor', [25004], 'grass'),
    (7815, 'floor', [21892], 'wasteland'),
    (7828, 'floor', [10637], 'sand'),
    (7841, 'floor', [21942], 'stone pebble floor'),
    (7866, 'floor', [20776], 'forest floor'),
    (7906, 'floor', [17665], 'mossy floor'),
    (7803, 'border', list(range(25018, 25066)), 'grass'),
    (7816, 'border', list(range(21912, 21924)), 'wasteland'),
    (7829, 'border', list(range(10638, 10650)), 'sand'),
    (7842, 'border', list(range(21950, 21962)), 'stone pebble floor'),
    (7867, 'border', list(range(21113, 21125)), 'forest floor'),
    (7907, 'border', list(range(17673, 17685)), 'mossy floor'),
    (7718, 'furn', [26059, 26060, 26061, 26062], 'magnificent chair'),
    (7726, 'furn', [26063, 26064, 26065, 26066], 'ferocious chair'),
    (7970, 'furn', [19648, 19649, 19650, 19651], 'venorean bench'),
    (7734, 'furn', [26349, 26350, 26351, 26352], 'rustic chair'),
    (7738, 'furn', [19639, 19640, 19641, 19642], 'venorean chair'),
    (7920, 'furn', [23809], 'ornamented fountain'),
    (7928, 'furn', [23765], 'well with a lion-like face'),
    (7936, 'furn', [8245, 8246, 8247, 8248], 'ornamented stone'),
    (7940, 'furn', [25299], 'moon flower'),
    (7954, 'furn', [25300], "parrot's beak plant"),
    (7967, 'furn', [24305], 'lapis-crested vase'),
    (7978, 'furn', [26073, 26074], 'magnificent table'),
    (7974, 'furn', [26354, 26355], 'rustic table'),
    (7982, 'furn', [23841, 23842], 'ancient sacrificial stone'),
    (7994, 'furn', [28240], 'majesty altar'),
]
from btype import classify
CANON = ['E_N','E_E','E_S','E_W','O_SE','O_SW','O_NW','O_NE','I_NW','I_NE','I_SE','I_SW']
OLD_ORDER = {7907: ['O_SE','O_SW','O_NE','O_NW','E_E','E_W','E_S','E_N','I_SE','I_SW','I_NE','I_NW']}
RAW = {'Ground': 0, 'GroundBorder': 1, 'OnBottom': 2, 'OnTop': 3}
U16 = {0, 9, 10, 26, 29, 30, 33, 35}; U16x2 = {22, 25}

def chains():
    x = open(XML, encoding='latin-1').read(); rot = {}
    for m in re.finditer(r'<item id="(\d+)"[^>]*?>(.*?)</item>', x, re.S):
        r = re.search(r'rotateTo" value="(\d+)', m.group(2))
        if r: rot[int(m.group(1))] = int(r.group(1))
    def chain(s):
        out = [s]
        while out[-1] in rot and rot[out[-1]] not in out: out.append(rot[out[-1]])
        return out
    return chain

def enc_attrs(flags):
    b = bytearray()
    for a in sorted(flags):
        v = flags[a]; b.append(a)
        if a in U16: b += struct.pack('<H', v)
        elif a in U16x2: b += struct.pack('<HH', *v)
    return bytes(b + b'\xff')

def layer0(t):
    w, h, L = t['w'], t['h'], t['layers']; out = []
    blocks = t['px'] * t['py'] * t['pz'] * t['frames']
    for k in range(blocks):
        base = k * L * w * h
        out += t['sprites'][base: base + w * h]
    return out

def mask_new(spr98, sid):
    px = port.decode_rgba(spr98, sid); return [p is not None and p[3] >= 128 for p in px]
def mask_old(spr8, sid):
    m = [False] * 1024
    if sid == 0: return m
    off = struct.unpack_from('<I', spr8, 8 + (sid - 1) * 4)[0]
    if not off: return m
    size = struct.unpack_from('<H', spr8, off + 3)[0]; i = off + 5; end = i + size; p = 0
    while i < end:
        t, c = struct.unpack_from('<HH', spr8, i); i += 4; p += t
        for _ in range(c): m[p] = True; p += 1; i += 3
    return m
def feat(m):
    """cobertura em 3x3 regioes (cantos, lados, centro) -> direcao da peca"""
    v = []
    for ry in ((0, 11), (11, 21), (21, 32)):
        for rx in ((0, 11), (11, 21), (21, 32)):
            n = (ry[1]-ry[0]) * (rx[1]-rx[0])
            v.append(sum(m[y*32+x] for y in range(*ry) for x in range(*rx)) / n)
    return v
def iou(a, b):
    fa, fb = feat(a), feat(b)
    return 1 - sum(abs(x - y) for x, y in zip(fa, fb)) / 9

def main(apply):
    s2c = dat1098.otb_map(dat1098.SRV); it98, _, _ = dat1098.read_items(dat1098.DAT)
    spr98 = open(port.SPR1098, 'rb').read()
    dat, items, _, _ = dat800.read(port.DAT); spr8 = open(port.SPR, 'rb').read()
    scount = struct.unpack_from('<I', spr8, 4)[0]
    chain = chains(); new_sprites = []; remap = {}
    def add(s):
        if s == 0: return 0
        if s not in remap:
            blob = port.encode_rgb(port.decode_rgba(spr98, s))
            if blob is None: remap[s] = 0
            else: new_sprites.append(blob); remap[s] = scount + len(new_sprites)
        return remap[s]

    entries = {}; xml_names = {}; xml_rot = {}; report = []
    def build(slot, src):
        old = items[slot - OFF]; t = it98[s2c[src]]
        flags = {k: v for k, v in old['flags'].items() if k not in (22, 25)}
        if 'Light' in t['flags']: flags[22] = t['flags']['Light']
        if 'Displacement' in t['flags']: flags[25] = t['flags']['Displacement']
        sprites = [add(s) for s in layer0(t)]
        g = bytearray([t['w'], t['h']])
        if t['w'] > 1 or t['h'] > 1: g.append(t['exact'])
        g += bytes([1, t['px'], t['py'], t['pz'], t['frames']]) + t['anim']
        g += struct.pack('<%dI' % len(sprites), *sprites)
        entries[slot - OFF] = enc_attrs(flags) + bytes(g)

    for slot, kind, srcs, name in SPEC:
        ch = chain(slot)
        if kind == 'floor':
            assert 0 in items[slot - OFF]['flags'], slot
            build(slot, srcs[0]); xml_names[slot] = name; xml_rot[slot] = None
            report.append('%d floor <- %d %s' % (slot, srcs[0], name))
        elif kind == 'border':
            assert len(ch) == 12, (slot, len(ch))
            otypes = OLD_ORDER.get(slot, CANON)
            ntype = {}
            for n in srcs:
                ty = classify(mask_new(spr98, layer0(it98[s2c[n]])[0]))
                ntype.setdefault(ty, n)
            missing = [t for t in otypes if t not in ntype]
            assert not missing, (slot, missing)
            for o, ty in zip(ch, otypes):
                build(o, ntype[ty]); xml_names[o] = name
            report.append('%d border <- %s' % (slot, ' '.join('%d:%d(%s)' % (o, ntype[ty], ty) for o, ty in zip(ch, otypes))))
        else:
            assert len(srcs) <= len(ch), (slot, len(srcs), len(ch))
            used = ch[:len(srcs)]
            for o, n in zip(used, srcs): build(o, n); xml_names[o] = name
            for k, o in enumerate(used): xml_rot[o] = used[(k + 1) % len(used)] if len(used) > 1 else None
            report.append('%d furn %d/%d pecas <- %s' % (slot, len(srcs), len(ch), srcs))
    print('\n'.join(report)); print('sprites novos:', len(new_sprites))

    out = bytearray(dat)
    for cid in sorted(entries, reverse=True):
        out[items[cid]['attr'][0]:items[cid]['group'][1]] = entries[cid]
    n = len(new_sprites); old_tab = struct.unpack_from('<%dI' % scount, spr8, 8); body = spr8[8 + 4 * scount:]
    tab = [o + 4 * n if o else 0 for o in old_tab]; pos = 8 + 4 * (scount + n) + len(body); extra = bytearray()
    for b in new_sprites: tab.append(pos + len(extra)); extra += b
    new_spr = spr8[:4] + struct.pack('<I', scount + n) + struct.pack('<%dI' % len(tab), *tab) + body + extra

    if apply:
        for f in (port.DAT, port.SPR, XML):
            bak = f + '.bak-antes-house1098'
            if not os.path.exists(bak): shutil.copy2(f, bak)
        open(port.DAT, 'wb').write(out); open(port.SPR, 'wb').write(new_spr)
        x = open(XML, encoding='latin-1', newline='').read()
        for sid, name in xml_names.items():
            art = 'an' if name[0] in 'aeiou' else 'a'
            m = re.search(r'(<item id="%d")[^>]*?(/?>)(.*?)(</item>)' % sid, x, re.S); assert m, sid
            body = m.group(3)
            if sid in xml_rot:
                body = re.sub(r'\s*<attribute key="rotateTo" value="\d+"\s*/>', '', body)
                if xml_rot[sid]:
                    nl = '\r\n' if '\r\n' in body else '\n'
                    body = body.rstrip() + '%s\t\t<attribute key="rotateTo" value="%d" />%s\t' % (nl, xml_rot[sid], nl)
            x = x[:m.start()] + '%s article="%s" name="%s"%s%s%s' % (m.group(1), art, name, m.group(2), body, m.group(4)) + x[m.end():]
        open(XML, 'w', encoding='latin-1', newline='').write(x)
        print('gravado (backups *.bak-antes-house1098)')

if __name__ == '__main__':
    main('--apply' in sys.argv)
