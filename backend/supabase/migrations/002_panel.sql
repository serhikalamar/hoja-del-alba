-- 002_panel.sql — Panel de administración: ajustes en vivo (GameTuning) y resumen de jugadores.
--
-- Requiere la 001 (001_cuentas.sql). Se ejecuta una vez en el SQL Editor de Supabase (ver backend/README.md,
-- sección "Panel de administración"). Se puede volver a ejecutar sin romper nada.
--
-- Modelo:
--   public.admins        Quién es administrador. Solo se escribe a mano desde el SQL Editor (ni la app ni la web pueden).
--   public.game_config   Documentos de ajustes (GameTuning en JSON): borradores, LA publicada y las archivadas.
--   public.admin_audit   Registro de cambios. Lo escriben las funciones y triggers de aquí, nunca el cliente.
--
-- API (PostgREST, siempre con la clave PÚBLICA; la seguridad la dan RLS y las comprobaciones de dentro):
--   published_config()          anon y jugadores: la configuración publicada (lo que descarga el juego). 0 o 1 filas.
--   is_admin()                  con sesión: ¿soy admin?
--   config_diff(draft_id)       admins: qué cambia un borrador respecto a la publicada
--   publish_config(draft_id)    admins: publica un borrador y archiva la anterior
--   rollback_config(version)    admins: vuelve a publicar una versión antigua como versión nueva
--   admin_summary()             admins: resumen de jugadores (sin correos)
--   admin_characters(...)       admins: lista de personajes (solo lectura)
--   admin_character(id)         admins: un personaje completo (solo lectura)
--   Tablas por REST (solo admins, con RLS): game_config (leer todo; crear/editar/borrar BORRADORES), admin_audit (leer).
--
-- Versiones: `version` es el número de publicación (1, 2, 3...). Los borradores no tienen versión (null);
-- la reciben al publicarse. Volver atrás publica una copia con un número nuevo, así que la versión publicada
-- siempre crece. Solo puede haber una publicada a la vez.

-- ---------------------------------------------------------------------------
-- Administradores
-- ---------------------------------------------------------------------------

create table if not exists public.admins (
    user_id     uuid primary key references auth.users (id) on delete cascade,
    note        text,
    created_at  timestamptz not null default now()
);

comment on table public.admins is 'Administradores del panel. Se añaden a mano en el SQL Editor (ver backend/README.md).';

-- ¿El usuario de la petición es admin? (security definer: lee admins sin depender de su RLS).
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (select 1 from public.admins a where a.user_id = (select auth.uid()));
$$;

-- ---------------------------------------------------------------------------
-- Ajustes del juego (GameTuning)
-- ---------------------------------------------------------------------------

create table if not exists public.game_config (
    id              bigint generated always as identity primary key,
    -- Número de publicación; null en los borradores.
    version         integer,
    status          text not null default 'draft',
    -- El GameTuning tal cual lo decodifica el juego (contrato en assets/admin/contrato.md).
    data            jsonb not null default '{}'::jsonb,
    -- Versión del formato de `data`. El juego ignora (con un aviso) las que sean más nuevas que las que entiende.
    schema_version  integer not null default 1,
    note            text,
    created_by      uuid default auth.uid() references auth.users (id) on delete set null,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    published_at    timestamptz,
    published_by    uuid references auth.users (id) on delete set null,
    constraint game_config_estado check (status in ('draft', 'published', 'archived')),
    constraint game_config_version_segun_estado check ((status = 'draft') = (version is null)),
    constraint game_config_fecha_segun_estado check ((status = 'draft') = (published_at is null)),
    constraint game_config_version_positiva check (version is null or version > 0),
    constraint game_config_schema_positivo check (schema_version >= 1),
    constraint game_config_data_objeto check (jsonb_typeof(data) = 'object'),
    constraint game_config_data_tamano check (pg_column_size(data) <= 524288),  -- 512 KB
    constraint game_config_nota check (note is null or char_length(note) <= 500),
    constraint game_config_version_unica unique (version)
);

comment on table public.game_config is 'Ajustes en vivo (GameTuning): borradores, la publicada (solo una) y las archivadas.';

-- Solo una publicada a la vez.
create unique index if not exists game_config_una_publicada on public.game_config ((true)) where status = 'published';
create index if not exists game_config_estado_idx on public.game_config (status, version desc);

