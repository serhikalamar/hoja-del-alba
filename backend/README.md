# Backend: cuentas y personajes en la nube (Supabase)

El jugador puede crear una cuenta con **usuario y contraseña** y sus personajes se guardan en la nube.
Sin cuenta (o sin configurar Supabase), el juego funciona igual que siempre: todo se guarda en el dispositivo.

```
backend/
  supabase/migrations/001_cuentas.sql   Cuentas y personajes: tablas, triggers y seguridad (RLS). Se pega en el SQL Editor.
  supabase/migrations/002_panel.sql     Panel de administración: ajustes en vivo, registro y resumen de jugadores.
  supabase/tests/002_panel_comprobaciones.sql   Comprueba la seguridad del panel (se deshace solo, no deja nada).
  SupabaseConfig.example.plist          Plantilla de configuración de la app (sí se versiona)
src/GameTest1/Resources/SupabaseConfig.plist   Configuración real (NO se versiona, está en .gitignore)
src/GameTest1/Account/                  Cliente REST, sesión (llavero), sincronización, pantalla de cuenta y ajustes en vivo
src/GameCore/Sources/GameCore/CloudSync.swift     Reglas puras (usuario, contraseña, conflictos) con tests
src/GameCore/Sources/GameCore/RemoteTuning.swift  Ajustes en vivo: qué aplicar y cuándo, caché (con tests)
```

- Sin dependencias: la app habla con la API REST de Supabase con `URLSession`
  (`/auth/v1/...` para la cuenta, `/rest/v1/characters` para los personajes).
- Cada personaje es una fila de `characters` con el `PlayerProfile` completo en JSON (`data`).
- **RLS**: cada jugador solo puede leer, crear, cambiar y borrar sus propias filas. Sin sesión no se ve nada.

---

## Paso a paso (lo que tienes que hacer tú)

### 1. Crear el proyecto

1. Entra en <https://supabase.com> → **New project**.
2. Nombre: `game-test-1` (el que quieras). Región: la más cercana (p. ej. *West EU (Paris)* o *Central EU (Frankfurt)*).
3. Contraseña de la base de datos: genera una y guárdala en tu gestor de contraseñas. **No** va en la app ni en el repositorio.
4. Espera a que el proyecto termine de crearse (1-2 minutos).

### 2. Crear las tablas (migración)

1. En el menú izquierdo: **SQL Editor** → **New query**.
2. Copia **todo** el contenido de `backend/supabase/migrations/001_cuentas.sql`, pégalo y pulsa **Run**.
   Debe terminar con *Success. No rows returned*. (Se puede volver a ejecutar sin problema.)
3. Compruébalo en **Table Editor**: aparecen `profiles` y `characters`, las dos con el candado de **RLS enabled**.

### 3. Configurar el inicio de sesión (Authentication)

1. **Authentication → Sign In / Providers → Email**:
   - *Enable Email provider*: **activado**.
   - *Confirm email*: **DESACTIVADO** (imprescindible: los emails son sintéticos y nadie los va a recibir; ver abajo).
   - Guarda.
2. **Authentication → Sign In / Providers** (arriba, ajustes generales): *Allow new users to sign up*: **activado**.
3. Recomendado: en los ajustes de contraseñas (*Password requirements* / *Minimum password length*) pon **8**,
   que es lo mismo que exige la app.

### 4. Copiar la URL y la clave pública

En **Project Settings → API Keys** (o con el botón **Connect** de arriba):

- **Project URL**: `https://xxxxxxxxxxxx.supabase.co`
- **Clave pública**: la *Publishable key* (`sb_publishable_...`) o, en proyectos con claves antiguas, la *anon public* (un JWT largo `eyJ...`).

> ⚠️ **Nunca** copies la `service_role` ni una *Secret key* (`sb_secret_...`): dan acceso total a la base de datos.
> La app las detecta y se niega a usarlas. La clave pública sí puede ir dentro de la app: la seguridad la da RLS.

### 5. Pegar la configuración en el proyecto

```bash
cp backend/SupabaseConfig.example.plist src/GameTest1/Resources/SupabaseConfig.plist
open -e src/GameTest1/Resources/SupabaseConfig.plist     # o ábrelo en Xcode
```

Rellena `SUPABASE_URL` y `SUPABASE_CLAVE_PUBLICA` (deja `EMAIL_PLANTILLA` como está de momento) y después:

```bash
make project      # para que Xcode meta el fichero en la app (obligatorio la primera vez)
make mac          # o compila para el simulador
```

`git status` **no** debe mostrar `SupabaseConfig.plist` (está en `.gitignore`).

---

## Cómo se consigue "usuario y contraseña" con Supabase

Supabase Auth inicia sesión con **email + contraseña** (no tiene "nombre de usuario" propio). Opciones:

| Opción | Cómo | A favor | En contra |
|---|---|---|---|
| **A. Email sintético** (la elegida) | El jugador escribe `pepe` + contraseña; la app usa por debajo el email `pepe@jugadores.valdehierro.app` (plantilla `EMAIL_PLANTILLA`). | El jugador solo ve usuario y contraseña. Sin correos, sin servidor de email, sin datos personales. | **No hay "he olvidado mi contraseña"** (no hay un email real). Hay que desactivar *Confirm email*. |
| B. Email real + nombre de usuario | Registro con email real y usuario; para entrar con el usuario hace falta buscar su email (función en el servidor). | Recuperar contraseña por email. | Pide el email (dato personal), hay que configurar SMTP propio, y la búsqueda usuario→email expone emails si no se hace con cuidado. |
| C. Solo email | Entrar con email + contraseña. | Lo estándar de Supabase. | No es lo que se pidió (usuario). |

Se ha elegido **A** para empezar: es lo que se pidió y no necesita nada más. Si más adelante hace falta recuperar
contraseñas, se puede pasar a B sin perder cuentas (añadiendo un email real a cada usuario).

Detalles:
- El nombre de usuario no distingue mayúsculas (`Pepe` = `pepe`), tiene 3-20 caracteres `a-z`, `0-9` y `_`
  (sin acentos ni ñ, porque forma parte del email). Las mismas reglas están en la app (`AccountRules`) y en la base
  de datos (`profiles_username_formato`).
- Al registrarse, un trigger crea la fila de `profiles` con el usuario. Si el usuario ya existe, el registro falla entero.
- **`EMAIL_PLANTILLA`**: `{usuario}` se sustituye por el nombre. El dominio por defecto (`jugadores.valdehierro.app`)
  no recibe correo: con *Confirm email* desactivado, Supabase no envía nada.
  Si al crear una cuenta la app dice *"Supabase no acepta el email sintético"* (error `email_address_invalid`:
  Supabase puede rechazar dominios que no existen), cambia la plantilla por una dirección tuya con "+",
  por ejemplo `tucorreo+{usuario}@gmail.com` (todas llegan a tu buzón; así además podrías recuperar cuentas a mano).
  **Ojo**: cambiar la plantilla cuando ya hay cuentas hace que esas cuentas no puedan entrar (su email es otro).

---

## Cómo funciona la sincronización

- **Al iniciar sesión** (y al abrir la app con la sesión guardada): se compara lo local con la nube y se sube, baja o borra.
  Los personajes creados sin cuenta en ese dispositivo pasan a la cuenta.
- **Al guardar** (cualquier `GameStore.save()`): si el personaje ha cambiado, se sube a los ~4 segundos
  (se agrupan varios guardados seguidos).
- **Durante una partida** solo se sube; lo que llegue de la nube se aplica al volver a la selección de personaje.
  En la arena se sube siempre el personaje de verdad (`store.character`), nunca la copia temporal de la partida.
- **Sin conexión**: se sigue jugando y guardando en local; se sube en la siguiente sincronización.
- **Conflictos** (lógica en `RosterSync.plan`, GameCore, con tests):
  - Cada fila tiene `version` (la sube un trigger en cada escritura) y `updated_at` (hora del servidor).
  - La app recuerda con qué versión coincidía cada personaje (`sync-cuenta.json`) y si ha cambiado desde entonces.
  - Solo cambió un lado → gana ese lado. Cambiaron los dos → **gana el cambio más reciente**.
  - Borrado en un lado y jugado en el otro → **se conserva** el personaje (no se pierde progreso).
  - Las subidas llevan la versión esperada (`PATCH ...?version=eq.N`): si otro dispositivo escribió entretanto,
    no se pisa y se vuelve a decidir.
  - Lo que se sustituye o se borra en local por la sincronización se copia antes en `copias-cuenta/`.
- **Otra cuenta en el mismo dispositivo**: los personajes de la cuenta anterior se apartan a `copias-cuenta/` y se
  bajan los de la nueva (los de la anterior siguen en la nube).
