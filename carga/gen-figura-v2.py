# -*- coding: utf-8 -*-
"""Figura muscular v2: silueta de cuerpo real y los musculos que la cubren.

La v1 (gen-figura.py) armaba el cuerpo con "mangueras" sueltas y pintaba
solo los musculos trabajados: salia un maniqui palido con manchas. Esta
dibuja UNA silueta continua con proporciones de persona entrenada (hombros
anchos, cintura, cadera, rodilla, gemelo) y la cubre ENTERA de musculos,
como un mapa: se ve el cuerpo completo en gris y lo que trabaja el ejercicio
se enciende en color. Es como lo leen las apps de fuerza que la gente ya
conoce.

Cada forma es una curva cerrada que pasa por una lista de puntos (Catmull-
Rom), dibujada en la mitad izquierda del lienzo y reflejada sobre x=50.
Lienzo 100 x 220, igual que la v1, para que el componente no cambie.

    python3 carga/gen-figura-v2.py > ../mealtracker/src/figura-formas-v2.js
"""
import sys

def f(v):
    s = ('%.1f' % v).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'

def cerrada(pts, tension=1.0):
    """Curva cerrada que pasa por todos los puntos."""
    n = len(pts)
    d = 'M%s,%s' % (f(pts[0][0]), f(pts[0][1]))
    for i in range(n):
        p0, p1, p2, p3 = pts[(i-1) % n], pts[i], pts[(i+1) % n], pts[(i+2) % n]
        c1 = (p1[0] + (p2[0]-p0[0])/6.0*tension, p1[1] + (p2[1]-p0[1])/6.0*tension)
        c2 = (p2[0] - (p3[0]-p1[0])/6.0*tension, p2[1] - (p3[1]-p1[1])/6.0*tension)
        d += 'C%s,%s %s,%s %s,%s' % (f(c1[0]), f(c1[1]), f(c2[0]), f(c2[1]), f(p2[0]), f(p2[1]))
    return d + 'Z'

def espejo_pts(pts):
    return [(100 - x, y) for x, y in reversed(pts)]

def par(pts, tension=1.0):
    return [cerrada(pts, tension), cerrada(espejo_pts(pts), tension)]

# ════════ SILUETA ════════════════════════════════════════════════════
# Media silueta, de la nuca al empeine y de vuelta por dentro de la pierna.
# Proporciones de persona entrenada, unas 8 cabezas de alto. El brazo cuelga
# separado del tronco desde la axila.
MEDIA = [
    (45.0, 21.0),                       # cuello
    (44.8, 26.6),
    (40.4, 29.2), (34.6, 31.2),         # caida del trapecio
    (29.2, 33.2), (25.8, 37.2),         # hombro (deltoides)
    (24.0, 43.0), (23.4, 50.0),
    (22.4, 57.0), (21.6, 64.0),         # biceps
    (21.0, 70.4),                       # codo
    (19.8, 78.0), (18.6, 87.0),         # antebrazo
    (17.4, 95.0), (17.0, 100.0),        # muneca
    (16.2, 105.0), (16.6, 111.0),       # mano
    (18.6, 114.4), (20.8, 112.2),
    (21.6, 106.0), (22.2, 100.4),       # muneca por dentro
    (23.6, 93.0), (25.8, 84.0),
    (27.0, 76.0), (27.6, 71.0),         # codo por dentro
    (28.6, 63.0), (29.8, 56.0),
    (31.0, 51.4),                       # axila
    (32.2, 58.0), (33.2, 66.0),         # dorsal / costado
    (34.4, 75.0), (33.8, 83.0),         # cintura
    (31.8, 92.0), (30.8, 101.0),        # cadera
    (30.8, 111.0), (31.6, 123.0),       # muslo por fuera
    (33.2, 134.0), (34.6, 142.0),       # rodilla
    (33.6, 150.0), (33.0, 158.0),       # gemelo por fuera
    (34.0, 169.0), (35.8, 181.0),
    (36.6, 190.0),                      # tobillo
    (35.4, 196.0), (35.2, 200.2),       # pie
    (38.2, 202.2), (42.8, 201.8),
    (44.0, 198.4), (43.4, 192.0),
    (43.0, 185.0), (44.2, 175.0),       # por dentro de la pierna
    (45.8, 163.0), (46.2, 153.0),
    (45.4, 146.0), (46.0, 138.0),       # rodilla por dentro
    (47.4, 128.0), (48.6, 118.0),
    (49.4, 110.4), (50.0, 107.6),       # entrepierna
]