create or replace function public.game_config_antes_de_guardar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if tg_op = 'UPDATE' then
        new.created_at := old.created_at;
    end if;
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists game_config_antes_de_guardar on public.game_config;
create trigger game_config_antes_de_guardar
    before insert or update on public.game_config
    for each row execute function public.game_config_antes_de_guardar();

-- ---------------------------------------------------------------------------
-- Registro de cambios
-- ---------------------------------------------------------------------------

create table if not exists public.admin_audit (
    id          bigint generated always as identity primary key,
    created_at  timestamptz not null default now(),
    -- Quién (null = SQL Editor o el propio sistema). Sin clave ajena: el registro se conserva aunque se borre la cuenta.
    actor       uuid,
    actor_name  text,
    -- publish, rollback, draft_created, draft_updated, draft_deleted, admin_added, admin_removed, manual_*
    action      text not null,
    config_id   bigint,
    version     integer,
    summary     text not null,
    -- Detalle: { "from_version": n, "changes": [{ "path", "before", "after" }], "total": n, "truncated": bool }
    diff        jsonb
);

comment on table public.admin_audit is 'Registro de cambios del panel (solo lectura para admins; lo escriben las RPC y los triggers).';

create index if not exists admin_audit_fecha_idx on public.admin_audit (created_at desc);

-- Diferencias entre dos JSON: lista de { path, before, after } con las hojas que cambian.
-- Objetos por clave y listas por posición (p. ej. "enemies/goblin/hp", "zones/0/level").
create or replace function public.panel_diff(a jsonb, b jsonb, ruta text default '')
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
    resultado jsonb := '[]'::jsonb;
    clave text;
    i integer;
begin
    if a is not distinct from b then
        return resultado;
    end if;
    if jsonb_typeof(a) = 'object' and jsonb_typeof(b) = 'object' then
        for clave in
            select k from jsonb_object_keys(a) as t(k)
            union
            select k from jsonb_object_keys(b) as t(k)
            order by 1
        loop
            resultado := resultado || public.panel_diff(a -> clave, b -> clave,
                                                        case when ruta = '' then clave else ruta || '/' || clave end);
        end loop;
        return resultado;
    end if;
    if jsonb_typeof(a) = 'array' and jsonb_typeof(b) = 'array' then
        for i in 0 .. greatest(jsonb_array_length(a), jsonb_array_length(b)) - 1 loop
            resultado := resultado || public.panel_diff(a -> i, b -> i,
                                                        case when ruta = '' then i::text else ruta || '/' || i end);
        end loop;
        return resultado;
    end if;
    return jsonb_build_array(jsonb_build_object('path', case when ruta = '' then '/' else ruta end, 'before', a, 'after', b));
end;
$$;