- **Cerrar sesión**: hace una última subida; los personajes se quedan en el dispositivo.
- Máximo **8 personajes** por cuenta (como en la selección de personaje; lo comprueba también un trigger).

Ficheros locales (en `~/Library/Application Support/GameTest1/` en el Mac, o en el contenedor de la app en iOS):
`roster.json` (personajes), `sync-cuenta.json` (estado de la sincronización), `copias-cuenta/` (copias de seguridad).
La sesión (tokens) está en el **llavero**; la contraseña no se guarda nunca.

---

## Cómo probarlo

1. **Sin configuración**: sin `SupabaseConfig.plist`, en la selección de personaje el botón **👤 CUENTA** dice
   *Sin cuenta* y al pulsarlo explica que se juega en local.
2. **Crear cuenta** (Mac: `make mac`): 👤 CUENTA → CREAR CUENTA → usuario `prueba1`, contraseña de 8+ caracteres.
   Debe decir *Conectado como prueba1* y *✓ Guardado en la nube*.
   En Supabase → **Table Editor → characters** aparecen tus personajes; en `profiles`, tu usuario;
   en **Authentication → Users**, `prueba1@jugadores.valdehierro.app`.
3. **Jugar y guardar**: juega un poco en el pueblo; a los segundos sube la `version` de la fila en `characters`.
4. **Otro dispositivo**: abre el simulador de iOS (o borra los datos locales), 👤 CUENTA → INICIAR SESIÓN con el mismo
   usuario: aparecen los mismos personajes. (En un dispositivo nuevo sin personajes, el botón está en la pantalla
   de creación de personaje.)
5. **Seguridad (RLS)**: sin sesión no se ve nada:
   ```bash
   curl "https://xxxxxxxxxxxx.supabase.co/rest/v1/characters?select=id" -H "apikey: <clave pública>"
   # → [] o un error de permisos, nunca personajes
   ```
   Y desde el SQL Editor puedes comprobar que las políticas existen:
   `select tablename, policyname, cmd from pg_policies where schemaname = 'public';`
6. **Sin conexión**: corta la red, juega, vuelve a conectar y pulsa ⟳ SINCRONIZAR.

Tests de la lógica: `make test` (suites *Cuenta: reglas y configuración* y *Cuenta: sincronización de personajes*).

---

## Panel de administración (ajustes en vivo)

Un panel web aparte del juego (`admin/`) para ver los datos de los jugadores y **balancear en vivo** (monstruos,
piezas, zonas, economía…) sin publicar una versión nueva de la app:

1. En el panel se crea un **borrador** con los ajustes (un documento `GameTuning` en JSON; contrato en `assets/admin/contrato.md`).
2. Se **publica**: pasa a ser *la* configuración publicada (solo hay una) y la anterior queda archivada.
3. El juego la **descarga al abrirse** (y al volver a primer plano, como mucho cada 15 minutos) con la clave pública
   y la aplica **antes de la siguiente partida**.
4. Si algo sale mal, se **vuelve atrás** a cualquier versión anterior en un clic.

### Esquema (migración 002)

| Tabla | Qué guarda | Quién la ve | Quién la escribe |
|---|---|---|---|
| `admins` | `user_id` de los administradores | los admins | **nadie desde la API**: solo a mano en el SQL Editor |
| `game_config` | `id`, `version` (nº de publicación; null en borradores), `status` (`draft` / `published` / `archived`), `data` (el `GameTuning`), `schema_version`, `note`, `created_by`, `created_at`, `updated_at`, `published_at`, `published_by` | los admins (todo) | los admins, **solo borradores** y solo `data`, `schema_version` y `note`; publicar y volver atrás, solo con las RPC |
| `admin_audit` | quién (`actor`, `actor_name`), qué (`action`), cuándo (`created_at`), `config_id`, `version`, `summary` y `diff` (cambios campo a campo) | los admins | nadie desde la API: lo escriben las RPC y los triggers |

- `version` la pone el servidor al publicar: 1, 2, 3… y **siempre crece** (volver atrás publica una *copia* con un número nuevo).
- Lo único que puede leer `anon` (el juego) es la función `published_config()`: la fila publicada (versión, formato,
  datos y fecha). Ni borradores, ni archivadas, ni notas, ni quién publicó.
- Los datos de los jugadores se leen solo con funciones para admins, **en solo lectura** y **sin correos** ni contraseñas
  (las contraseñas no están en estas tablas: las guarda Supabase Auth cifradas con bcrypt, y nadie las puede leer).

