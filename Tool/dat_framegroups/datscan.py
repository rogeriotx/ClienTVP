import struct, sys, collections

U16 = {0, 8, 9, 25, 28, 29, 32, 34}  # OTC enum ids with a single u16 payload

class R:
    def __init__(s, b): s.b, s.p = b, 0
    def u8(s): v = s.b[s.p]; s.p += 1; return v
    def i8(s): v = struct.unpack_from('<b', s.b, s.p)[0]; s.p += 1; return v
    def u16(s): v = struct.unpack_from('<H', s.b, s.p)[0]; s.p += 2; return v
    def u32(s): v = struct.unpack_from('<I', s.b, s.p)[0]; s.p += 4; return v
    def i32(s): v = struct.unpack_from('<i', s.b, s.p)[0]; s.p += 4; return v
    def skip(s, n): s.p += n

def read_attrs(r):
    while True:
        a = r.u8()
        if a == 255: return
        if a == 8: continue
        if a > 8: a -= 1
        if a in U16: r.u16()
        elif a in (21, 24): r.u16(); r.u16()
        elif a == 33:
            r.skip(6); n = r.u16(); r.skip(n); r.skip(4)
        elif a == 38: r.skip(16)

def read_anim(r, phases):
    mode = r.u8(); loop = r.i32(); start = r.i8()
    d = [(r.u32(), r.u32()) for _ in range(phases)]
    return dict(async_=(mode == 0), loop=loop, start=start, dur=d)

def read_group(r, creature):
    gtype = r.u8() if creature else 0
    w, h = r.u8(), r.u8()
    if w > 1 or h > 1: r.u8()
    layers, px, py, pz, ph = r.u8(), r.u8(), r.u8(), r.u8(), r.u8()
    anim = read_anim(r, ph) if ph > 1 else None
    r.skip(4 * w * h * layers * px * py * pz * ph)
    return dict(type=gtype, phases=ph, anim=anim, px=px, py=py, layers=layers)

def main(path, show):
    r = R(open(path, 'rb').read())
    r.u32(); ni, no, ne, nm = r.u16(), r.u16(), r.u16(), r.u16()
    for cid in range(100, ni + 1):
        read_attrs(r); read_group(r, False)
    stats = collections.Counter(); samples = []
    for cid in range(1, no + 1):
        read_attrs(r)
        n = r.u8()
        groups = [read_group(r, True) for _ in range(n)]
        key = tuple((g['type'], g['phases']) for g in groups)
        stats[key] += 1
        if cid in show:
            samples.append((cid, groups))
    print('outfits', no, 'end offset ok' if r.p <= len(r.b) else 'OVERRUN')
    for k, v in stats.most_common(15):
        print('  groups(type,phases)=', k, 'count', v)
    for cid, gs in samples:
        print('looktype', cid)
        for g in gs:
            a = g['anim']
            print('   type', g['type'], 'phases', g['phases'],
                  'async' if a and a['async_'] else ('sync' if a else ''),
                  'start', a and a['start'], 'loop', a and a['loop'],
                  'dur', a and a['dur'])

if __name__ == '__main__':
    main(sys.argv[1], {int(x) for x in sys.argv[2:]})