def silueta():
    der = [(100 - x, y) for x, y in reversed(MEDIA[:-1])]
    pts = MEDIA + der[1:]
    return cerrada(pts)

CABEZA = cerrada([(50, 2.6), (55.6, 4.8), (58.2, 11.2), (57.2, 18.0), (53.6, 23.0),
                  (50, 24.4), (46.4, 23.0), (42.8, 18.0), (41.8, 11.2), (44.4, 4.8)])

# Músculos profundos: tapados por otros, solo se dibujan cuando el ejercicio
# los trabaja (en gris taparían al que sí se ve).
PROFUNDOS = ['transverso', 'romboides']

# ════════ MUSCULOS · FRENTE ══════════════════════════════════════════
F = {}
F['trapecio_superior'] = par([(45.4, 24.8), (41.6, 28.2), (36.0, 30.8), (32.4, 32.4), (36.6, 33.6), (42.4, 32.4), (45.8, 30.8)])
F['deltoide_anterior'] = par([(34.2, 33.8), (30.2, 35.0), (27.4, 38.6), (26.8, 44.2), (28.0, 49.4), (30.2, 48.2), (31.6, 43.4), (33.4, 38.8)])
F['deltoide_lateral']  = par([(28.6, 34.6), (25.4, 38.0), (24.2, 43.6), (24.6, 49.0), (26.6, 49.8), (26.2, 43.6), (27.2, 38.6)])
F['pectoral_superior'] = par([(49.2, 34.4), (44.0, 33.8), (38.6, 34.6), (34.8, 36.8), (33.8, 39.4), (38.4, 39.6), (44.0, 39.6), (49.2, 40.0)])
F['pectoral_mayor']    = par([(49.2, 41.0), (43.6, 40.6), (37.6, 40.6), (33.6, 41.2), (31.8, 44.2), (33.4, 48.4), (37.4, 51.6), (42.8, 52.8), (47.4, 52.4), (49.2, 51.4)])
F['biceps']    = par([(30.0, 51.0), (27.2, 50.2), (24.6, 54.4), (23.2, 60.4), (23.4, 66.2), (25.4, 69.0), (27.6, 66.2), (29.0, 59.8)])
F['braquial']  = par([(23.0, 58.6), (22.0, 64.6), (22.2, 69.6), (23.8, 69.0), (23.4, 63.6)])
F['antebrazo'] = par([(26.8, 71.6), (22.6, 71.6), (20.4, 78.4), (19.0, 86.4), (18.2, 94.6), (21.0, 96.4), (23.4, 89.0), (25.8, 80.4), (27.2, 75.2)])
F['recto_abdominal'] = par([(49.2, 53.8), (45.0, 54.2), (44.2, 62.4), (44.2, 72.0), (44.8, 82.0), (46.2, 90.0), (49.2, 94.6)], 0.9)
F['oblicuos']   = par([(43.4, 54.6), (38.8, 53.4), (34.8, 56.2), (33.8, 63.4), (34.8, 71.4), (35.8, 78.8), (38.8, 85.0), (42.8, 87.0), (43.2, 76.0), (42.8, 64.0)])
F['transverso'] = par([(45.0, 84.4), (39.8, 86.2), (41.6, 90.8), (45.8, 94.4), (49.2, 96.0), (49.2, 90.6)])
F['psoas']      = par([(46.4, 96.4), (41.4, 94.8), (38.6, 98.4), (41.6, 103.4), (46.4, 106.0), (48.4, 102.0)])
F['abductores'] = par([(36.8, 92.6), (32.8, 95.2), (31.6, 102.6), (32.2, 109.6), (35.2, 105.0), (37.2, 98.4)])
F['cuadriceps'] = par([(39.8, 103.8), (34.6, 106.0), (32.4, 113.4), (32.6, 123.8), (34.2, 133.6), (37.0, 140.6), (41.4, 142.8), (44.6, 139.6), (45.6, 130.4), (45.0, 120.4), (43.2, 111.2)])
F['aductores']  = par([(49.0, 109.0), (45.4, 106.8), (44.6, 114.6), (45.6, 124.6), (47.0, 128.8), (48.4, 119.8)])
F['tibial_anterior'] = par([(38.6, 147.2), (35.8, 149.4), (35.0, 159.6), (36.0, 171.4), (38.0, 183.0), (39.6, 176.2), (39.8, 162.0)])
F['gemelos']    = par([(44.8, 147.6), (42.0, 150.4), (41.6, 160.0), (42.8, 169.0), (44.6, 162.6), (45.4, 154.6)])
F['cuerpo_completo'] = []

