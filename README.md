# Módulo de Entrenamiento · EntrenaConMétodo

App donde el cliente ve su calendario de entrenos, abre la rutina del día,
la ejecuta y marca reps y pesos. Las rutinas las arma el coach desde el CRM.

Es el tercer módulo del ecosistema, junto a **Alimentación** (mealtracker) y
**Aprendizaje** (centro de recursos).

---

## Estado

Andamiaje y modelo de datos. **Todavía NO se muestra a los clientes**: la app
se usa suelta, en su propia URL, mientras se construye. No se ha tocado el
repo del mealtracker.

| Pieza | Estado |
|---|---|
| Modelo de datos (`schema.sql`) | Listo y probado contra Postgres 16 |
| Copiar/importar rutinas | Listo (`copiar_rutina`, `copiar_fase`, `duplicar_rutina`) |
| Andamiaje de la app + identidad | Listo |
| Galería de ejercicios (CRM) | Pendiente |
| Constructor de rutinas (CRM) | Pendiente |
| Visibilidad: "enviar al cliente" | Listo (`carga/migracion-visibilidad.sql` + botón en el CRM) |
| Rutinas reales cargadas | Listo — 10 clientes, ver `carga/LEEME.md` |
| Calendario del cliente | Pendiente |
| Ejecución: reps, pesos, video, dibujo del cuerpo | Pendiente |
| Enganche como pestaña en la app del cliente | Pendiente, **a propósito** |

## Lo que ya está cargado

Las rutinas de 10 clientes (importadas de Trainerize) viven ya en la base,
**invisibles para ellos**: las fases entran con `visible_cliente = false` y
solo se publican una a una desde el CRM. Ver `carga/LEEME.md`.

Cuando se construya el calendario del cliente, **debe leer de la vista
`rutinas_visibles`, nunca de `rutinas`**: es la única forma de que no se le
escape un borrador, y además esa vista no expone `notas_coach`.

## Poner en marcha

```bash
npm install
npm run dev
```

Sin parámetros en la URL, la app pide un nombre a mano. Ese es el modo de
trabajo por ahora.

## Base de datos

`schema.sql` se pega en el **Supabase del CRM** (SQL Editor → New query →
Run), no en un proyecto nuevo. El CRM ya es la fuente de verdad de
`clientes`; poner las rutinas ahí evita sincronizar dos bases y permite
calcular la adherencia de entreno sola, en vez de cargarla a mano en
`seguimientos`.

Es idempotente: se puede volver a correr.

Después, una vez: **Storage → New bucket → `ejercicios`, público NO.**

### Las tablas

- `musculos` — vocabulario cerrado. El `slug` es el `id` del `<path>` en el
  SVG del cuerpo: marcar un músculo es pintar por id.
- `ejercicios` — la galería. Con patrón, segmento, tipo, músculos, equipo,
  lugar y nivel; los filtros del constructor salen de ahí.
- `fases` — un bloque de X semanas para un cliente, con sus días. De aquí
  sale el calendario.
- `rutinas` + `rutina_bloques` + `rutina_ejercicios` — los días de entreno y
  su prescripción, con soporte de superseries y circuitos.
- `sesiones` + `series_log` — lo que el cliente marca al entrenar.
- `adherencia_entreno` (vista) — cierra el círculo con `/api/adherence.js`
  del mealtracker.

### Copiar e importar rutinas

```sql
-- Importar la fase de un cliente a otro (clona la fase y todas sus rutinas)
select copiar_fase('<fase_id>', '<cliente_destino>', '2026-10-05', 'Fase 1');

-- Copiar una rutina suelta a otra fase (o a la biblioteca si va NULL)
select copiar_rutina('<rutina_id>', '<fase_destino>');

-- Duplicar un día dentro de la misma fase, para editarlo como variante
select duplicar_rutina('<rutina_id>');
```

Las copias guardan `origen_rutina_id` / `origen_fase_id`, así siempre se sabe
de dónde salió cada una. Nunca se comparten filas: editar la rutina de un
cliente jamás toca la de otro.

### Video de los ejercicios

Dos caminos, por ejercicio, vía `video_fuente`:

- `youtube` → pega el link, se guarda `video_url` + `video_ref`. Costo cero.
  Es el default recomendado.
- `archivo` → subes el mp4 al bucket `ejercicios`, se guarda `video_path`.
  Para material que no quieres público. Ojo con el egress de Storage: demos
  cortas, no clases completas.
- `ninguno` → ficha sin reproductor.

**Lo que ve el cliente y lo que ves tú son distintos.** `descripcion` y
`claves_tecnicas` son del cliente; `notas_coach` (en `ejercicios`, `rutinas`,
`rutina_ejercicios` y `fases`) nunca sale hacia la app.

## Cómo se conecta con el resto

Cuando llegue el momento de mostrárselo a los clientes, se embebe como
pestaña dentro de la app igual que "Aprendizaje": un `<iframe>` con la
identidad en la URL (`?mt_user=<uuid>&mt_name=<nombre>`), sin segundo login.

El código ya cumple ese contrato, para no tener que rehacerlo:

1. `src/identity.js` lee `mt_user` / `mt_name`, con fallback manual.
2. **Sin barra inferior fija** — la app padre monta el iframe 64px más corto
   y le pinta encima un degradado de 96px; una barra propia quedaría tapada.
   Ver `FADE_TOP` / `FADE_BOTTOM` en `src/App.jsx`.
3. `src/theme.js` es copia literal del mealtracker: el fondo `#EDECE5` calza
   byte a byte y no se ve la costura.
4. `vercel.json` no declara `X-Frame-Options` ni `frame-ancestors`.

Falta, ese día: agregar el dominio a `ALLOWED_ORIGINS` en Vercel (proyecto
mealtracker) para que `/api/authorize` acepte la validación por CORS.

## Estructura

```
schema.sql          Modelo de datos → Supabase del CRM
src/theme.js        Paleta y sombras (copia literal del mealtracker)
src/identity.js     Identidad por URL, con fallback manual
src/musculos.js     Vocabulario de músculos — GENERADO desde schema.sql
src/taxonomia.js    Categorías y filtros de la galería
src/App.jsx         Cascarón de la app
```

`src/musculos.js` no se edita a mano: se agrega el músculo al `schema.sql` y
se regenera, para que SQL, SVG y app no se desincronicen.
