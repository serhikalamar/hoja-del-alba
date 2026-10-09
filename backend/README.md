# Backend: cuentas y personajes en la nube (Supabase)

El jugador puede crear una cuenta con **usuario y contraseña** y sus personajes se guardan en la nube.
Sin cuenta (o sin configurar Supabase), el juego funciona igual que siempre: todo se guarda en el dispositivo.

```
backend/
  supabase/migrations/001_cuentas.sql   Tablas, triggers y seguridad (RLS). Se pega en el SQL Editor.
  SupabaseConfig.example.plist          Plantilla de configuración de la app (sí se versiona)
src/GameTest1/Resources/SupabaseConfig.plist   Configuración real (NO se versiona, está en .gitignore)
src/GameTest1/Account/                  Cliente REST, sesión (llavero), sincronización y pantalla de cuenta
src/GameCore/Sources/GameCore/CloudSync.swift  Reglas puras (usuario, contraseña, conflictos) con tests
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

## Problemas frecuentes

| Mensaje en la app | Causa | Solución |
|---|---|---|
| *Las cuentas todavía no están activadas* | Falta `SupabaseConfig.plist`, tiene los valores de ejemplo, o no se hizo `make project`. | Paso 5. |
| *Esa clave es secreta…* | Has pegado la `service_role` / `sb_secret_`. | Usa la clave pública (paso 4). |
| *Supabase pide confirmar el email* | *Confirm email* está activado. | Paso 3. |
| *Supabase no acepta el email sintético* | El dominio de `EMAIL_PLANTILLA` no es aceptado. | Usa `tucorreo+{usuario}@gmail.com`. |
| *Faltan las tablas en Supabase* | No se ejecutó la migración. | Paso 2. |
| *Ese nombre de usuario ya existe* | Usuario ocupado. | Otro nombre. |
| *Demasiados intentos* | Límite de peticiones de Supabase Auth. | Espera; se ajusta en Authentication → Rate Limits. |
| Mac: aviso del llavero al abrir la app | La versión de Mac se firma en local y cambia al recompilar. | "Permitir siempre". |

## Más adelante

- Recuperar contraseña (opción B: email real opcional).
- Borrar la cuenta desde la app (hoy: Supabase → Authentication → Users → borrar; sus filas se borran en cascada).
- Servicios online (MMO): nuevas tablas o funciones aquí, en `backend/supabase/migrations/002_...sql`.