-- Las diferencias, recortadas a 300 entradas para no llenar el registro.
create or replace function public.panel_changes(a jsonb, b jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
    with d as (select public.panel_diff(a, b) as lista)
    select jsonb_build_object(
        'changes', coalesce((select jsonb_agg(e) from (select e from jsonb_array_elements(d.lista) as x(e) limit 300) as y), '[]'::jsonb),
        'total', jsonb_array_length(d.lista),
        'truncated', jsonb_array_length(d.lista) > 300
    )
    from d;
$$;

create or replace function public.panel_audit(accion text, config bigint, num_version integer, resumen text, detalle jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    quien uuid := (select auth.uid());
begin
    insert into public.admin_audit (actor, actor_name, action, config_id, version, summary, diff)
    values (
        quien,
        coalesce((select p.username from public.profiles p where p.id = quien), case when quien is null then 'SQL Editor' end),
        accion, config, num_version, left(resumen, 1000), detalle
    );
end;
$$;

-- Cambios en game_config hechos fuera de publish_config / rollback_config (borradores desde la web, o a mano).
create or replace function public.game_config_auditar()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    detalle jsonb;
begin
    -- Las RPC escriben su propio registro (más completo).
    if coalesce(current_setting('panel.en_rpc', true), '') = 'on' then
        return null;
    end if;
    if tg_op = 'INSERT' then
        perform public.panel_audit(
            case when new.status = 'draft' then 'draft_created' else 'manual_insert' end,
            new.id, new.version,
            format('Nuevo borrador %s%s', new.id, coalesce(': ' || new.note, '')),
            null);
    elsif tg_op = 'UPDATE' then
        -- Nada que contar (p. ej. "on delete set null" al borrar una cuenta).
        if old.data is not distinct from new.data and old.note is not distinct from new.note
           and old.schema_version = new.schema_version and old.status = new.status
           and old.version is not distinct from new.version then
            return null;
        end if;
        detalle := public.panel_changes(old.data, new.data);
        perform public.panel_audit(
            case when old.status = 'draft' and new.status = 'draft' then 'draft_updated' else 'manual_update' end,
            new.id, new.version,
            format('Configuración %s guardada: %s', new.id,
                   case when (detalle ->> 'total')::integer = 0 then 'sin cambios en los datos (nota o schema_version)'
                        else (detalle ->> 'total') || ' cambios en los datos' end),
            detalle);
    else
        perform public.panel_audit(
            case when old.status = 'draft' then 'draft_deleted' else 'manual_delete' end,
            old.id, old.version,
            format('Borrada la configuración %s%s', old.id, coalesce(' (versión ' || old.version || ')', '')),
            null);
    end if;
    return null;
end;
$$;

drop trigger if exists game_config_auditar on public.game_config;
create trigger game_config_auditar
    after insert or update or delete on public.game_config
    for each row execute function public.game_config_auditar();

-- Altas y bajas de administradores (se hacen a mano: quedan apuntadas).
create or replace function public.admins_auditar()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    usuario uuid := case when tg_op = 'DELETE' then old.user_id else new.user_id end;
    nombre text := (select p.username from public.profiles p where p.id = usuario);
begin
    perform public.panel_audit(
        case when tg_op = 'DELETE' then 'admin_removed' else 'admin_added' end,
        null, null,
        format('%s administrador: %s', case when tg_op = 'DELETE' then 'Quitado' else 'Nuevo' end, coalesce(nombre, usuario::text)),
        null);
    return null;
end;
$$;

drop trigger if exists admins_auditar on public.admins;
create trigger admins_auditar
    after insert or delete on public.admins
    for each row execute function public.admins_auditar();

-- ---------------------------------------------------------------------------
-- Lo que descarga el juego
-- ---------------------------------------------------------------------------

-- La configuración publicada (0 o 1 filas). Es lo ÚNICO del panel que puede leer `anon`: ni borradores ni archivadas.
-- GET /rest/v1/rpc/published_config
create or replace function public.published_config()
returns table (version integer, schema_version integer, data jsonb, published_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
    select c.version, c.schema_version, c.data, c.published_at
    from public.game_config c
    where c.status = 'published'
    limit 1;
$$;

-- ---------------------------------------------------------------------------
-- Publicar y volver atrás (solo admins)
-- ---------------------------------------------------------------------------

create or replace function public.panel_exigir_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if not public.is_admin() then
        raise exception 'Solo los administradores pueden hacer esto' using errcode = '42501', hint = 'no_admin';
    end if;
end;
$$;

-- Qué cambia un borrador respecto a la configuración publicada (para revisarlo antes de publicar).
-- POST /rest/v1/rpc/config_diff  { "draft_id": 7 }
create or replace function public.config_diff(draft_id bigint)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    borrador public.game_config;
    actual public.game_config;
begin
    perform public.panel_exigir_admin();
    select * into borrador from public.game_config c where c.id = config_diff.draft_id;
    if not found then
        raise exception 'No existe la configuración %', config_diff.draft_id using errcode = 'P0002', hint = 'no_existe';
    end if;
    select * into actual from public.game_config c where c.status = 'published';
    return jsonb_build_object('from_version', actual.version, 'schema_version_before', actual.schema_version,
                              'schema_version_after', borrador.schema_version)
           || public.panel_changes(coalesce(actual.data, '{}'::jsonb), borrador.data);
end;
$$;

-- Publica un borrador: recibe el siguiente número de versión y la publicada pasa a archivada.
-- POST /rest/v1/rpc/publish_config  { "draft_id": 7 }   → la fila publicada
create or replace function public.publish_config(draft_id bigint)
returns public.game_config
language plpgsql
security definer
set search_path = ''
as $$
declare
    borrador public.game_config;
    anterior public.game_config;
    nueva public.game_config;
    siguiente integer;
    detalle jsonb;
begin
    perform public.panel_exigir_admin();
    -- Una publicación (o vuelta atrás) a la vez.
    lock table public.game_config in share row exclusive mode;

    select * into borrador from public.game_config c where c.id = publish_config.draft_id for update;
    if not found then
        raise exception 'No existe la configuración %', publish_config.draft_id using errcode = 'P0002', hint = 'no_existe';
    end if;
    if borrador.status <> 'draft' then
        raise exception 'La configuración % no es un borrador (está %)', borrador.id, borrador.status
            using errcode = '22023', hint = 'no_es_borrador';
    end if;

    select * into anterior from public.game_config c where c.status = 'published';
    select coalesce(max(c.version), 0) + 1 into siguiente from public.game_config c;

    perform set_config('panel.en_rpc', 'on', true);
    update public.game_config c set status = 'archived' where c.id = anterior.id;
    update public.game_config c
       set status = 'published', version = siguiente, published_at = now(), published_by = (select auth.uid())
     where c.id = borrador.id
    returning * into nueva;

    detalle := jsonb_build_object('from_version', anterior.version)
               || case when anterior.id is null then jsonb_build_object('changes', '[]'::jsonb, 'total', 0, 'truncated', false)
                       else public.panel_changes(anterior.data, nueva.data) end;
    perform public.panel_audit('publish', nueva.id, nueva.version,
        format('Publicada la versión %s (borrador %s)%s%s', nueva.version, nueva.id,
               case when anterior.id is null then ', la primera' else format(', sustituye a la %s: %s cambios', anterior.version, detalle ->> 'total') end,
               coalesce(' — ' || nueva.note, '')),
        detalle);
    perform set_config('panel.en_rpc', 'off', true);
    return nueva;
end;
$$;

-- Vuelve a publicar una versión antigua: se publica una COPIA con un número de versión nuevo
-- (así el juego, que solo mira la publicada, la descarga como un cambio más).
-- POST /rest/v1/rpc/rollback_config  { "version": 3 }   → la fila publicada nueva
create or replace function public.rollback_config(version integer)
returns public.game_config
language plpgsql
security definer
set search_path = ''
as $$
declare
    origen public.game_config;
    anterior public.game_config;
    nueva public.game_config;
    siguiente integer;
    detalle jsonb;
begin
    perform public.panel_exigir_admin();
    lock table public.game_config in share row exclusive mode;

    select * into origen from public.game_config c where c.version = rollback_config.version;
    if not found then
        raise exception 'No existe la versión %', rollback_config.version using errcode = 'P0002', hint = 'no_existe';
    end if;
    select * into anterior from public.game_config c where c.status = 'published';
    if anterior.id = origen.id then
        raise exception 'La versión % ya es la publicada', origen.version using errcode = '22023', hint = 'ya_publicada';
    end if;
    select coalesce(max(c.version), 0) + 1 into siguiente from public.game_config c;

    perform set_config('panel.en_rpc', 'on', true);
    update public.game_config c set status = 'archived' where c.id = anterior.id;
    insert into public.game_config (status, version, data, schema_version, note, published_at, published_by)
    values ('published', siguiente, origen.data, origen.schema_version,
            left(format('Vuelta a la versión %s', origen.version) || coalesce(': ' || origen.note, ''), 500),
            now(), (select auth.uid()))
    returning * into nueva;

    detalle := jsonb_build_object('from_version', anterior.version, 'restored_version', origen.version)
               || public.panel_changes(coalesce(anterior.data, '{}'::jsonb), nueva.data);
    perform public.panel_audit('rollback', nueva.id, nueva.version,
        format('Vuelta a la versión %s: publicada como versión %s%s', origen.version, nueva.version,
               coalesce(format(' (sustituye a la %s)', anterior.version), '')),
        detalle);
    perform set_config('panel.en_rpc', 'off', true);
    return nueva;
end;
$$;

-- ---------------------------------------------------------------------------
-- Datos de los jugadores (solo admins, solo lectura, sin correos)
-- ---------------------------------------------------------------------------

-- Un número del JSON como entero (null si falta o no es un número). No falla con datos raros.
create or replace function public.panel_int(valor jsonb)
returns bigint
language sql
immutable
set search_path = ''
as $$
    select case when jsonb_typeof(valor) = 'number'
                then trunc(least(greatest((valor #>> '{}')::numeric, -1e15), 1e15))::bigint end;
$$;

-- Cuántas misiones tiene entregadas un personaje (quests: { id: { accepted, progress, done } }).
create or replace function public.panel_misiones_hechas(datos jsonb)
returns integer
language sql
immutable
set search_path = ''
as $$
    select count(*)::integer
    from jsonb_each(case when jsonb_typeof(datos -> 'quests') = 'object' then datos -> 'quests' else '{}'::jsonb end) as q(k, v)
    where q.v ->> 'done' = 'true';
$$;

-- Resumen de los jugadores para balancear.
-- POST /rest/v1/rpc/admin_summary  {}
create or replace function public.admin_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    resultado jsonb;
begin
    perform public.panel_exigir_admin();

    with panel_p as (
        select c.id,
               c.owner,
               c.name,
               c.updated_at,
               coalesce(c.data ->> 'race', '?') as race,
               least(greatest(coalesce(public.panel_int(c.data -> 'level'), 1), 1), 60)::integer as level,
               coalesce(public.panel_int(c.data -> 'gold'), 0) as gold,
               public.panel_int(c.data -> 'arenaBestWave') as arena_wave,
               public.panel_misiones_hechas(c.data) as quests_done,
               coalesce(c.data ->> 'currentAreaID', 'town') as area,
               coalesce(c.data -> 'townProgress' ->> 'princessRescued', 'false') = 'true' as princess,
               case when jsonb_typeof(c.data -> 'townProgress' -> 'rescued') = 'array'
                    then jsonb_array_length(c.data -> 'townProgress' -> 'rescued') else 0 end as villagers,
               c.data
        from public.characters c
    )
    select jsonb_build_object(
        'generated_at', now(),
        'accounts', (select count(*) from public.profiles),
        'accounts_with_characters', (select count(distinct p.owner) from panel_p p),
        'characters', (select count(*) from panel_p),
        'active_last_24h', (select count(*) from panel_p p where p.updated_at > now() - interval '24 hours'),
        'active_last_7d', (select count(*) from panel_p p where p.updated_at > now() - interval '7 days'),
        'by_race', coalesce((select jsonb_object_agg(x.race, x.n) from
                                (select p.race, count(*) as n from panel_p p group by p.race) as x), '{}'::jsonb),
        'by_level', coalesce((select jsonb_agg(jsonb_build_object('level', x.level, 'characters', x.n) order by x.level) from
                                (select p.level, count(*) as n from panel_p p group by p.level) as x), '[]'::jsonb),
        'by_race_and_level', coalesce((select jsonb_agg(jsonb_build_object('race', x.race, 'level', x.level, 'characters', x.n)
                                                        order by x.race, x.level) from
                                (select p.race, p.level, count(*) as n from panel_p p group by p.race, p.level) as x), '[]'::jsonb),
        'gold', (select jsonb_build_object(
                     'average', coalesce(round(avg(p.gold)), 0),
                     'median', coalesce(percentile_cont(0.5) within group (order by p.gold), 0),
                     'max', coalesce(max(p.gold), 0),
                     'by_level', coalesce((select jsonb_agg(jsonb_build_object('level', y.level, 'average', y.media) order by y.level) from
                                  (select q.level, round(avg(q.gold)) as media from panel_p q group by q.level) as y), '[]'::jsonb))
                 from panel_p p),
        'arena', (select jsonb_build_object(
                      'record', max(p.arena_wave),
                      'players', count(p.arena_wave),
                      'average_best_wave', round(avg(p.arena_wave), 1),
                      'top', coalesce((select jsonb_agg(t order by t.wave desc, t.character) from (
                                  select q.arena_wave as wave, q.name as character, pr.username, q.race, q.level
                                  from panel_p q left join public.profiles pr on pr.id = q.owner
                                  where q.arena_wave is not null
                                  order by q.arena_wave desc, q.name limit 10) as t), '[]'::jsonb))
                  from panel_p p),
        'story', jsonb_build_object(
            'average_quests_done', (select coalesce(round(avg(p.quests_done), 1), 0) from panel_p p),
            'quests_done_distribution', coalesce((select jsonb_agg(jsonb_build_object('quests_done', x.qd, 'characters', x.n) order by x.qd) from
                                  (select p.quests_done as qd, count(*) as n from panel_p p group by p.quests_done) as x), '[]'::jsonb),
            'quests', coalesce((select jsonb_agg(jsonb_build_object('quest', x.k, 'accepted', x.aceptadas, 'done', x.hechas) order by x.hechas desc, x.k) from
                                  (select q.k, count(*) filter (where q.v ->> 'accepted' = 'true') as aceptadas,
                                          count(*) filter (where q.v ->> 'done' = 'true') as hechas
                                   from panel_p p,
                                        jsonb_each(case when jsonb_typeof(p.data -> 'quests') = 'object' then p.data -> 'quests' else '{}'::jsonb end) as q(k, v)
                                   group by q.k) as x), '[]'::jsonb),
            'dungeons_won', coalesce((select jsonb_agg(jsonb_build_object('dungeon', x.d, 'characters', x.n) order by x.n desc, x.d) from
                                  (select d.d, count(*) as n
                                   from panel_p p,
                                        jsonb_array_elements_text(case when jsonb_typeof(p.data -> 'wonDungeons') = 'array' then p.data -> 'wonDungeons' else '[]'::jsonb end) as d(d)
                                   group by d.d) as x), '[]'::jsonb),
            'princess_rescued', (select count(*) from panel_p p where p.princess),
            'average_villagers_rescued', (select coalesce(round(avg(p.villagers), 1), 0) from panel_p p),
            'by_area', coalesce((select jsonb_agg(jsonb_build_object('area', x.area, 'characters', x.n) order by x.n desc, x.area) from
                                  (select p.area, count(*) as n from panel_p p group by p.area) as x), '[]'::jsonb)
        )
    ) into resultado;
    return resultado;
end;
$$;

-- Lista de personajes (más recientes primero), con búsqueda por nombre de personaje o de usuario.
-- POST /rest/v1/rpc/admin_characters  { "search": "pepe", "page_size": 50, "page": 0 }
create or replace function public.admin_characters(search text default null, page_size integer default 50, page integer default 0)
returns table (
    id uuid, name text, username text, race text, level integer, gold bigint, arena_best_wave bigint,
    quests_done integer, area text, version integer, created_at timestamptz, updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform public.panel_exigir_admin();
    return query
    select c.id, c.name, pr.username,
           coalesce(c.data ->> 'race', '?'),
           least(greatest(coalesce(public.panel_int(c.data -> 'level'), 1), 1), 60)::integer,
           coalesce(public.panel_int(c.data -> 'gold'), 0),
           public.panel_int(c.data -> 'arenaBestWave'),
           public.panel_misiones_hechas(c.data),
           coalesce(c.data ->> 'currentAreaID', 'town'),
           c.version, c.created_at, c.updated_at
    from public.characters c
    left join public.profiles pr on pr.id = c.owner
    where admin_characters.search is null or btrim(admin_characters.search) = ''
       or strpos(lower(c.name), lower(btrim(admin_characters.search))) > 0
       or strpos(lower(coalesce(pr.username, '')), lower(btrim(admin_characters.search))) > 0
    order by c.updated_at desc, c.id
    limit least(greatest(coalesce(admin_characters.page_size, 50), 1), 200)
    offset greatest(coalesce(admin_characters.page, 0), 0) * least(greatest(coalesce(admin_characters.page_size, 50), 1), 200);
end;
$$;

-- Un personaje completo (el PlayerProfile en JSON). Solo lectura: no hay ninguna forma de cambiarlo desde el panel.
-- POST /rest/v1/rpc/admin_character  { "character_id": "uuid" }
create or replace function public.admin_character(character_id uuid)
returns table (id uuid, name text, username text, data jsonb, version integer, created_at timestamptz, updated_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform public.panel_exigir_admin();
    return query
    select c.id, c.name, pr.username, c.data, c.version, c.created_at, c.updated_at
    from public.characters c
    left join public.profiles pr on pr.id = c.owner
    where c.id = admin_character.character_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Seguridad (RLS y permisos)
-- ---------------------------------------------------------------------------

alter table public.admins enable row level security;
alter table public.game_config enable row level security;
alter table public.admin_audit enable row level security;

-- Nada para anon (el juego solo usa published_config()). Supabase da permisos por defecto: se quitan todos.
revoke all on public.admins from anon, authenticated;
revoke all on public.game_config from anon, authenticated;
revoke all on public.admin_audit from anon, authenticated;

-- admins: los admins ven la lista. Nadie escribe desde la API (solo a mano en el SQL Editor).
grant select on public.admins to authenticated;
drop policy if exists "admins: los admins ven la lista" on public.admins;
create policy "admins: los admins ven la lista"
    on public.admins for select to authenticated
    using ((select public.is_admin()));

-- game_config: los admins leen todo y crean, editan y borran BORRADORES.
-- Solo pueden escribir data, schema_version y note: el estado, la versión y la publicación los ponen las RPC.
grant select, delete on public.game_config to authenticated;
grant insert (data, schema_version, note) on public.game_config to authenticated;
grant update (data, schema_version, note) on public.game_config to authenticated;

drop policy if exists "ajustes: los admins leen todo" on public.game_config;
create policy "ajustes: los admins leen todo"
    on public.game_config for select to authenticated
    using ((select public.is_admin()));

drop policy if exists "ajustes: los admins crean borradores" on public.game_config;
create policy "ajustes: los admins crean borradores"
    on public.game_config for insert to authenticated
    with check ((select public.is_admin()) and status = 'draft' and version is null);

drop policy if exists "ajustes: los admins editan borradores" on public.game_config;
create policy "ajustes: los admins editan borradores"
    on public.game_config for update to authenticated
    using ((select public.is_admin()) and status = 'draft')
    with check ((select public.is_admin()) and status = 'draft' and version is null);

drop policy if exists "ajustes: los admins borran borradores" on public.game_config;
create policy "ajustes: los admins borran borradores"
    on public.game_config for delete to authenticated
    using ((select public.is_admin()) and status = 'draft');

-- admin_audit: los admins lo leen; nadie lo escribe desde la API.
grant select on public.admin_audit to authenticated;
drop policy if exists "registro: los admins lo leen" on public.admin_audit;
create policy "registro: los admins lo leen"
    on public.admin_audit for select to authenticated
    using ((select public.is_admin()));

-- Funciones: Supabase deja ejecutar todo lo nuevo a anon y authenticated; se quita y se da lo justo.
revoke execute on function public.is_admin() from public, anon, authenticated;
revoke execute on function public.published_config() from public, anon, authenticated;
revoke execute on function public.config_diff(bigint) from public, anon, authenticated;
revoke execute on function public.publish_config(bigint) from public, anon, authenticated;
revoke execute on function public.rollback_config(integer) from public, anon, authenticated;
revoke execute on function public.admin_summary() from public, anon, authenticated;
revoke execute on function public.admin_characters(text, integer, integer) from public, anon, authenticated;
revoke execute on function public.admin_character(uuid) from public, anon, authenticated;
-- Internas: no se llaman por la API.
revoke execute on function public.panel_diff(jsonb, jsonb, text) from public, anon, authenticated;
revoke execute on function public.panel_changes(jsonb, jsonb) from public, anon, authenticated;
revoke execute on function public.panel_audit(text, bigint, integer, text, jsonb) from public, anon, authenticated;
revoke execute on function public.panel_exigir_admin() from public, anon, authenticated;
revoke execute on function public.panel_int(jsonb) from public, anon, authenticated;
revoke execute on function public.panel_misiones_hechas(jsonb) from public, anon, authenticated;
revoke execute on function public.game_config_antes_de_guardar() from public, anon, authenticated;
revoke execute on function public.game_config_auditar() from public, anon, authenticated;
revoke execute on function public.admins_auditar() from public, anon, authenticated;

-- Lo que descarga el juego: cualquiera (con la clave pública), con o sin sesión.
grant execute on function public.published_config() to anon, authenticated;
-- Con sesión: comprobar si se es admin (la usan las políticas de RLS) y las RPC del panel, que lo comprueban dentro.
grant execute on function public.is_admin() to authenticated;
grant execute on function public.config_diff(bigint) to authenticated;
grant execute on function public.publish_config(bigint) to authenticated;
grant execute on function public.rollback_config(integer) to authenticated;
grant execute on function public.admin_summary() to authenticated;
grant execute on function public.admin_characters(text, integer, integer) to authenticated;
grant execute on function public.admin_character(uuid) to authenticated;