### 1. Aplicar la migración

1. Antes, la 001 (paso 2 de arriba).
2. **SQL Editor → New query** → pega **todo** `backend/supabase/migrations/002_panel.sql` → **Run**.
   Debe terminar con *Success. No rows returned*. Se puede volver a ejecutar.
3. **Table Editor**: aparecen `admins`, `game_config` y `admin_audit` con el candado de **RLS enabled**.
4. Opcional pero recomendado: **New query** → pega `backend/supabase/tests/002_panel_comprobaciones.sql` → **Run**.
   Hace de anon, de jugador y de admin con dos usuarios de prueba y lo deshace todo al final (`rollback`).
   Si algo falla, se para con un error que empieza por **FALLO:**; si no, todo está bien.
   (Si diera *permission denied for table users*, tu proyecto no deja crear usuarios desde el SQL Editor: sáltatelo y
   haz las pruebas de "Cómo probarlo" de abajo.)

### 2. Hacerte administrador

Un admin es una cuenta normal cuyo id está en `admins`. No hay forma de hacerse admin desde la app ni desde la web.

1. Crea tu cuenta **desde el juego** (👤 CUENTA → CREAR CUENTA), por ejemplo `sergi`.
   (También vale *Authentication → Users → Add user* con *Auto Confirm User*, pero la parte del email antes de la @ debe
   ser un nombre de usuario válido —3-20 caracteres `a-z`, `0-9`, `_`— o el registro falla: es el trigger de la 001.)
2. En el **SQL Editor**:
   ```sql
   insert into public.admins (user_id, note)
   select id, 'Sergi' from public.profiles where username = 'sergi';
   ```
   Debe decir *1 row affected*. (Queda apuntado en `admin_audit`.)
3. Para quitar un admin: `delete from public.admins where user_id = (select id from public.profiles where username = 'sergi');`

Recomendado: una cuenta de admin aparte de la que usas para jugar, con una contraseña larga y única.

### 3. Qué clave usa la web

La web usa **la misma clave pública** que el juego (*Publishable key* `sb_publishable_...` o la *anon* antigua) y la URL
del proyecto. Esa clave **se puede ver** (está dentro de la app y de la web, y puede ir en un repositorio público):
por sí sola no da acceso a nada. La seguridad la dan **RLS** y las comprobaciones dentro de cada función
(`is_admin()`): sin sesión de admin no se pueden leer borradores, ni publicar, ni ver jugadores.

> ⚠️ **Nunca** pongas la `service_role` ni una *Secret key* (`sb_secret_...`) en la web, en la app ni en el repositorio:
> se salta RLS y da acceso total. El panel no la necesita para nada.

El administrador inicia sesión en la web con su **usuario y contraseña** del juego (la web usa la misma plantilla de
email sintético, `EMAIL_PLANTILLA`). Su token de sesión es el que le da permisos de admin.

### 4. Publicar y volver atrás

Desde la web (o por la API, ver la referencia de abajo):

- **Borrador**: crear uno nuevo (vacío o copiando la publicada), editarlo y guardarlo. Se pueden tener varios.
- **Revisar**: `config_diff(draft_id)` enseña qué cambia respecto a la publicada (campo a campo).
- **Publicar**: `publish_config(draft_id)`. El borrador recibe el siguiente número de versión y la publicada pasa a archivada.
  Los jugadores la reciben al abrir el juego o volver a él (como mucho cada 15 min) y la aplican en la siguiente partida.
- **Volver atrás**: `rollback_config(version)` con la versión buena (por ejemplo la 3): se publica una copia como versión
  nueva (p. ej. la 6, con la nota *"Vuelta a la versión 3"*). Así el juego la ve como un cambio más y la aplica.
- **Registro**: todo queda en `admin_audit` (borradores creados, guardados y borrados; publicaciones; vueltas atrás; altas
  y bajas de admins), con un resumen y la lista de cambios.

**Botón de emergencia** (sin la web): volver a los valores de serie del juego para todos. En el SQL Editor:
```sql
update public.game_config set status = 'archived' where status = 'published';
```
El juego verá que no hay nada publicado y volverá a sus valores de serie en la siguiente partida (queda en el registro como
`manual_update`). Para volver a publicar algo, usa la web (publicar un borrador o volver a una versión).

### 5. Qué ve un jugador

