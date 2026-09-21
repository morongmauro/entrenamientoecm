# -*- coding: utf-8 -*-
"""Genera los paths SVG de la figura muscular.

En vez de escribir rectangulos a mano, cada pieza se define como una
"manguera": una linea central con un radio en cada punto. Asi el brazo se
estrecha hacia la muneca y el muslo hacia la rodilla solo, sin cuadrar
coordenadas a ojo.
"""
import math

def _cr(pts):
    """Catmull-Rom -> cubicas. pts: [(x,y)]. Devuelve 'C x1 y1, x2 y2, x y ...'"""
    out = []
    n = len(pts)
    ext = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(n - 1):
        p0, p1, p2, p3 = ext[i], ext[i+1], ext[i+2], ext[i+3]
        c1 = (p1[0] + (p2[0]-p0[0])/6.0, p1[1] + (p2[1]-p0[1])/6.0)
        c2 = (p2[0] - (p3[0]-p1[0])/6.0, p2[1] - (p3[1]-p1[1])/6.0)
        out.append('C%s,%s %s,%s %s,%s' % (f(c1[0]), f(c1[1]), f(c2[0]), f(c2[1]), f(p2[0]), f(p2[1])))
    return ''.join(out)

def f(v):
    s = ('%.1f' % v).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'

def tube(spine, cap_top=True, cap_bot=True):
    """spine: [(x, y, r)] de arriba a abajo. Devuelve el path cerrado."""
    izq, der = [], []
    n = len(spine)
    for i, (x, y, r) in enumerate(spine):
        # normal perpendicular a la tangente de la linea central
        if i == 0:
            dx, dy = spine[1][0]-x, spine[1][1]-y
        elif i == n-1:
            dx, dy = x-spine[-2][0], y-spine[-2][1]
        else:
            dx, dy = spine[i+1][0]-spine[i-1][0], spine[i+1][1]-spine[i-1][1]
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy/L, dx/L
        izq.append((x - nx*r, y - ny*r))
        der.append((x + nx*r, y + ny*r))
    d = 'M%s,%s' % (f(izq[0][0]), f(izq[0][1]))
    d += _cr(izq)
    # tapa de abajo
    if cap_bot:
        r = spine[-1][2]
        d += 'A%s,%s 0 0 0 %s,%s' % (f(r), f(r), f(der[-1][0]), f(der[-1][1]))
    else:
        d += 'L%s,%s' % (f(der[-1][0]), f(der[-1][1]))
    d += _cr(list(reversed(der)))
    if cap_top:
        r = spine[0][2]
        d += 'A%s,%s 0 0 0 %s,%s' % (f(r), f(r), f(izq[0][0]), f(izq[0][1]))
    d += 'Z'
    return d

def espejo(d):
    """Refleja un path sobre x=50. Solo entiende M/C/L/A/Z con pares x,y."""
    import re
    out, i = [], 0
    tok = re.findall(r'[MCLAZ]|-?\d*\.?\d+', d)
    while i < len(tok):
        t = tok[i]
        if t == 'Z':
            out.append('Z'); i += 1; continue
        if t == 'M' or t == 'L':
            x, y = float(tok[i+1]), float(tok[i+2])
            out.append('%s%s,%s' % (t, f(100-x), f(y))); i += 3; continue
        if t == 'C':
            vals = [float(v) for v in tok[i+1:i+7]]
            for k in (0, 2, 4): vals[k] = 100 - vals[k]
            out.append('C%s,%s %s,%s %s,%s' % tuple(f(v) for v in vals)); i += 7; continue
        if t == 'A':
            rx, ry, rot, laf, sf, x, y = [float(v) for v in tok[i+1:i+8]]
            # al reflejar se invierte el sentido de barrido
            out.append('A%s,%s %s %s %s %s,%s' % (f(rx), f(ry), f(rot), int(laf), 1-int(sf), f(100-x), f(y)))
            i += 8; continue
        i += 1
    return ''.join(out)

