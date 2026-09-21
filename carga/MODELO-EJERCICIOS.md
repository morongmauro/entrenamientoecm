# Catálogo de ejercicios · modelo de datos

> Contexto para quien lea esto sin el resto del proyecto: esto es la
> **galería de ejercicios** de un CRM de entrenamiento personal
> (stack: Supabase/PostgreSQL + JS plano, sin framework). El coach da de
> alta ejercicios aquí y luego los mete en rutinas; el cliente los ve en su
> app. Cada ejercicio es una fila de la tabla `ejercicios`.
>
> Este documento lista TODOS los campos que se capturan, con sus valores
> permitidos exactos. Generado desde el esquema y el formulario reales.

---

## Resumen

| | |
|---|---|
| Tabla | `ejercicios` |
| Campos totales | **27** |
| Los llena el formulario | 19 |
| Automáticos | 4 (`id`, `user_id`, `created_at`, `updated_at`) |
| Se ponen por otra vía | 1 (`archivado`, con el botón Archivar) |
| Heredado, en desuso | 1 (`poster_url`) |
| **Existen pero nada los llena** | **2 (`unilateral`, `tags`)** — ver §8 |

---

## 1 · Identidad

| Campo | Tipo | Obligatorio | Quién lo ve | Para qué |
|---|---|---|---|---|
| `nombre` | text | **Sí** | Cliente | El nombre del ejercicio |
| `alias` | text | No | Solo búsqueda | Otro nombre por el que buscarlo ("RDL", "peso muerto rumano"). No se muestra, pero entra en el buscador |

## 2 · Lo que ve el cliente

| Campo | Tipo | Para qué |
|---|---|---|
| `descripcion` | text | Cómo se ejecuta, en lenguaje de cliente |
| `claves_tecnicas` | text[] | Bullets cortos, uno por elemento ("Escápulas retraídas", "Codos a 45°") |

## 3 · Lo que ve solo el coach

| Campo | Tipo | Para qué |
|---|---|---|
| `notas_coach` | text | Cuándo progresarlo, cuándo evitarlo. **Nunca se envía a la app del cliente** |

---

## 4 · Clasificación (son los filtros de la galería)

Selección ÚNICA:


### `tipo` · text · una sola opción

| valor guardado | etiqueta en la interfaz |
|---|---|
| `fuerza` | Fuerza |
| `hipertrofia` | Hipertrofia |
| `potencia` | Potencia |
| `pliometrico` | Pliométrico |
| `agilidad` | Agilidad |
| `movilidad` | Movilidad |
| `estiramiento_pasivo` | Estiram. pasivo |
| `estiramiento_activo` | Estiram. activo |
| `cardio` | Cardio |
| `core` | Core |
| `rehabilitacion` | Rehabilitación |
| `calentamiento` | Calentamiento |

### `segmento` · text · una sola opción

| valor guardado | etiqueta en la interfaz |
|---|---|
| `tren_superior` | Tren superior |
| `tren_inferior` | Tren inferior |
| `core` | Core |
| `full_body` | Cuerpo completo |

### `patron` · text · una sola opción

| valor guardado | etiqueta en la interfaz |
|---|---|
| `push` | Empuje |
| `pull` | Tracción |
| `rodilla` | Dom. rodilla |
| `cadera` | Dom. cadera |
| `core` | Core |
| `carry` | Transporte |
| `locomocion` | Locomoción |

### `nivel` · text · una sola opción

| valor guardado | etiqueta en la interfaz |
|---|---|
| `principiante` | Principiante |
| `intermedio` | Intermedio |
| `avanzado` | Avanzado |

Selección MÚLTIPLE (arrays):


### `equipo` · text[]

| valor guardado | etiqueta |
|---|---|
| `peso_corporal` | Peso corporal |
| `barra` | Barra |
| `mancuerna` | Mancuernas |
| `kettlebell` | Kettlebell |
| `polea` | Polea |
| `maquina` | Máquina |
| `smith` | Máquina Smith |
| `banda` | Banda |
| `trx` | TRX / anillas |
| `balon` | Balón medicinal |
| `banco` | Banco |
| `caja` | Cajón |
| `cuerda` | Cuerda |

### `lugar` · text[] · cruza con `clientes.lugar_entreno` para filtrar qué puede hacer cada cliente

| valor guardado | etiqueta |
|---|---|
| `gym` | Gimnasio |
| `casa` | Casa |
| `aire_libre` | Aire libre |

---

## 5 · Músculos

Dos arrays de slugs, ambos de selección múltiple sobre el mismo catálogo:

| Campo | Tipo | Efecto |
|---|---|---|
| `musculos_primarios` | text[] | Se pintan **fuerte** en el dibujo del cuerpo que ve el cliente |
| `musculos_secundarios` | text[] | Se pintan **suave** |

Los slugs salen de la tabla `musculos`, que es catálogo fijo:

```sql
create table musculos (
  slug   text primary key,
  nombre text not null,   -- etiqueta larga: "Bíceps braquial"
  corto  text not null,   -- etiqueta del chip: "Bíceps"
  grupo  text not null,   -- pecho|espalda|hombro|brazo|pierna|gluteo|core|otro
  cara   text not null,   -- frente | espalda | ambas  (en qué silueta se pinta)
  orden  int
);
```

**Ojo:** el chip de la interfaz muestra `corto`, pero lo que se guarda es el
`slug`. No siempre coinciden (el chip "LUMBARES" guarda `erectores`).

### Catálogo completo

| slug (lo que se guarda) | chip | nombre completo | grupo | cara |
|---|---|---|---|---|
| `pectoral_mayor` | Pecho | Pectoral mayor | pecho | frente |
| `pectoral_superior` | Pecho sup. | Pectoral superior (clavicular) | pecho | frente |
| `deltoide_anterior` | Deltoide ant. | Deltoide anterior | hombro | frente |
| `deltoide_lateral` | Deltoide lat. | Deltoide lateral | hombro | ambas |
| `deltoide_posterior` | Deltoide post. | Deltoide posterior | hombro | espalda |
| `biceps` | Bíceps | Bíceps braquial | brazo | frente |
| `braquial` | Braquial | Braquial anterior | brazo | frente |
| `triceps` | Tríceps | Tríceps braquial | brazo | espalda |
| `antebrazo` | Antebrazo | Antebrazo | brazo | ambas |
| `dorsal_ancho` | Dorsales | Dorsal ancho | espalda | espalda |
| `trapecio_superior` | Trapecio sup. | Trapecio superior | espalda | ambas |
| `trapecio_medio` | Trapecio medio | Trapecio medio | espalda | espalda |
| `trapecio_inferior` | Trapecio inf. | Trapecio inferior | espalda | espalda |
| `romboides` | Romboides | Romboides | espalda | espalda |
| `redondo_mayor` | Redondo | Redondo mayor | espalda | espalda |
| `erectores` | Lumbares | Erectores espinales | espalda | espalda |
| `recto_abdominal` | Abdomen | Recto abdominal | core | frente |
| `oblicuos` | Oblicuos | Oblicuos | core | frente |
| `transverso` | Transverso | Transverso abdominal | core | frente |
| `cuadriceps` | Cuádriceps | Cuádriceps | pierna | frente |
| `isquiotibiales` | Isquios | Isquiotibiales | pierna | espalda |
| `gluteo_mayor` | Glúteo | Glúteo mayor | gluteo | espalda |
| `gluteo_medio` | Glúteo medio | Glúteo medio | gluteo | espalda |
| `aductores` | Aductores | Aductores | pierna | frente |
| `abductores` | Abductores | Abductores | pierna | ambas |
| `gemelos` | Gemelos | Gemelos / sóleo | pierna | espalda |
| `tibial_anterior` | Tibial | Tibial anterior | pierna | frente |
| `psoas` | Psoas | Psoas ilíaco | core | frente |
| `manguito_rotador` | Manguito | Manguito rotador | hombro | espalda |
| `cuerpo_completo` | Full body | Cuerpo completo | otro | ambas |

Total: **30 músculos**.

---

## 6 · Vídeo

Dos caminos excluyentes, según `video_fuente`.

| Campo | Tipo | Cuándo se usa |
|---|---|---|
| `video_fuente` | text | `youtube` · `vimeo` · `archivo` · `ninguno` (por defecto) |
| `video_url` | text | Solo `youtube`/`vimeo`: el link tal cual se pegó |
| `video_ref` | text | Solo `youtube`/`vimeo`: el id extraído del link, para montar el embed sin re-parsear |
| `video_path` | text | Solo `archivo`: ruta en Supabase Storage (bucket `ejercicios`, privado, se sirve con URL firmada) |
| `poster_path` | text | Solo `archivo`: miniatura, misma ruta de Storage |
| `poster_url` | text | Heredado, para miniaturas públicas. En desuso: el formulario escribe `poster_path` |
| `video_inicio_seg` | int | Solo `youtube`: arrancar el vídeo en el segundo N |

---

## 7 · Control

