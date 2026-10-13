-- 002_panel_comprobaciones.sql — Comprueba la seguridad del panel (RLS, permisos y RPC).
--
-- Cómo usarlo: SQL Editor de Supabase → New query → pega TODO el fichero → Run.
-- - Va entero dentro de una transacción que se deshace al final (rollback): no deja nada en la base de datos.
-- - Crea dos usuarios de prueba (un admin y un jugador) y hace de "anon", de jugador y de admin con `set local role`.
-- - Si algo falla, se para con un error que empieza por "FALLO:". Si termina sin errores, todo está bien.
-- - Requiere haber ejecutado antes 001_cuentas.sql y 002_panel.sql.
-- También vale con psql contra un Supabase local: psql "$DB_URL" -v ON_ERROR_STOP=1 -f backend/supabase/tests/002_panel_comprobaciones.sql

begin;

-- ---------------------------------------------------------------------------
-- Preparación (como postgres): un admin, un jugador con dos personajes
-- ---------------------------------------------------------------------------

insert into auth.users (id, email, raw_user_meta_data) values
    ('00000000-0000-4000-8000-00000000ad01', 'zz_prueba_admin@jugadores.valdehierro.app', '{"username": "zz_prueba_admin"}'),
    ('00000000-0000-4000-8000-00000000ad02', 'zz_prueba_jugador@jugadores.valdehierro.app', '{"username": "zz_prueba_jugador"}');

insert into public.admins (user_id, note) values ('00000000-0000-4000-8000-00000000ad01', 'prueba');

insert into public.characters (id, owner, name, data) values
    ('00000000-0000-4000-8000-0000000c0001', '00000000-0000-4000-8000-00000000ad02', 'Prueba Uno',
     '{"race": "elf", "level": 7, "gold": 120, "arenaBestWave": 999001,
       "quests": {"valdemar.prueba": {"accepted": true, "progress": [1], "done": true}},
       "townProgress": {"killedSpawns": [], "rescued": ["a", "b"], "princessRescued": true}}'),
    ('00000000-0000-4000-8000-0000000c0002', '00000000-0000-4000-8000-00000000ad02', 'Prueba Dos',
     '{"race": "dwarf", "level": "raro", "gold": 30}');

-- Lo que hubiera ya publicado antes de la prueba (en un proyecto en uso no se empieza de cero).
select set_config('pruebas.version_previa', coalesce((select max(version) from public.game_config), 0)::text, true);

-- ---------------------------------------------------------------------------
-- Admin
-- ---------------------------------------------------------------------------

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-4000-8000-00000000ad01", "role": "authenticated"}', true);

do $$
declare
    previa integer := current_setting('pruebas.version_previa')::integer;
    b1 bigint;
    b2 bigint;
    fila public.game_config;
    n integer;
    resumen jsonb;