# ════════ SILUETA ════════════════════════════════════════════════════
# 100 x 220. Cabeza arriba, pies abajo. 1 unidad ~ 1 cm de persona.
CABEZA = 'M50,3.5c4.7,0 8.3,4.4 8.3,10.2c0,6.1 -3.6,11 -8.3,11c-4.7,0 -8.3,-4.9 -8.3,-11c0,-5.8 3.6,-10.2 8.3,-10.2z'
CUELLO = tube([(50,23,4.6),(50,29,5.2)], cap_top=False, cap_bot=False)

# Tronco: hombros anchos, cintura estrecha, cadera. Incluye el casquete del
# deltoides para que el brazo pueda colgar separado sin dejar hueco.
TRONCO = ('M50,27.5'
          'C43.5,27.5 38,29.5 33.5,32.5'
          'C29,35.5 26.8,39.5 26.5,44.5'
          'C26.2,49.5 27.5,54 29.5,57.5'
          'C32,62 33.8,66.5 34.6,71.5'
          'C35.2,75.5 35,79.5 34.2,84'
          'C33.4,88.5 33,93 33.4,97.5'
          'C33.7,101 34.4,104 35.4,106.5'
          'L64.6,106.5'
          'C65.6,104 66.3,101 66.6,97.5'
          'C67,93 66.6,88.5 65.8,84'
          'C65,79.5 64.8,75.5 65.4,71.5'
          'C66.2,66.5 68,62 70.5,57.5'
          'C72.5,54 73.8,49.5 73.5,44.5'
          'C73.2,39.5 71,35.5 66.5,32.5'
          'C62,29.5 56.5,27.5 50,27.5Z')

BRAZO_IZQ = tube([
    (28.5, 47, 5.6),   # bajo el deltoides
    (26.0, 57, 5.9),   # biceps / triceps
    (23.8, 70, 5.4),
    (22.0, 82, 4.2),   # codo
    (20.2, 94, 4.3),   # antebrazo
    (18.4, 107, 3.4),
    (17.2, 116, 2.8),  # muneca
    (16.2, 124, 3.6),  # mano
], cap_top=False)

PIERNA_IZQ = tube([
    (42.5, 104, 8.4),  # cadera / arranque del muslo
    (41.0, 118, 8.0),
    (39.8, 134, 7.0),
    (39.0, 150, 5.2),  # rodilla
    (38.4, 163, 5.6),  # gemelo
    (37.8, 180, 4.0),
    (37.4, 196, 2.9),  # tobillo
], cap_top=False, cap_bot=False)
PIE_IZQ = 'M34.5,196C33.5,201 33,205 33.2,208C33.4,210.5 35,211.5 38.5,211.5C42,211.5 43.5,210.5 43.4,208C43.3,204.5 42,200.5 40.3,196Z'

CUERPO = [CABEZA, CUELLO, TRONCO,
          BRAZO_IZQ, espejo(BRAZO_IZQ),
          PIERNA_IZQ, espejo(PIERNA_IZQ),
          PIE_IZQ, espejo(PIE_IZQ)]

# ════════ MUSCULOS ═══════════════════════════════════════════════════
def blob(cx, cy, rx, ry, inclina=0.0):
    """Ovalo simple, opcionalmente inclinado (para pectorales, dorsales...)."""
    k = 0.5523
    pts = [(cx, cy-ry), (cx+rx, cy), (cx, cy+ry), (cx-rx, cy)]
    c = [((cx+rx*k, cy-ry), (cx+rx, cy-ry*k)),
         ((cx+rx, cy+ry*k), (cx+rx*k, cy+ry)),
         ((cx-rx*k, cy+ry), (cx-rx, cy+ry*k)),
         ((cx-rx, cy-ry*k), (cx-rx*k, cy-ry))]
    def rot(p):
        if not inclina: return p
        a = math.radians(inclina)
        dx, dy = p[0]-cx, p[1]-cy
        return (cx + dx*math.cos(a) - dy*math.sin(a), cy + dx*math.sin(a) + dy*math.cos(a))
    d = 'M%s,%s' % tuple(f(v) for v in rot(pts[0]))
    for i in range(4):
        a, b = rot(c[i][0]), rot(c[i][1])
        e = rot(pts[(i+1) % 4])
        d += 'C%s,%s %s,%s %s,%s' % (f(a[0]),f(a[1]),f(b[0]),f(b[1]),f(e[0]),f(e[1]))
    return d + 'Z'

