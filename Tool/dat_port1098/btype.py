def cov(m, x0, x1, y0, y1):
    n = (x1-x0)*(y1-y0); return sum(m[y*32+x] for y in range(y0, y1) for x in range(x0, x1)) / n
def classify(m):
    """lado = faixa fina no meio da borda do tile; L = dois lados vizinhos; canto externo = so o cantinho"""
    side = {'N': cov(m, 12, 20, 0, 3), 'S': cov(m, 12, 20, 29, 32), 'W': cov(m, 0, 3, 12, 20), 'E': cov(m, 29, 32, 12, 20)}
    on = [k for k in 'NSWE' if side[k] > 0.5]
    if len(on) == 2 and set(on) not in ({'N', 'S'}, {'W', 'E'}): return 'I_' + ''.join(on)
    if len(on) == 1: return 'E_' + on[0]
    c = {'NW': cov(m, 0, 4, 0, 4), 'NE': cov(m, 28, 32, 0, 4), 'SW': cov(m, 0, 4, 28, 32), 'SE': cov(m, 28, 32, 28, 32)}
    return 'O_' + max(c, key=c.get) if len(on) == 0 else '?%d' % len(on)