- **Nada nuevo en pantalla**, salvo que los números cambian. En 👤 CUENTA aparece una línea pequeña: *Ajustes del juego:
  versión N* (o *de serie*), y si ha llegado una nueva durante la partida, *hay cambios para la siguiente partida*.
- No necesita cuenta: los ajustes se descargan sin sesión, con la clave pública.
- Se aplican en la selección de personaje o al pulsar HISTORIA / ARENA, **nunca a mitad de un combate**. Lo que llega
  durante una partida se aplica en la siguiente.
- Sin conexión, se aplica la última descargada (`ajustes-en-vivo.json`, junto a `roster.json`); la primera vez sin red,
  los valores de serie.
- Lo ya conseguido no cambia: un arma o armadura ya forjada conserva sus números (ver el contrato).
- Si el formato (`schema_version`) es más nuevo que el que entiende su versión del juego, la ignora (sigue con la anterior)
  hasta que actualice la app; queda un aviso en el log.
- Sin `SupabaseConfig.plist` el juego no descarga nada ni mira la caché: valores de serie, como siempre.
- Los avisos (ids desconocidos, valores recortados) salen en el log del sistema: en el Mac, **Consola.app** filtrando por
  *ajustes-en-vivo* (o en la consola de Xcode).

### Referencia de la API para la web

Todas las peticiones llevan la cabecera `apikey: <clave pública>`. Las de admin, además,
`Authorization: Bearer <access_token del admin>` (de `POST /auth/v1/token?grant_type=password` con el email sintético).
Las RPC son `POST /rest/v1/rpc/<nombre>` con los parámetros en un JSON (las que solo leen también admiten `GET`).

| Llamada | Quién | Devuelve |
|---|---|---|
| `GET /rest/v1/rpc/published_config` | cualquiera | `[]` o `[{ "version", "schema_version", "data", "published_at" }]` |
| `POST /rest/v1/rpc/is_admin` `{}` | con sesión | `true` / `false` |
| `GET /rest/v1/game_config?select=*&order=id.desc` | admins | todas las filas (borradores, publicada, archivadas) |
| `POST /rest/v1/game_config` `{ "data": {…}, "schema_version": 1, "note": "…" }` + `Prefer: return=representation` | admins | el borrador creado (`status: "draft"`, `version: null`) |
| `PATCH /rest/v1/game_config?id=eq.7` `{ "data": {…}, "note": "…" }` | admins | solo borradores (en otra fila no cambia nada) |
| `DELETE /rest/v1/game_config?id=eq.7` | admins | solo borradores |
| `POST /rest/v1/rpc/config_diff` `{ "draft_id": 7 }` | admins | `{ "from_version", "schema_version_before", "schema_version_after", "changes": [{ "path", "before", "after" }], "total", "truncated" }` |
| `POST /rest/v1/rpc/publish_config` `{ "draft_id": 7 }` | admins | la fila publicada |
| `POST /rest/v1/rpc/rollback_config` `{ "version": 3 }` | admins | la fila publicada nueva |
| `GET /rest/v1/admin_audit?select=*&order=created_at.desc&limit=50` | admins | el registro |
| `POST /rest/v1/rpc/admin_summary` `{}` | admins | resumen (abajo) |
| `POST /rest/v1/rpc/admin_characters` `{ "search": "pepe", "page_size": 50, "page": 0 }` | admins | `[{ id, name, username, race, level, gold, arena_best_wave, quests_done, area, version, created_at, updated_at }]` |
| `POST /rest/v1/rpc/admin_character` `{ "character_id": "uuid" }` | admins | `[{ id, name, username, data, version, created_at, updated_at }]` (`data` = el `PlayerProfile`) |

Formato: guarda en la columna `schema_version` el mismo número que `schemaVersion` dentro de `data`
(`GameTuning.currentSchemaVersion`, hoy 1). El juego usa el mayor de los dos y, si es más nuevo que el suyo, ignora la
configuración. La `version` de dentro de `data` no hace falta: el juego pone la de la fila publicada.

`admin_summary()` devuelve:
`accounts`, `accounts_with_characters`, `characters`, `active_last_24h`, `active_last_7d`, `by_race` (`{ "elf": 3, … }`),
`by_level` y `by_race_and_level` (`[{ race, level, characters }]`), `gold` (`average`, `median`, `max`, `by_level`),
`arena` (`record`, `players`, `average_best_wave`, `top`: 10 mejores con `wave`, `character`, `username`, `race`, `level`),
`story` (`average_quests_done`, `quests_done_distribution`, `quests`: `[{ quest, accepted, done }]`, `dungeons_won`,
`princess_rescued`, `average_villagers_rescued`, `by_area`) y `generated_at`.

