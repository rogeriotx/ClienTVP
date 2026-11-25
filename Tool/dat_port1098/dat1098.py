import struct, sys
SRV = r'C:/Users/roger/Desktop/Server + Client + All Sources/Server/data/items/items.otb'
DAT = r'C:/Users/roger/Desktop/Server + Client + All Sources/Cliente/data/things/1098/Tibia.dat'

def parse_nodes(data, start):
    i = start; stack = []; root = None
    while i < len(data):
        b = data[i]
        if b == 0xFE:
            node = [data[i+1], bytearray(), []]
            (stack[-1][2].append(node) if stack else None)
            root = root or node; stack.append(node); i += 2; continue
        if b == 0xFF:
            stack.pop(); i += 1
            if not stack: break
            continue
        if b == 0xFD: i += 1; b = data[i]
        stack[-1][1].append(b); i += 1
    return root

def otb_map(path):
    root = parse_nodes(open(path, 'rb').read(), 4); s2c = {}
    for n in root[2]:
        p = bytes(n[1]); j = 4; sid = cid = None
        while j < len(p):
            a = p[j]; ln = struct.unpack_from('<H', p, j+1)[0]; v = p[j+3:j+3+ln]; j += 3+ln
            if a == 0x10: sid = struct.unpack('<H', v[:2])[0]
            elif a == 0x11: cid = struct.unpack('<H', v[:2])[0]
        if sid is not None: s2c[sid] = cid
    return s2c

NAMES = {0:'Ground',1:'GroundBorder',2:'OnBottom',3:'OnTop',4:'Container',5:'Stackable',6:'ForceUse',
 7:'MultiUse',8:'Writable',9:'WritableOnce',10:'Fluid',11:'Splash',12:'NotWalkable',13:'NotMoveable',
 14:'BlockProjectile',15:'NotPathable',16:'NoMoveAnim',17:'Pickupable',18:'Hangable',19:'HookSouth',
 20:'HookEast',21:'Rotateable',22:'Light',23:'DontHide',24:'Translucent',25:'Displacement',26:'Elevation',
 27:'LyingCorpse',28:'AnimateAlways',29:'MinimapColor',30:'LensHelp',31:'FullGround',32:'Look',33:'Cloth',
 34:'Market',35:'DefaultAction',36:'Wrapable',37:'Unwrapable',38:'TopEffect',254:'Usable'}
U16 = {0, 8, 9, 26, 29, 30, 33, 35}; U16x2 = {22, 25}

def read_items(path):
    d = open(path, 'rb').read()
    sig, ni, no, ne, nm = struct.unpack_from('<IHHHH', d, 0); i = 12; out = {}
    for cid in range(100, ni + 1):
        flags = {}
        while True:
            a = d[i]; i += 1
            if a == 255: break
            if a in U16: flags[NAMES[a]] = struct.unpack_from('<H', d, i)[0]; i += 2
            elif a in U16x2: flags[NAMES[a]] = struct.unpack_from('<HH', d, i); i += 4
            elif a == 34:
                cat, trade, show, ln = struct.unpack_from('<HHHH', d, i); i += 8
                name = d[i:i+ln].decode('latin-1'); i += ln + 4
                flags['Market'] = (cat, trade, show, name)
            else: flags[NAMES.get(a, a)] = True
        w, h = d[i], d[i+1]; i += 2; exact = 32
        if w > 1 or h > 1: exact = d[i]; i += 1
        layers, px, py, pz, fr = d[i], d[i+1], d[i+2], d[i+3], d[i+4]; i += 5
        anim = b''
        if fr > 1: anim = d[i:i + 1 + 4 + 1 + fr * 8]; i += len(anim)
        n = w*h*layers*px*py*pz*fr
        sprites = struct.unpack_from('<%dI' % n, d, i); i += 4*n
        out[cid] = dict(flags=flags, exact=exact, anim=anim, w=w, h=h, layers=layers, px=px, py=py, pz=pz, frames=fr, sprites=sprites)
    return out, (ni, no, ne, nm), i

if __name__ == '__main__':
    s2c = otb_map(SRV)
    items, counts, end = read_items(DAT)
    print('dat counts', counts, 'parsed to', end, 'file size', len(open(DAT, 'rb').read()))
    for sid in map(int, sys.argv[1:]):
        c = s2c.get(sid); it = items.get(c)
        f = {k: v for k, v in it['flags'].items() if k != 'Market'}
        print(sid, '->', c, '%dx%d L%d pat %dx%dx%d fr%d spr%d' % (it['w'], it['h'], it['layers'], it['px'], it['py'], it['pz'], it['frames'], len(it['sprites'])), f)