begin
    if not public.is_admin() then raise exception 'FALLO: el admin de prueba no es admin'; end if;

    -- Crear borradores (por REST sería POST /rest/v1/game_config).
    insert into public.game_config (data, note) values ('{"prueba": {"vida": 10}}', 'prueba 1') returning id into b1;
    insert into public.game_config (data, note) values ('{"prueba": {"vida": 20}}', 'prueba 2') returning id into b2;

    -- Editar un borrador sí se puede.
    update public.game_config set note = 'prueba 1 editada' where id = b1;
    get diagnostics n = row_count;
    if n <> 1 then raise exception 'FALLO: el admin no puede editar un borrador'; end if;

    -- Publicar.
    fila := public.publish_config(b1);
    if fila.status <> 'published' or fila.version <> previa + 1 then
        raise exception 'FALLO: publish_config no publicó la versión % (%, %)', previa + 1, fila.status, fila.version;
    end if;
    fila := public.publish_config(b2);
    if fila.version <> previa + 2 then raise exception 'FALLO: la segunda publicación no es la versión %', previa + 2; end if;
    if (select count(*) from public.game_config where status = 'published') <> 1 then
        raise exception 'FALLO: hay más de una configuración publicada';
    end if;
    if (select status from public.game_config where id = b1) <> 'archived' then
        raise exception 'FALLO: la publicada anterior no se archivó';
    end if;

    -- Publicar algo que no es borrador: error.
    begin
        perform public.publish_config(b1);
        raise exception 'FALLO: se pudo publicar una configuración archivada';
    exception when invalid_parameter_value then null;
    end;

    -- Volver a la versión previa+1: se publica una copia con número nuevo.
    fila := public.rollback_config(previa + 1);
    if fila.version <> previa + 3 or fila.data <> '{"prueba": {"vida": 10}}'::jsonb then
        raise exception 'FALLO: rollback_config no publicó una copia de la versión %', previa + 1;
    end if;

    -- Las publicadas y archivadas no se pueden tocar por REST (RLS: solo borradores).
    update public.game_config set note = 'pirata' where version = previa + 3;
    get diagnostics n = row_count;
    if n <> 0 then raise exception 'FALLO: el admin pudo editar la configuración publicada sin RPC'; end if;
    delete from public.game_config where version = previa + 1;
    get diagnostics n = row_count;
    if n <> 0 then raise exception 'FALLO: el admin pudo borrar una versión archivada'; end if;

    -- El estado y la versión solo los ponen las RPC (sin permiso sobre esas columnas).
    begin
        insert into public.game_config (data, status, version, published_at) values ('{}', 'published', 99999, now());
        raise exception 'FALLO: se pudo crear una configuración publicada sin RPC';
    exception when insufficient_privilege then null;
    end;
    begin
        update public.game_config set status = 'published' where id = b2;
        raise exception 'FALLO: se pudo cambiar el estado sin RPC';
    exception when insufficient_privilege then null;
    end;

    -- El registro existe y no se puede escribir.
    if (select count(*) from public.admin_audit where action in ('publish', 'rollback') and config_id >= b1) < 3 then
        raise exception 'FALLO: faltan entradas de publish/rollback en admin_audit';
    end if;
    begin
        insert into public.admin_audit (action, summary) values ('falso', 'falso');
        raise exception 'FALLO: el admin pudo escribir en admin_audit';
    exception when insufficient_privilege then null;
    end;
    -- Ni hacerse admin a otro desde la API.
    begin
        insert into public.admins (user_id) values ('00000000-0000-4000-8000-00000000ad02');
        raise exception 'FALLO: se pudo añadir un admin desde la API';
    exception when insufficient_privilege then null;
    end;

    -- Datos de los jugadores.
    resumen := public.admin_summary();
    if (resumen ->> 'characters')::integer < 2 or (resumen -> 'arena' ->> 'record')::bigint < 999001 then
        raise exception 'FALLO: admin_summary no cuenta los personajes de prueba: %', resumen;
    end if;
    if (select count(*) from public.admin_characters('zz_prueba_jugador')) <> 2 then
        raise exception 'FALLO: admin_characters no encuentra los personajes por usuario';
    end if;
    if (select c.data ->> 'race' from public.admin_character('00000000-0000-4000-8000-0000000c0001') c) <> 'elf' then
        raise exception 'FALLO: admin_character no devuelve el personaje';
    end if;
    -- Solo lectura: los personajes de otro no se pueden cambiar (RLS de la 001).
    update public.characters set name = 'pirata' where id = '00000000-0000-4000-8000-0000000c0001';
    get diagnostics n = row_count;
    if n <> 0 then raise exception 'FALLO: el admin pudo cambiar el personaje de otro jugador'; end if;

    -- Un borrador más, sin publicar: nadie salvo los admins debe verlo.
    insert into public.game_config (data, note) values ('{"secreto": "borrador-sin-publicar"}', 'borrador privado') returning id into b1;
    perform set_config('pruebas.borrador', b1::text, true);
    raise notice 'OK: admin';
end;
$$;

-- ---------------------------------------------------------------------------
-- Jugador con sesión, sin ser admin
-- ---------------------------------------------------------------------------

select set_config('request.jwt.claims', '{"sub": "00000000-0000-4000-8000-00000000ad02", "role": "authenticated"}', true);

do $$
declare
    borrador bigint := current_setting('pruebas.borrador')::bigint;
    previa integer := current_setting('pruebas.version_previa')::integer;
    n integer;