def par(d):
    return [d, espejo(d)]

FRENTE = {}
# — hombro y pecho —
FRENTE['deltoide_anterior'] = par(tube([(34,35.5,4.0),(31.5,41.5,4.8),(30.5,48,4.4)]))
FRENTE['deltoide_lateral']  = par(tube([(31,37,3.2),(28.8,44,4.2),(28.2,51,3.6)]))
FRENTE['trapecio_superior'] = ['M50,28.2C44.6,28.2 39.8,29.6 35.6,32.4'
                              'C33.8,33.6 33,35.2 33.4,37.2C39.2,34.6 44.8,33.3 50,33.3'
                              'C55.2,33.3 60.8,34.6 66.6,37.2C67,35.2 66.2,33.6 64.4,32.4'
                              'C60.2,29.6 55.4,28.2 50,28.2Z']
FRENTE['pectoral_superior'] = par('M49,36.5C44,36.2 39.5,37 36,38.8C34.5,39.6 33.8,40.8 34,42.2L49,43.6Z')
FRENTE['pectoral_mayor']    = par('M49,44.6L34.2,43.2C34.6,47.5 36,51.5 38.4,54.4C41.2,57.8 45,59.4 49,59.2Z')
# — brazo —
FRENTE['biceps']    = par(tube([(26.6,55,4.2),(25,63,4.4),(23.6,72,3.6)]))
FRENTE['braquial']  = par(tube([(23.2,73,2.6),(22.2,80,2.6)]))
FRENTE['antebrazo'] = par(tube([(21.6,86,4.0),(19.8,97,3.9),(18.2,109,3.0)]))
# — tronco —
FRENTE['recto_abdominal'] = ['M44.2,60.5C43.6,70 43.6,79.5 44.4,89C44.6,91.5 45.8,92.8 48,93.2'
                             'L52,93.2C54.2,92.8 55.4,91.5 55.6,89C56.4,79.5 56.4,70 55.8,60.5Z']
FRENTE['oblicuos']   = par('M43.2,61C39.8,61.2 37.2,62.5 35.6,64.8C34.6,69.5 34.4,74.5 35,79.5'
                           'C35.4,83.5 37,86.5 39.8,88.5C41.4,89.6 42.6,89 42.8,87C42.2,78.4 42.3,69.7 43.2,61Z')
FRENTE['transverso'] = [blob(50, 90, 9.4, 4.4)]
FRENTE['psoas']      = par(blob(45.5, 100, 3.4, 5.0, 8))
# — pierna —
FRENTE['cuadriceps'] = par(tube([(42,110,7.4),(40.6,124,7.0),(39.6,138,5.6),(39,148,4.2)]))
FRENTE['aductores']  = par(tube([(46.5,110,3.4),(45.5,124,3.4),(44.6,136,2.6)]))
FRENTE['abductores'] = par(tube([(35.5,106,3.4),(34.6,116,3.2),(34.2,124,2.4)]))
FRENTE['tibial_anterior'] = par(tube([(37.4,158,3.2),(36.8,172,3.0),(36.4,186,2.2)]))
FRENTE['gemelos'] = []
FRENTE['cuerpo_completo'] = []