def lineas_par(ds):
    """Una linea de dibujo (M x,y C ...) y su reflejo."""
    import re
    out = []
    for d in ds:
        out.append(d)
        nums = re.findall(r'-?\d*\.?\d+', d)
        letras = re.findall(r'[MCL]', d)
        vals = [float(n) for n in nums]
        for i in range(0, len(vals), 2): vals[i] = 100 - vals[i]
        it = iter(vals)
        partes, k = [], 0
        for L in letras:
            n = 2 if L in 'ML' else 6
            grupo = [next(it) for _ in range(n)]
            pares = ' '.join('%s,%s' % (f(grupo[j]), f(grupo[j+1])) for j in range(0, n, 2))
            partes.append(L + pares)
        out.append(''.join(partes))
    return out

# Lineas de dibujo: separaciones del abdomen y las cabezas del cuadriceps.
LINEAS_F = lineas_par([
    'M44.3,63.0L49.2,62.6', 'M44.2,71.6L49.2,71.2', 'M44.6,80.4L49.2,80.2',
    'M39.6,108.0C38.4,118.0 38.6,128.0 40.4,138.4',
    'M44.8,128.0C42.6,132.0 41.8,136.0 42.4,140.6',
])

# ════════ MUSCULOS · ESPALDA ═════════════════════════════════════════
E = {}
E['trapecio_superior'] = par([(45.4, 24.2), (40.8, 28.6), (34.6, 31.6), (31.8, 33.4), (37.4, 35.0), (43.6, 35.4), (49.2, 35.0), (49.2, 27.0)])
E['trapecio_medio']    = par([(49.2, 35.8), (43.4, 36.2), (35.6, 37.6), (38.2, 42.8), (43.8, 47.6), (49.2, 49.6)])
E['trapecio_inferior'] = par([(49.2, 50.2), (45.2, 48.4), (42.4, 52.4), (45.2, 60.6), (49.2, 67.2)])
E['romboides']         = par([(48.6, 38.2), (44.2, 40.2), (42.2, 45.4), (45.4, 47.8), (48.6, 48.2)])
E['deltoide_posterior'] = par([(34.8, 33.8), (30.2, 35.0), (27.6, 38.8), (27.4, 44.4), (28.6, 49.4), (30.8, 47.6), (32.6, 42.8), (34.6, 38.4)])
E['deltoide_lateral']  = F['deltoide_lateral']
E['manguito_rotador']  = par([(41.6, 38.4), (36.4, 38.2), (33.2, 41.4), (33.4, 46.0), (36.8, 48.6), (41.4, 47.4), (43.0, 43.0)])
E['redondo_mayor']     = par([(37.8, 48.8), (33.8, 48.0), (31.6, 50.8), (33.6, 53.6), (38.2, 52.8)])
E['dorsal_ancho']      = par([(45.2, 50.4), (40.4, 52.6), (33.6, 53.0), (32.6, 59.6), (33.8, 67.6), (36.2, 75.6), (40.2, 82.2), (45.0, 82.0), (46.4, 72.0), (46.0, 61.0)])
E['erectores']         = par([(49.2, 58.0), (46.6, 58.6), (45.8, 68.0), (45.6, 78.0), (46.2, 87.6), (49.2, 90.4)], 0.9)
E['triceps']           = par([(30.2, 50.2), (27.2, 49.4), (24.4, 53.4), (22.8, 60.4), (23.2, 67.4), (25.4, 71.0), (28.0, 67.6), (29.4, 60.0)])
E['antebrazo']         = F['antebrazo']
E['gluteo_medio']      = par([(44.6, 86.4), (37.6, 86.4), (33.2, 90.2), (32.0, 95.8), (37.8, 94.6), (44.8, 91.2)])
E['gluteo_mayor']      = par([(49.2, 91.6), (43.2, 91.0), (36.6, 93.6), (32.6, 98.6), (32.4, 105.2), (35.4, 110.6), (41.4, 112.4), (47.0, 111.4), (49.2, 109.2)])
E['abductores']        = par([(33.0, 99.0), (31.2, 101.6), (31.4, 108.0), (33.0, 110.6), (33.6, 104.6)])
E['isquiotibiales']    = par([(47.4, 113.2), (42.0, 113.6), (35.4, 114.4), (33.2, 121.6), (34.2, 131.6), (37.2, 139.4), (41.8, 141.8), (45.6, 137.4), (47.0, 125.6)])
E['aductores']         = par([(49.2, 111.8), (47.6, 112.6), (47.0, 120.6), (48.2, 126.0), (49.2, 120.0)])
_gem = [
    [(40.8, 145.6), (36.4, 147.4), (34.0, 154.0), (34.4, 162.4), (37.0, 170.8), (39.8, 165.0), (40.8, 155.0)],
    [(45.4, 146.0), (42.2, 146.8), (41.8, 156.0), (42.6, 166.4), (44.6, 169.4), (46.0, 161.0), (46.2, 152.4)],
]
E['gemelos']           = [cerrada(p) for p in _gem] + [cerrada(espejo_pts(p)) for p in _gem]
E['cuerpo_completo'] = []