Errores (PostgREST: `{ code, message, hint }`): `42501` / hint `no_admin` (no eres admin), `P0002` / `no_existe`,
`22023` / `no_es_borrador` o `ya_publicada`. Si un PATCH o DELETE no encuentra la fila (no es un borrador), devuelve una
lista vacía, sin error.

### Cómo probarlo

1. Aplica la 002 y (opcional) las comprobaciones (pasos 1 y 2).
2. Sin sesión, con la clave pública, solo se ve lo publicado:
   ```bash
   URL=https://xxxxxxxxxxxx.supabase.co; KEY=<clave pública>
   curl "$URL/rest/v1/rpc/published_config" -H "apikey: $KEY"          # → [] (aún no hay nada publicado)
   curl "$URL/rest/v1/game_config?select=id" -H "apikey: $KEY"          # → error de permisos (42501)
   curl -X POST "$URL/rest/v1/rpc/publish_config" -H "apikey: $KEY" -H "Content-Type: application/json" -d '{"draft_id":1}'
                                                                        # → error de permisos
   ```
3. Publica algo visible con la web: por ejemplo, el oro con el que se empieza la arena, `{"economy": {"arenaStartingGold": 500}}`.
   Mientras no exista la web, desde el SQL Editor haciéndote pasar por tu cuenta de admin (así no escribes la contraseña
   en ningún sitio; las comprobaciones de admin funcionan igual):
   ```sql
   begin;
   select set_config('request.jwt.claims', json_build_object('sub', (select id from public.profiles where username = 'sergi'),
                     'role', 'authenticated')::text, true);
   set local role authenticated;
   insert into public.game_config (data, note) values ('{"economy": {"arenaStartingGold": 500}}', 'Prueba: 500 de oro en la arena');
   select version, status, note from public.publish_config((select max(id) from public.game_config where status = 'draft'));
   commit;
   ```
   Y para volver atrás a una versión: igual, pero con `select version, note from public.rollback_config(1);`.
4. Abre el juego (`make mac`): en 👤 CUENTA debe poner *Ajustes del juego: versión 1*; entra en la ARENA y empiezas con 500 de oro.
5. Vuelve atrás (o usa el botón de emergencia), vuelve a la selección de personaje (o cierra y abre la app) y comprueba que
   el oro inicial vuelve a ser el de serie.
6. Sin red: corta la conexión y abre el juego: sigue con la última versión descargada.


| Mensaje en la app | Causa | Solución |
|---|---|---|
| *Las cuentas todavía no están activadas* | Falta `SupabaseConfig.plist`, tiene los valores de ejemplo, o no se hizo `make project`. | Paso 5. |
| *Esa clave es secreta…* | Has pegado la `service_role` / `sb_secret_`. | Usa la clave pública (paso 4). |
| *Supabase pide confirmar el email* | *Confirm email* está activado. | Paso 3. |
| *Supabase no acepta el email sintético* | El dominio de `EMAIL_PLANTILLA` no es aceptado. | Usa `tucorreo+{usuario}@gmail.com`. |
| *Faltan las tablas en Supabase* | No se ejecutó la migración. | Paso 2. |
| Log *Falta la función en Supabase: ejecuta … 002_panel.sql* | No se ejecutó la 002. El juego sigue con los valores de serie. | Panel, paso 1. |
| Log *se ignora la versión N: su formato … es más nuevo* | Se publicó un `schema_version` que esta versión del juego no entiende. | Actualizar la app, o volver atrás. |
| La web dice que no eres admin | Tu `user_id` no está en `admins`. | Panel, paso 2. |
| *Ese nombre de usuario ya existe* | Usuario ocupado. | Otro nombre. |
| *Demasiados intentos* | Límite de peticiones de Supabase Auth. | Espera; se ajusta en Authentication → Rate Limits. |
| Mac: aviso del llavero al abrir la app | La versión de Mac se firma en local y cambia al recompilar. | "Permitir siempre". |

## Más adelante

- Recuperar contraseña (opción B: email real opcional).
- Borrar la cuenta desde la app (hoy: Supabase → Authentication → Users → borrar; sus filas se borran en cascada).
- Servicios online (MMO): nuevas tablas o funciones aquí, en `backend/supabase/migrations/003_...sql`.
