"""Leitor do Tibia.dat 8.00 do TVP (formato 7.8-8.54 + frame-durations + frame-groups so em outfits).
Retorna por item: span de atributos e span do grupo (bytes), para permitir troca no lugar."""
import struct

DAT = r'C:/Users/roger/Downloads/TVP/TVP-Ravenor-Client/TVP-Ravenor-Client/data/things/800/Tibia.dat'
# raw 8.00: 0 Ground u16 | 1 Clip | 2 Bottom | 3 Top | 4 Container | 5 Stackable | 6 ForceUse | 7 MultiUse
# 8 Charges | 9 Writable u16 | 10 WritableOnce u16 | 11 Fluid | 12 Splash | 13 NotWalkable | 14 NotMoveable
# 15 BlockProj | 16 NotPathable | 17 Pickupable | 18 Hangable | 19 HookS | 20 HookE | 21 Rotateable
# 22 Light u16 u16 | 23 DontHide | 24 Translucent | 25 Displacement u16 u16 | 26 Elevation u16 | 27 LyingCorpse
# 28 AnimateAlways | 29 MinimapColor u16 | 30 LensHelp u16 | 31 FullGround | 32 Look | 33 Cloth u16 | 34 Market | 35 DefaultAction u16
RAW_U16 = {0, 9, 10, 26, 29, 30, 33, 35}
RAW_U16x2 = {22, 25}

def parse_attrs(d, i):
    flags = {}
    while True:
        a = d[i]; i += 1
        if a == 255: return flags, i
        if a in RAW_U16: flags[a] = struct.unpack_from('<H', d, i)[0]; i += 2
        elif a in RAW_U16x2: flags[a] = struct.unpack_from('<HH', d, i); i += 4
        elif a == 34:
            ln = struct.unpack_from('<H', d, i + 6)[0]; i += 8 + ln + 4; flags[a] = True
        elif a == 39: i += 16; flags[a] = True
        else: flags[a] = True

def parse_group(d, i):
    w, h = d[i], d[i+1]; i += 2
    if w > 1 or h > 1: i += 1
    layers, px, py, pz, ph = d[i:i+5]; i += 5
    if ph > 1: i += 1 + 4 + 1 + 8 * ph
    n = w*h*layers*px*py*pz*ph
    spr = struct.unpack_from('<%dI' % n, d, i); i += 4*n
    return dict(w=w, h=h, layers=layers, px=px, py=py, pz=pz, ph=ph, sprites=spr), i

def read(path=DAT):
    d = open(path, 'rb').read()
    sig, ni, no, ne, nm = struct.unpack_from('<IHHHH', d, 0); i = 12; items = {}
    for cid in range(100, ni + 1):
        a0 = i; flags, i = parse_attrs(d, i); g0 = i; grp, i = parse_group(d, i)
        items[cid] = dict(flags=flags, attr=(a0, g0), group=(g0, i), **grp)
    return d, items, (sig, ni, no, ne, nm), i
