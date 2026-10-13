# Panel de administración de Hoja del Alba

Web estática para **ver los datos de la app** (jugadores, personajes, progreso) y **balancear el juego en vivo**
(monstruos, piezas, armaduras, minerales, zonas y aparición, mazmorras, misiones, economía) sin publicar una versión
nueva de la app. Habla con el mismo Supabase que el juego, con la **clave pública**; la seguridad la dan RLS y las
funciones de `backend/supabase/migrations/002_panel.sql`.

- Contrato de ajustes (`GameTuning`): `assets/admin/contrato.md`.
- Backend, tablas, RPC y cómo hacerse admin: `backend/README.md`, sección «Panel de administración».
- Valores base del juego: `admin/public/data/*.json` (se generan con `make datos`, no se editan a mano).

## Pantallas

| Pantalla | Qué hace | Fuente |
|---|---|---|
| **Entrar** | Usuario y contraseña del juego (email sintético con la misma plantilla que la app). Comprueba si eres admin; si no, solo lectura. Sin Supabase configurado: **modo demo**. | Supabase Auth, `is_admin` |
| **Resumen** | Cuentas, activos en 24 h y 7 días, personajes por raza y nivel, oro, top 10 de la arena, misiones, mazmorras, dónde están. Gráficos en SVG propio (cada uno con «Ver como tabla»). | `admin_summary` |
| **Jugadores** | Lista paginada con búsqueda (personaje o usuario) y ficha de solo lectura del personaje (con el `PlayerProfile` completo). | `admin_characters`, `admin_character` |
| **Balance** | Pestañas Enemigos, Piezas, Armadura, Minerales, Zonas y aparición, Mazmorras, Misiones y Economía. Tabla con búsqueda y filtros, base → ajustado con el % y lo cambiado resaltado, edición en línea validada con `esquema.json`, ↺ para volver al base (un campo o la fila), edición masiva, deshacer. | `public/data/*.json` + borrador |
| **Borrador** | Nota, guardar (botón o autoguardado), cambios respecto a la publicada (y `config_diff` del servidor), publicar con confirmación, descartar, importar y exportar JSON, avisos como los del juego. | `game_config`, `config_diff`, `publish_config` |
| **Historial** | Versiones publicadas (quién, cuándo, nota), «Ver», «Copiar al borrador», «Volver a esta versión» (con confirmación) y el registro de `admin_audit`. | `game_config`, `rollback_config`, `admin_audit` |

Detalles útiles:

- **Enemigos**: «Dónde sale» enseña las zonas, spawns, mazmorras (y oleadas), arena (primera oleada y oleadas de jefe),
  misiones y piezas de cada monstruo, **con el borrador aplicado** (si mueves un spawn, se ve).
- **Zonas y aparición**: niveles de áreas y zonas; al abrir una fila, qué monstruo hay en cada spawn y un desplegable para
  cambiarlo por otro válido (los jefes no se mueven). Avisa si una misión de «mata N» se quedaría sin sus monstruos.
- **Mazmorras**: editor de oleadas (1-10, sin jefes, 0-40 de cada) y de la escolta del jefe.
- **Misiones**: XP y oro; al abrir una fila, los minerales de la recompensa (si se cambian, sustituyen a todos).
- **Economía**: los números globales (por grupos), los pesos de minerales del continente, la ruleta y dos gráficos
  (XP por nivel y oro de la arena por oleada, base frente a ajustado).
- **Edición masiva**: se aplica a las filas que se ven (con los filtros puestos). Ejemplos: Enemigos → filtro Área
  «Colinas del Pedregal» y Jefe «Sin jefes» → Edición masiva → Vida, +/− %, 10. O Piezas → Tier T1 → Precio, ×, 0,8.
  Los enteros se redondean, todo se recorta al rango y se puede deshacer.
- Enlaces directos: `#/balance/enemigos/orc` abre esa fila (los nombres de la lista de cambios llevan ahí).
- El borrador vive en memoria, con copia en `localStorage`: si cierras la pestaña sin guardar, al volver te ofrece
  recuperarlo. El navegador avisa si sales con cambios sin guardar en Supabase.
- El documento que se guarda es **mínimo**: solo lo distinto de los valores base (si vuelves un valor al base, desaparece).

## Arrancarlo

Necesita Node 20.19 o más nuevo.

```bash
cd admin && npm install && npm run dev      # http://localhost:5174
# o, desde la raíz:
make admin
```

Sin configurar nada arranca en **modo demo**: solo lectura, con los valores base del juego y un aviso. Se pueden probar
ajustes en el navegador y exportarlos, pero no se guarda ni se publica nada; el resumen y los jugadores son datos
inventados (está marcado).

Otros comandos:

```bash
npm test              # tests de la lógica (Vitest): documento mínimo, validación, diff, edición masiva, API
npm run typecheck     # tipos de TypeScript (también npm run lint)
npm run build         # tipos + compilación en admin/dist/
make admin-build      # lo mismo desde la raíz (tests + build)
```

## Configurarlo (paso a paso)

