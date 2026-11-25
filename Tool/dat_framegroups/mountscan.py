"""Lista montarias (mounts.xml do servidor) e outfits com pose montada no Tibia.dat 8.00
(extended, frame-durations e frame-groups ligados).

uso: python -I mountscan.py <Tibia.dat> <mounts.xml> [outfits.xml]
"""
import sys, os, re, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from datscan import R, read_attrs, read_group

def load_outfits(path):
    r = R(open(path, 'rb').read())
    r.u32(); ni, no, ne, nm = r.u16(), r.u16(), r.u16(), r.u16()
    for _ in range(100, ni + 1):
        read_attrs(r); read_group(r, False)
    outs = {}
    for cid in range(1, no + 1):
        read_attrs(r)
        outs[cid] = [read_group(r, True) for _ in range(r.u8())]
    return outs

def desc(groups):
    parts = []
    for g in groups:
        name = 'Idle' if g['type'] == 0 else 'Moving'
        a = g['anim']
        dur = ''
        if a:
            ds = sorted(set(mn for mn, mx in a['dur']))
            dur = ' %sms' % '/'.join(map(str, ds))
        parts.append('%s %d%s' % (name, g['phases'], dur))
    pz = max(g.get('pz', 1) for g in groups)
    return ' + '.join(parts)

def main(dat, mounts_xml, outfits_xml=None):
    outs = load_outfits(dat)
    mounts = re.findall(r'<mount[^>]*clientid="(\d+)"[^>]*name="([^"]+)"', open(mounts_xml, encoding='latin-1').read())
    print('MONTARIAS (%d):' % len(mounts))
    stats = collections.Counter()
    for cid, name in mounts:
        gs = outs.get(int(cid))
        if not gs:
            print('  %5s %-22s NAO EXISTE NO DAT' % (cid, name)); continue
        moving = [g for g in gs if g['type'] == 1] or gs
        stats[moving[0]['phases']] += 1
        print('  %5s %-22s %s' % (cid, name, desc(gs)))
    print('  frames Moving das montarias:', dict(sorted(stats.items())))
    if outfits_xml:
        looks = sorted({int(x) for x in re.findall(r'looktype="(\d+)"', open(outfits_xml, encoding='latin-1').read())})
        print('\nOUTFITS DE PLAYER (%d):' % len(looks))
        c = collections.Counter()
        for lt in looks:
            gs = outs.get(lt)
            if not gs: continue
            moving = [g for g in gs if g['type'] == 1] or gs
            key = (moving[0]['phases'], 'montado' if MOUNTED.get(lt) else 'sem pose montada')
            c[key] += 1
            print('  %5d %-40s %s' % (lt, desc(gs), key[1]))
        print('  resumo (frames Moving, pose):', dict(c))

MOUNTED = {}

if __name__ == '__main__':
    # pattern Z: le de novo so para saber quem tem pose montada (pz >= 2)
    import datscan
    orig = datscan.read_group
    def rg(r, creature):
        start = r.p
        gtype = r.u8() if creature else 0
        w, h = r.u8(), r.u8()
        if w > 1 or h > 1: r.u8()
        r.u8(); r.u8(); r.u8(); pz = r.u8()
        r.p = start
        g = orig(r, creature); g['pz'] = pz
        return g
    datscan.read_group = rg
    globals()['read_group'] = rg
    outs = load_outfits(sys.argv[1])
    for k, gs in outs.items():
        MOUNTED[k] = max(g['pz'] for g in gs) >= 2
    main(*sys.argv[1:])
