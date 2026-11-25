import sys, os, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from datscan import R, read_attrs, read_group
r = R(open(sys.argv[1],'rb').read()); r.u32(); ni,no,ne,nm = r.u16(),r.u16(),r.u16(),r.u16()
def stats(name, groups):
    c = collections.Counter()
    for g in groups:
        a = g['anim']
        if a: c[(a['async_'], a['loop'], a['start'], tuple(sorted(set(a['dur']))))] += 1
    print(name, c.most_common(4))
it = []
for cid in range(100, ni+1): read_attrs(r); it.append(read_group(r, False))
stats('items', it)
cr = []
for cid in range(1, no+1):
    read_attrs(r); cr += [read_group(r, True) for _ in range(r.u8())]
stats('outfits', cr)
ef = []
for cid in range(1, ne+1): read_attrs(r); ef.append(read_group(r, False))
stats('effects', ef)
mi = []
for cid in range(1, nm+1): read_attrs(r); mi.append(read_group(r, False))
stats('missiles', mi); print('end', r.p, len(r.b))
