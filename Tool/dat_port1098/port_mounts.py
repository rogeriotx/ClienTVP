"""Port 5: montarias do Hellgrave (10.98) para o Tibia.dat 8.00 + mounts.xml do pbOT.
- Montaria que o pbOT ja tem (mesmo id/clientid): compara a pose parada com a do 10.98 pixel a pixel;
  se for a mesma montaria, o outfit e atualizado com o do 10.98 (ganha Idle animado etc.).
  Se nao parecer a mesma, fica como esta e aparece no relatorio.
- Montaria nova: vai no mesmo clientid se esse slot estiver vazio no 8.00; senao vira outfit novo no fim.
- Sprites iguais (mesmos pixels) aos ja existentes no outfit antigo sao reaproveitados.
Uso: python port_mounts.py [--apply]   (backups *.bak-antes-mounts)"""
import struct, sys, os, re, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dat800, dat1098, port, outfits

DAT, SPR = port.DAT, port.SPR
XML = 'X:/data/XML/mounts.xml'
XML98 = 'C:/Users/roger/Desktop/Server + Client + All Sources/Server/data/XML/mounts.xml'
BAK = '.bak-antes-mounts'
SAME = 0.85  # fracao minima de pixels iguais na pose parada para considerar a mesma montaria


def mounts(path):
    x = open(path, encoding='latin-1').read()
    return [dict(id=int(m.group(1)), cid=int(m.group(2)), name=m.group(3), line=m.group(0))
            for m in re.finditer(r'<mount id="(\d+)" clientid="(\d+)" name="([^"]+)"[^>]*/>', x)]


def pixels_800(spr, sid):
    """{pos: rgb} de um sprite do spr 8.00 (rgb, sem alpha)."""
    out = {}
    if not sid: return out
    off = struct.unpack_from('<I', spr, 8 + (sid - 1) * 4)[0]
    if not off: return out
    size = struct.unpack_from('<H', spr, off + 3)[0]; i = off + 5; end = i + size; p = 0
    while i < end:
        t, c = struct.unpack_from('<HH', spr, i); i += 4; p += t
        for _ in range(c): out[p] = bytes(spr[i:i+3]); i += 3; p += 1
    return out


def pixels_98(spr98, sid):
    px = port.decode_rgba(spr98, sid)
    return {i: bytes(x[:3]) for i, x in enumerate(px) if x is not None and x[3] >= 128}


def idle_sprites(o):
    g = o['groups'][0]
    return g['spr'][:g['w'] * g['h'] * g['layers'] * g['px'] * g['py'] * g['pz']]


def similarity(a, b):
    keys = set(a) | set(b)
    if not keys: return 1.0
    return sum(1 for k in keys if a.get(k) == b.get(k)) / len(keys)


def empty(o):
    return not any(s for g in o['groups'] for s in g['spr'])