1. Prepara Supabase y aplica las migraciones `001_cuentas.sql` y `002_panel.sql` (`backend/README.md`).
2. Copia la plantilla y rellénala:
   ```bash
   cp admin/.env.example admin/.env.local
   ```
   - `VITE_SUPABASE_URL`: la *Project URL* (`https://xxxxxxxxxxxx.supabase.co`).
   - `VITE_SUPABASE_ANON_KEY`: la **clave pública**, la misma que el juego (*Publishable key* `sb_publishable_...` o
     la *anon public* antigua `eyJ...`).
   - `VITE_EMAIL_PLANTILLA`: igual que `EMAIL_PLANTILLA` del juego (por defecto `{usuario}@jugadores.valdehierro.app`).
3. Vuelve a arrancar `npm run dev`. Ahora pide usuario y contraseña.

`admin/.env.local` no se versiona (está en `.gitignore`). `git status` no debe enseñarlo.

> ⚠️ **Nunca** pongas la `service_role` ni una *Secret key* (`sb_secret_...`): se salta RLS y da acceso total.
> El panel las detecta y se niega a usarlas (arranca en modo demo con un aviso), pero en una web compilada la clave
> quedaría dentro igualmente: si la has pegado por error, cámbiala en Supabase. La clave pública sí puede verse
> (está dentro del juego y de esta web): por sí sola no da acceso a nada.

### Hacerse admin

Un admin es una cuenta normal del juego cuyo id está en la tabla `admins`. Se hace a mano en el SQL Editor de Supabase:
`backend/README.md` → «Panel de administración» → «2. Hacerte administrador». Sin eso, el panel entra en **solo lectura**
(ve los valores base y la versión publicada, pero no jugadores, borradores ni historial).

## Cómo se publica un ajuste

1. **Balance**: cambia lo que quieras (en línea o con edición masiva). Lo cambiado se resalta y la barra de abajo lo cuenta.
2. **Borrador**: escribe una nota y guarda (o deja el autoguardado: guarda 8 s después del último cambio). Revisa
   «Cambios respecto a la versión N» y los **avisos** (los mismos que daría el juego).
3. Para probarlo antes en el juego: **Exportar JSON** y
   ```bash
   cd tools/Harness && swift run -c release Harness balance --ajustes ~/Downloads/ajustes-borrador-7-….json
   ```
   (vale con cualquier comando del banco de pruebas: `historia`, `valdemar`…; imprime los avisos).
4. **Publicar…**: enseña el resumen de cambios y pide confirmación. Los jugadores la reciben al abrir el juego (como mucho
   cada 15 min) y la aplican en la siguiente partida.
5. Si algo sale mal: **Historial → Volver a esta versión** (publica una copia con un número nuevo). Botón de emergencia
   sin la web: `backend/README.md`.

## Regenerar los valores base

Si cambian los números en el código del juego:

```bash
make datos      # escribe admin/public/data/*.json (Harness exportar-datos)
```

El panel no copia números a mano: lee esos JSON (y `esquema.json` para los rangos y descripciones).

## Publicarlo en GitHub Pages

El repositorio ya trae el workflow `.github/workflows/admin-pages.yml`, pero **no está activado**: solo se lanza a mano.

1. En GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. **Settings → Secrets and variables → Actions → Variables** (pestaña *Variables*; como *Secret* también vale):
   - `VITE_SUPABASE_URL` = la Project URL.
   - `VITE_SUPABASE_ANON_KEY` = la clave **pública** (anon / publishable).
   - Opcional: `VITE_EMAIL_PLANTILLA`.
   Sin ellas se publica el modo demo.
3. **Actions → «Panel de administración (Pages)» → Run workflow**. Construye `admin/` (tests + build con
   `VITE_BASE=/<repositorio>/`), comprueba que la clave no sea secreta y lo publica en
   `https://<usuario>.github.io/<repositorio>/`.
4. Para publicar solo al cambiar `admin/` en `main`, quita los `#` del bloque `push:` del workflow.

Recuerda:

- La clave anon/publishable queda dentro de la web publicada y cualquiera puede verla. Es lo esperado: **la seguridad
  está en RLS** y en las comprobaciones `is_admin()` de las funciones. Sin sesión de admin no se pueden leer borradores,
  ni publicar, ni ver jugadores.
- El panel publicado es una web pública (con `noindex`): cualquiera puede abrirla, pero sin una cuenta de admin solo ve
  los valores base del juego, que ya están en este repositorio.
- Usa para el panel una cuenta de admin con una contraseña larga y única (no hay «he olvidado mi contraseña»).
- `base` de Vite: por defecto `./` (funciona en cualquier carpeta porque las rutas van con `#`). Se puede fijar con
  `VITE_BASE`.

## Estructura

```
admin/
  public/data/          Valores base del juego (make datos) y esquema.json
  src/tipos/            Tipos de GameTuning y de los JSON de datos
  src/logica/           Lógica pura con tests: documento mínimo, validación, diff, edición masiva, tablas de Balance
  src/api/              Capa de API aislada: Supabase (supabase-js, cargado aparte), modo demo, configuración, errores
  src/estado/           Estado del panel (sesión, borrador, deshacer, copia local, autoguardado) y rutas con "#"
  src/componentes/      Tabla de balance, celda base → ajustado, edición masiva, gráficos SVG, diff, modales
  src/paginas/          Entrar, Resumen, Jugadores, Balance, Borrador, Historial
```

Responsable: agente `web-admin-developer` (`.claude/agents/web-admin-developer.md`).