ESPALDA = {}
ESPALDA['trapecio_superior'] = ['M50,29.5C45,29.5 40.5,30.8 36.5,33.4C34.8,34.5 34.2,36 35,37.6'
                                'C39.8,36 44.8,35.2 50,35.2C55.2,35.2 60.2,36 65,37.6'
                                'C65.8,36 65.2,34.5 63.5,33.4C59.5,30.8 55,29.5 50,29.5Z']
ESPALDA['trapecio_medio']    = ['M50,36.4C44.4,36.4 39.2,37.3 34.4,39.2C34.2,44 34.8,48.4 36.2,52.4'
                                'C41,50.8 45.6,50 50,50C54.4,50 59,50.8 63.8,52.4'
                                'C65.2,48.4 65.8,44 65.6,39.2C60.8,37.3 55.6,36.4 50,36.4Z']
ESPALDA['trapecio_inferior'] = ['M50,51.4C47,51.4 44.2,51.8 41.6,52.6C43.4,58.4 46.2,63.6 50,68.2'
                                'C53.8,63.6 56.6,58.4 58.4,52.6C55.8,51.8 53,51.4 50,51.4Z']
ESPALDA['romboides']         = par('M49,38.6C45,38.8 41.2,39.6 37.6,41C37.6,45 38.2,48.6 39.4,51.8'
                                   'C42.4,51 45.6,50.5 49,50.3Z')
ESPALDA['redondo_mayor']     = par(blob(34.5, 49, 4.6, 3.2, -25))
ESPALDA['dorsal_ancho']      = par('M33.8,52C33.2,58 33.4,64 34.4,70C35.2,75 37,79.2 40,82.6'
                                   'C42.6,85.5 44.4,84.8 44.6,80.8C45,72 45.4,63.4 46,55'
                                   'C42.2,52.8 38.2,52 33.8,52Z')
ESPALDA['erectores']         = par(tube([(47,50,2.4),(46.6,62,2.6),(46.4,76,2.8),(46.6,88,2.6)]))
ESPALDA['deltoide_posterior']= par(tube([(34,35.5,4.0),(31.4,42.5,4.8),(30.6,49.5,4.2)]))
ESPALDA['triceps']           = par(tube([(26.6,54,4.4),(25,64,4.6),(23.4,74,3.8)]))
ESPALDA['antebrazo']         = par(tube([(21.6,86,4.0),(19.8,97,3.9),(18.2,109,3.0)]))
ESPALDA['gluteo_mayor']      = par('M49,89.6C44.2,89.2 39.8,90.4 36,93.2C34.6,96.6 34.2,100.2 34.8,103.8'
                                   'C35.2,105.8 36.2,106.8 38,106.8L49,106.8Z')
ESPALDA['gluteo_medio']      = par(blob(36, 93, 4.4, 3.4, -18))
ESPALDA['isquiotibiales']    = par(tube([(42,112,7.6),(40.8,126,7.2),(39.8,138,6.0),(39.2,148,4.4)]))
ESPALDA['gemelos']           = par(tube([(38.4,158,5.2),(37.9,170,4.8),(37.6,182,3.0)]))
ESPALDA['deltoide_lateral']  = par(tube([(31,37,3.2),(28.8,44,4.2),(28.2,51,3.6)]))
ESPALDA['abductores']        = par(tube([(35.4,104,3.4),(34.8,114,3.2),(34.4,122,2.4)]))
ESPALDA['manguito_rotador']  = par(blob(37.5, 41.5, 4.4, 3.2, -22))
ESPALDA['cuerpo_completo']   = []

# ════════ SALIDA ═════════════════════════════════════════════════════
def js_lista(nombre, lista, sangria='  '):
    cuerpo = ',\n'.join("%s'%s'" % (sangria, d) for d in lista)
    return 'const %s = [\n%s,\n];' % (nombre, cuerpo)