| Campo | Tipo | |
|---|---|---|
| `archivado` | boolean | `true` lo saca de la galería **sin romper las rutinas que ya lo usan** |
| `id` | uuid | PK, automática |
| `user_id` | uuid | El coach dueño. RLS: cada uno solo ve los suyos |
| `created_at` / `updated_at` | timestamptz | Automáticas |

---

## 8 · Existen en la tabla pero el formulario NO los captura

Son campos reales de la tabla, con índice y todo, pero la pantalla de la
galería no tiene dónde rellenarlos. Solo se pueden poner por SQL.

| Campo | Tipo | Para qué servía |
|---|---|---|
| `unilateral` | boolean, default `false` | Marca los ejercicios a un lado. Es lo que hace que la app le pida al cliente las **reps por lado** en vez de un total |
| `tags` | text[], default `{}` | Etiquetas libres para lo que no cabe en las categorías ("apto embarazo", "sin impacto"). Tiene índice GIN para filtrar |

---

## 9 · Cómo se usa un ejercicio dentro de una rutina

El ejercicio es la ficha; la **prescripción** (series, reps, peso) no vive
aquí sino en `rutina_ejercicios`, que lo referencia. Así el mismo ejercicio
puede ir a 4×6 en una rutina y a 3×15 en otra.

| Campo de `rutina_ejercicios` | Tipo | Nota |
|---|---|---|
| `ejercicio_id` | uuid | → `ejercicios.id` |
| `series` | int | |
| `reps` | **text** | Texto a propósito: "8-10", "AMRAP", "30s por lado", "al fallo" son respuestas legítimas que un número no admite |
| `peso_objetivo` | text | Mismo motivo: "70% RM" |
| `rir` | int | Reps en reserva (0-5) |
| `tempo` | text | "3-1-1-0" |
| `descanso_seg` | int | |
| `notas` | text | Indicación para el cliente **en esta rutina** |
| `notas_coach` | text | Solo el coach |
| `bloque_id` | uuid | Si va dentro de una superserie/circuito |
| `orden` | int | |

---

## Anexo · DDL real de la tabla

```sql
create table if not exists ejercicios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,

  nombre text not null,
  alias text,                        -- otro nombre por el que lo buscas ("peso muerto rumano" / "RDL")

  -- ---- Lo que VE EL CLIENTE ----
  descripcion text,                  -- cómo se ejecuta, en lenguaje de cliente
  claves_tecnicas text[] default '{}', -- 2-4 bullets cortos ("rodilla en línea con el pie")

  -- ---- Lo que ves SOLO TÚ en el constructor ----
  notas_coach text,                  -- criterios de progresión, cuándo NO usarlo, etc.
                                     -- NUNCA se envía a la app del cliente.

  -- ---- Clasificación / filtros de la galería ----
  patron text,                       -- push | pull | rodilla | cadera | core | carry | locomocion
  segmento text,                     -- tren_superior | tren_inferior | core | full_body
  tipo text default 'fuerza',        -- fuerza | hipertrofia | potencia | movilidad | pliometrico
                                     -- agilidad | estiramiento_pasivo | estiramiento_activo
                                     -- cardio | core | rehabilitacion | calentamiento
  musculos_primarios text[] default '{}',   -- slugs de `musculos` → pintan FUERTE en el dibujo
  musculos_secundarios text[] default '{}', -- slugs de `musculos` → pintan SUAVE
  equipo text[] default '{}',        -- barra | mancuerna | kettlebell | polea | maquina
                                     -- banda | trx | balon | peso_corporal | banco | caja
  lugar text[] default '{}',         -- gym | casa | aire_libre  (cruza con clientes.lugar_entreno)
  nivel text default 'intermedio',   -- principiante | intermedio | avanzado
  unilateral boolean default false,  -- si es a un lado: la UI pide reps por lado
  tags text[] default '{}',          -- etiquetas libres, para lo que no cabe arriba

  -- ---- Video: SUBIDO o LINK DE YOUTUBE (los dos caminos, ver §2.1) ----
  video_fuente text default 'ninguno', -- youtube | vimeo | archivo | ninguno
  video_url text,                    -- link original pegado (youtube/vimeo)
  video_ref text,                    -- id extraído del link (p.ej. 'dQw4w9WgXcQ') para
                                     -- construir el embed sin re-parsear en cada render
  video_path text,                   -- ruta en Supabase Storage si TÚ subiste el archivo
  video_inicio_seg int,              -- opcional: arrancar el video en el segundo N
  poster_url text,                   -- miniatura para la galería (si no hay, se usa la de YouTube)

  archivado boolean default false,   -- se oculta de la galería sin romper rutinas viejas
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```