LINEAS_E = ['M50,35.6L50,90.4'] + lineas_par(['M40.8,116.0C40.2,125.0 40.6,133.0 41.8,140.8'])

def js_obj(nombre, dic):
    out = ['export const %s = {' % nombre]
    for k, v in dic.items():
        out.append("  %s: [%s]," % (k, ', '.join("'%s'" % d for d in v)))
    out.append('};')
    return '\n'.join(out)

def main():
    print("""// ─────────────────────────────────────────────────────────────────────────
// FORMAS DE LA FIGURA MUSCULAR v2  ·  ⚠ ARCHIVO GENERADO
//
// Sale de entrenamientoecm/carga/gen-figura-v2.py. No lo edites a mano.
// Silueta continua de cuerpo real y musculos que la cubren entera: se pinta
// todo en gris y se enciende lo que trabaja el ejercicio. Mismo lienzo
// (100 x 220) y mismos slugs que la v1.
// ─────────────────────────────────────────────────────────────────────────
""")
    print("export const FIG2_SILUETA = '%s';" % silueta())
    print("export const FIG2_CABEZA = '%s';" % CABEZA)
    print(js_obj('FIG2_FRENTE', F))
    print(js_obj('FIG2_ESPALDA', E))
    print("export const FIG2_LINEAS_FRENTE = [%s];" % ', '.join("'%s'" % d for d in LINEAS_F))
    print("export const FIG2_LINEAS_ESPALDA = [%s];" % ', '.join("'%s'" % d for d in LINEAS_E))
    print("export const FIG2_PROFUNDOS = [%s];" % ', '.join("'%s'" % d for d in PROFUNDOS))

if __name__ == '__main__':
    main()