def js_mapa(nombre, mapa):
    lineas = []
    ancho = max(len(k) for k in mapa) + 1
    for k, v in mapa.items():
        if not v:
            lineas.append('  %-*s [],' % (ancho, k + ':'))
        else:
            paths = ', '.join("'%s'" % d for d in v)
            lineas.append('  %-*s [%s],' % (ancho, k + ':', paths))
    return 'const %s = {\n%s\n};' % (nombre, '\n'.join(lineas))

# ── El contrato ──────────────────────────────────────────────────────────
# `src/musculos.js` dice, para cada slug, en que silueta debe aparecer. Si
# aqui falta una forma el musculo simplemente no se pinta y nadie se entera:
# el ejercicio sale con el cuerpo en blanco y parece que no trabaja nada. Por
# eso la generacion falla en vez de avisar.
import re as _re
_src = open('/home/user/entrenamientoecm/src/musculos.js').read()
_contrato = {m.group(1): m.group(2) for m in
             _re.finditer(r"slug:\s*'([a-z_]+)'.*?cara:\s*'(frente|espalda|ambas)'", _src)}
assert _contrato, 'no pude leer musculos.js'

_con_forma = lambda d: {k for k, v in d.items() if v}
_f, _e = _con_forma(FRENTE), _con_forma(ESPALDA)
_fallos = []
for _slug, _cara in _contrato.items():
    if _slug == 'cuerpo_completo':
        continue          # no tiene forma propia: tiñe la silueta entera
    _esp_f, _esp_e = _cara in ('frente', 'ambas'), _cara in ('espalda', 'ambas')
    if (_slug in _f) != _esp_f or (_slug in _e) != _esp_e:
        _fallos.append('%s: el contrato dice %s, las formas dicen %s'
                       % (_slug, _cara,
                          ('frente+espalda' if _slug in _f and _slug in _e else
                           'frente' if _slug in _f else
                           'espalda' if _slug in _e else 'ninguna')))
for _slug in (_f | _e) - set(_contrato):
    _fallos.append('%s: hay forma pero no existe en musculos.js' % _slug)

if _fallos:
    raise SystemExit('CONTRATO ROTO:\n  ' + '\n  '.join(_fallos))
print('contrato: los %d slugs calzan' % len(_contrato))

CABECERA = """// ─────────────────────────────────────────────────────────────────────────
// FORMAS DE LA FIGURA MUSCULAR  ·  \u26a0 ARCHIVO GENERADO
//
// No lo edites a mano. Sale de `carga/gen-figura.py`, que dibuja brazos,
// piernas y musculos recorriendo una linea central con un radio por punto.
// Si tocas una coordenada aqui, el proximo `python3 carga/gen-figura.py` se
// la lleva por delante.
//
// Los slugs son los de la tabla `musculos`. Un slug sin forma simplemente no
// se pinta; no rompe nada.
// ─────────────────────────────────────────────────────────────────────────
"""

SALIDAS = [
    # (ruta, prefijo de cada const)
    ('/tmp/claude-0/-home-user/4888e79f-cb18-547b-956d-b50bb1c5649a/scratchpad/figura-formas.js', 'const '),
    ('/home/user/entrenamientoecm/src/figura-formas.js', 'export const '),
]

for ruta, pref in SALIDAS:
    cuerpo = (js_lista('FIG_CUERPO', CUERPO) + '\n\n'
              + js_mapa('FIG_FRENTE', FRENTE) + '\n\n'
              + js_mapa('FIG_ESPALDA', ESPALDA) + '\n')
    if pref != 'const ':
        cuerpo = cuerpo.replace('const ', pref)
        cuerpo = CABECERA + '\n' + cuerpo
    with open(ruta, 'w') as fh:
        fh.write(cuerpo)
    print('escrito', ruta)

print('cuerpo:', len(CUERPO), 'piezas')
print('frente:', len(FRENTE), 'espalda:', len(ESPALDA))