def main(apply):
    dat, items, (sig, ni, no, ne, nm), _ = dat800.read(DAT)
    _, _, _, o8 = outfits.read(DAT, '800'); _, _, _, o98 = outfits.read(dat1098.DAT, '1098')
    spr = open(SPR, 'rb').read(); ssig, scount = struct.unpack_from('<II', spr, 0)
    spr98 = open(port.SPR1098, 'rb').read()
    pb = {m['id']: m for m in mounts(XML)}; hg = mounts(XML98)

    new_sprites = []; enc = {}
    def add_sprite(sid98, reuse):
        if sid98 == 0: return 0
        if sid98 in reuse: return reuse[sid98]
        if sid98 not in enc:
            blob = port.encode_rgb(port.decode_rgba(spr98, sid98))
            if blob is None: enc[sid98] = 0
            else: new_sprites.append(blob); enc[sid98] = scount + len(new_sprites)
        return enc[sid98]

    def build(oid98, old=None):
        """bytes do outfit 10.98 (attrs do 8.00 quando ha outfit antigo), reaproveitando sprites iguais do antigo."""
        reuse = {}
        if old:
            olds = {}
            for g in old['groups']:
                for s in g['spr']:
                    if s and s not in olds: olds[s] = pixels_800(spr, s)
            index = {}
            for s, px in olds.items(): index.setdefault(frozenset(px.items()), s)
            for g in o98[oid98]['groups']:
                for s in g['spr']:
                    if s and s not in reuse:
                        hit = index.get(frozenset(pixels_98(spr98, s).items()))
                        if hit: reuse[s] = hit
        body = bytearray(old['raw_attr'] if old else b'\xff') + bytes([len(o98[oid98]['groups'])])
        for g in o98[oid98]['groups']:
            body += outfits.write_group(dict(g, spr=[add_sprite(s, reuse) for s in g['spr']]))
        return body, len(reuse)

    replace = {}; append = []; xml_add = []; report = []
    for m in hg:
        c = m['cid']; o = o98[c]
        p = pb.get(m['id'])
        if p and p['name'].lower() == m['name'].lower():
            old = o8[p['cid']]
            a = [pixels_800(spr, s) for s in idle_sprites(old)]
            b = [pixels_98(spr98, s) for s in idle_sprites(o)]
            if len(a) != len(b):
                report.append('%3d %-20s cid %d: formato diferente, mantido' % (m['id'], m['name'], p['cid'])); continue
            sim = sum(similarity(x, y) for x, y in zip(a, b)) / len(a)
            if sim < SAME:
                report.append('%3d %-20s cid %d: parecida %.0f%%, mantida' % (m['id'], m['name'], p['cid'], sim * 100)); continue
            body, reused = build(c, old)
            if body == bytearray(dat[old['span'][0]:old['span'][1]]):
                report.append('%3d %-20s cid %d: igual (%.0f%%)' % (m['id'], m['name'], p['cid'], sim * 100)); continue
            replace[p['cid']] = body
            report.append('%3d %-20s cid %d: ATUALIZADA (%.0f%% igual, grupos %s, %d sprites reaproveitados)' % (
                m['id'], m['name'], p['cid'], sim * 100, [(g['type'], g['ph']) for g in o['groups']], reused))
        elif p:
            report.append('%3d %-20s: id ja usado por %s no pbOT, ignorada' % (m['id'], m['name'], p['name']))
        else:
            if c <= no and empty(o8[c]):
                replace[c] = build(c, o8[c])[0]; newc = c; where = 'slot vazio %d' % c
            else:
                newc = no + 1 + len(append); append.append(build(c)[0]); where = 'outfit NOVO %d' % newc
            xml_add.append(m['line'].replace('clientid="%d"' % c, 'clientid="%d"' % newc))
            report.append('%3d %-20s 10.98 %d -> %s' % (m['id'], m['name'], c, where))

    print('\n'.join(report))
    out = bytearray(dat)
    for oid in sorted(replace, reverse=True):
        a, b = o8[oid]['span']; out[a:b] = replace[oid]
    out[len(out) - len(dat) + o8[no]['span'][1]:len(out) - len(dat) + o8[no]['span'][1]] = b''.join(append)
    struct.pack_into('<H', out, 6, no + len(append))

    k = len(new_sprites); shift = 4 * k
    tab = [o + shift if o else 0 for o in struct.unpack_from('<%dI' % scount, spr, 8)]
    body = spr[8 + 4 * scount:]; pos = 8 + 4 * (scount + k) + len(body); extra = bytearray()
    for b in new_sprites: tab.append(pos + len(extra)); extra += b
    new_spr = struct.pack('<II', ssig, scount + k) + struct.pack('<%dI' % len(tab), *tab) + body + extra

    xs = open(XML, 'rb').read().decode('latin-1'); nl = '\r\n' if '\r\n' in xs else '\n'
    if xml_add: xs = xs.replace('</mounts>', nl.join('\t' + l for l in xml_add) + nl + '</mounts>')
    print('atualizadas/no lugar %d | outfits novos %d (%d -> %d) | sprites novos %d | mounts.xml +%d' % (
        len(replace), len(append), no, no + len(append), k, len(xml_add)))
    if apply:
        for f in (DAT, SPR, XML):
            if not os.path.exists(f + BAK): shutil.copy2(f, f + BAK)
        # grava tudo em .tmp e so troca no fim: se um arquivo estiver travado (cliente aberto), nada muda
        data = {DAT: out, SPR: new_spr, XML: xs.encode('latin-1')}
        for f, b in data.items(): open(f + '.tmp', 'wb').write(b)
        done = []
        try:
            for f in (SPR, DAT, XML): os.replace(f + '.tmp', f); done.append(f)
        except PermissionError:
            for f in done: shutil.copy2(f + BAK, f)
            for f in data:
                if os.path.exists(f + '.tmp'): os.remove(f + '.tmp')
            sys.exit('arquivo travado (feche o cliente); nada foi alterado')
        _, h2, _, chk = outfits.read(DAT, '800'); dat800.read(DAT)
        assert h2[2] == no + len(append) and len(chk) == no + len(append)
        print('gravado e relido OK (backups *%s)' % BAK)


if __name__ == '__main__':
    main('--apply' in sys.argv)