begin
    if public.is_admin() then raise exception 'FALLO: el jugador es admin'; end if;
    if (select count(*) from public.game_config) <> 0 then raise exception 'FALLO: el jugador ve filas de game_config'; end if;
    if (select count(*) from public.admin_audit) <> 0 then raise exception 'FALLO: el jugador ve el registro'; end if;
    if (select count(*) from public.admins) <> 0 then raise exception 'FALLO: el jugador ve la lista de admins'; end if;

    begin
        perform public.publish_config(borrador);
        raise exception 'FALLO: un jugador pudo publicar';
    exception when insufficient_privilege then null;
    end;
    begin
        perform public.rollback_config(previa + 1);
        raise exception 'FALLO: un jugador pudo volver atrás';
    exception when insufficient_privilege then null;
    end;
    begin
        perform public.admin_summary();
        raise exception 'FALLO: un jugador pudo ver el resumen';
    exception when insufficient_privilege then null;
    end;
    begin
        perform * from public.admin_character('00000000-0000-4000-8000-0000000c0001');
        raise exception 'FALLO: un jugador pudo ver un personaje con admin_character';
    exception when insufficient_privilege then null;
    end;
    begin
        insert into public.game_config (data) values ('{}');
        raise exception 'FALLO: un jugador pudo crear un borrador';
    exception when insufficient_privilege then null;
    end;
    update public.game_config set note = 'pirata';
    get diagnostics n = row_count;
    if n <> 0 then raise exception 'FALLO: un jugador pudo cambiar game_config'; end if;

    -- Lo publicado sí lo puede leer (es lo que descarga el juego).
    if (select count(*) from public.published_config()) <> 1 then raise exception 'FALLO: el jugador no ve la configuración publicada'; end if;
    raise notice 'OK: jugador';
end;
$$;

-- ---------------------------------------------------------------------------
-- Anon (el juego sin sesión, o cualquiera con la clave pública)
-- ---------------------------------------------------------------------------

reset role;
set local role anon;
select set_config('request.jwt.claims', '{"role": "anon"}', true);

do $$
declare
    borrador bigint := current_setting('pruebas.borrador')::bigint;
    previa integer := current_setting('pruebas.version_previa')::integer;
    fila record;
begin
    -- Solo la publicada: una fila, la última versión, sin rastro de borradores.
    if (select count(*) from public.published_config()) <> 1 then raise exception 'FALLO: anon no recibe exactamente 1 configuración'; end if;
    select * into fila from public.published_config();
    if fila.version <> previa + 3 then raise exception 'FALLO: anon no recibe la última publicada (recibe %)', fila.version; end if;
    if fila.data::text like '%borrador-sin-publicar%' then raise exception 'FALLO: anon ve un borrador'; end if;

    begin
        perform count(*) from public.game_config;
        raise exception 'FALLO: anon puede leer game_config (borradores incluidos)';
    exception when insufficient_privilege then null;
    end;
    begin
        perform count(*) from public.admin_audit;
        raise exception 'FALLO: anon puede leer admin_audit';
    exception when insufficient_privilege then null;
    end;
    begin
        perform count(*) from public.admins;
        raise exception 'FALLO: anon puede leer admins';
    exception when insufficient_privilege then null;
    end;
    begin
        perform count(*) from public.characters;
        raise exception 'FALLO: anon puede leer characters';
    exception when insufficient_privilege then null;
    end;
    begin
        perform public.publish_config(borrador);
        raise exception 'FALLO: anon pudo publicar';
    exception when insufficient_privilege then null;
    end;
    begin
        perform public.rollback_config(previa + 1);
        raise exception 'FALLO: anon pudo volver atrás';
    exception when insufficient_privilege then null;
    end;
    begin
        perform public.admin_summary();
        raise exception 'FALLO: anon pudo ver el resumen';
    exception when insufficient_privilege then null;
    end;
    begin
        perform * from public.admin_characters();
        raise exception 'FALLO: anon pudo ver la lista de personajes';
    exception when insufficient_privilege then null;
    end;
    raise notice 'OK: anon';
end;
$$;

reset role;
select 'OK: todas las comprobaciones del panel han pasado (se deshace todo con rollback)' as resultado;
rollback;
