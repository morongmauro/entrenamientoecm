# Carga de las rutinas de Trainerize

Las rutinas que 10 clientes venían haciendo, sacadas de los PDF de
Trainerize del 19 sep 2026, listas para entrar en el módulo de
entrenamiento. **Nada se le muestra al cliente**: todo entra como borrador
y oculto, y se publica una fase a la vez con el botón del CRM.

## En qué orden se corre

En el SQL editor de Supabase, de arriba abajo:

| # | Archivo | Qué hace |
|---|---|---|
| 1 | `migracion-visibilidad.sql` | Añade el interruptor `visible_cliente`, la vista `rutinas_visibles` y la función `publicar_fase()`. Se puede correr dos veces. |
| 2 | `carga-rutinas-trainerize.sql` | Los 160 ejercicios, las 10 fases, las 29 rutinas y las 1.266 series de historial. Se puede correr dos veces: lo ya cargado se salta solo. |

Los dos están probados de cero contra PostgreSQL 16, que es lo que corre
Supabase.

## Qué queda cargado

| Cliente | Fase | Semanas | Desde | Rutinas | Series de historial |
|---|---|---|---|---|---|
| Alejandra Borbón | Cycle 3 | 4 | 7 sep 2026 | 4 | 58 |
| Alejandro Aguirre | Cycle 18 | 5 | 7 sep 2026 | 4 | 206 |
| Amalia Rodríguez | Cycle 4 | 5 | 7 sep 2026 | 3 | — |
| Amauri Barbosa | Cycle 6 | 5 | 14 sep 2026 | 2 | 89 |
| Andrea Angulo | Cycle 8 | 5 | 24 ago 2026 | 2 | 265 |
| Andrés Yepes | Cycle 14 | 4 | 31 ago 2026 | 2 | 201 |
| Camilo Rodríguez | Cycle 2 | 4 | 7 sep 2026 | 2 | — |
| Carlos Martínez | Cycle 14 | 5 | 24 ago 2026 | 4 | 126 |
| David Forero | Cycle 17 | 4 | 24 ago 2026 | 4 | 230 |
| Diana Tovar | Cycle 7 | 6 | 17 ago 2026 | 2 | 91 |

Los circuitos entran como bloques con sus vueltas y su descanso, los sets ×
reps y los descansos van tal cual, y el historial de "Previous Stats" entra
como sesiones completadas con una fila por serie (reps y peso).

## Cómo se envía al cliente

En el CRM → Entrenamiento → Clientes, cada fase trae ahora un chip que dice
si el cliente la ve (`🔒 solo tú` / `📲 la ve el cliente`) y un botón
**📤 Enviar al cliente**. Antes de enviar te lista qué días va a ver. Se
puede retirar después sin borrar nada.

La app del cliente debe leer de la vista `rutinas_visibles`, no de
`rutinas`: así es imposible que se le escape un borrador. Esa vista tampoco
expone `notas_coach`.

## Lo que hay que revisar antes de enviar

Esto sale de leer los PDF, así que conviene una pasada de ojo. Lo que ya
detecté:

- **Nombres de los clientes.** Cada uno se busca en `clientes` por nombre
  (`ilike`). Si alguno está escrito distinto en el CRM, ese cliente se salta
  con un aviso en la consola y el resto entra igual. El del PDF es **Andrés
  Yepes** con ese, aunque el archivo se llamara `andres_yepez`.
- **`Bar Hang` con tiempos imposibles.** Amauri Barbosa tiene 1.200 s
  (20 min) el 14 y el 16 sep; Andrés Yepes tiene 2.700 s (45 min) en cuatro
  fechas. Vienen así del PDF — es un error de registro en Trainerize, no de
  la carga. Los dejé tal cual para no inventar datos; si quieres limpiarlos:
  `delete from series_log sl using ejercicios e where e.id = sl.ejercicio_id and e.alias = 'Bar Hang' and sl.reps > 300;`
- **Andrés Yepes · Smith Machine Shrug, serie 1 del 14 sep: 1 rep × 25 kg.**
  Casi seguro eran 10 como las otras tres, pero el PDF dice 1.
- **David Forero · Dip Machine Straight Leg Raise, serie 2 del 8 sep:** ese
  dato quedaba tapado por el botón "Dismiss" en el PDF, así que esa serie no
  se cargó en vez de adivinarla.
- **Ejercicios del historial que ya no están en la rutina.** Trainerize
  arrastra el historial del hueco, no del ejercicio, así que hay series de
  ejercicios de ciclos anteriores (Landmine RDL, Kettlebell High Pull,
  Squat Jump…). Se cargan igual: quedan en el historial del cliente, sin
  ligar a ninguna rutina actual, que es justo lo que quieres para consultar
  "cuánto levantaba antes en X".
- **Sin historial:** Amalia Rodríguez y Camilo Rodríguez no traían ninguno,
  y a Alejandra y a Carlos les falta en algunas rutinas. En el PDF esas
  tablas de "Previous Stats" están vacías.
- **"Squat to Hinge" y "Bodyweight Squat To Hinge"** son el mismo
  movimiento, así que quedaron como un solo ejercicio (por eso son 159
  fichas y no 160).

## Los ejercicios

Se crean con el nombre en **español** (es el que verá el cliente) y el
nombre original de Trainerize en `alias`, que es por donde se cruzan. Si ya
tenías alguno creado, se reusa en vez de duplicarlo. Van con tipo, segmento,
patrón y equipo puestos; **sin vídeo ni músculos**: eso se rellena desde la
galería del CRM.

Todos llevan la etiqueta `importado-trainerize`, para poder encontrarlos.

## Si algo sale mal

Al final de `carga-rutinas-trainerize.sql` está el bloque para deshacer:
borra las fases importadas y, en cascada, sus rutinas, bloques, sesiones y
series. Los ejercicios de la galería no se tocan salvo que se lo pidas
expresamente (y solo los que nadie esté usando).
