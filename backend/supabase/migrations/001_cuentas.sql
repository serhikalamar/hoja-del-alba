-- 001_cuentas.sql — Cuentas de jugador y personajes guardados en la nube.
--
-- Se ejecuta una vez en el SQL Editor de Supabase (ver backend/README.md).
-- Se puede volver a ejecutar sin romper nada: usa "if not exists" / "or replace" / "drop ... if exists".
--
-- Modelo:
--   auth.users          (lo gestiona Supabase Auth: email sintético + contraseña)
--   public.profiles     1 fila por usuario: el nombre de usuario (único)
--   public.characters   1 fila por personaje: el PlayerProfile en JSON (máx. 8 por cuenta)
-- Seguridad: RLS en todas las tablas; cada usuario solo ve y toca lo suyo. El rol anon no tiene acceso.

-- ---------------------------------------------------------------------------
-- Perfiles (nombre de usuario)
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
    id          uuid primary key references auth.users (id) on delete cascade,
    username    text not null,
    created_at  timestamptz not null default now(),
    -- Las mismas reglas que AccountRules.usernameProblem en GameCore: 3-20 caracteres a-z, 0-9 y _ (en minúsculas).
    constraint profiles_username_formato check (username ~ '^[a-z0-9_]{3,20}$'),
    constraint profiles_username_unico unique (username)
);

comment on table public.profiles is 'Nombre de usuario de cada cuenta (se crea solo al registrarse).';

-- Al registrarse (POST /auth/v1/signup con data.username), se crea su perfil.
-- Si el nombre no es válido o ya existe, el registro entero falla (no quedan cuentas a medias).
create or replace function public.crear_perfil_de_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.profiles (id, username)
    values (
        new.id,
        lower(coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)))
    );
    return new;
end;
$$;

drop trigger if exists al_crear_usuario on auth.users;
create trigger al_crear_usuario
    after insert on auth.users
    for each row execute function public.crear_perfil_de_usuario();

-- ---------------------------------------------------------------------------
-- Personajes
-- ---------------------------------------------------------------------------

create table if not exists public.characters (
    -- El mismo UUID que PlayerProfile.characterID.
    id          uuid primary key,
    owner       uuid not null default auth.uid() references auth.users (id) on delete cascade,
    name        text not null,
    -- PlayerProfile completo tal cual lo codifica la app (JSONEncoder).
    data        jsonb not null,
    -- Sube en 1 en cada escritura (trigger). La app la usa para no pisar cambios de otro dispositivo.
    version     integer not null default 1,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    constraint characters_nombre check (char_length(name) between 1 and 32),
    constraint characters_data_objeto check (jsonb_typeof(data) = 'object'),
    constraint characters_data_tamano check (pg_column_size(data) <= 1048576)  -- 1 MB por personaje
);

comment on table public.characters is 'Personajes de cada cuenta (PlayerProfile en JSON).';

create index if not exists characters_owner_idx on public.characters (owner, updated_at desc);

-- Versión, fechas y dueño los pone el servidor, no la app.
-- (Sin security definer: la cuenta de personajes respeta RLS y solo ve los del propio usuario.)
create or replace function public.characters_antes_de_guardar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if tg_op = 'INSERT' then
        if (select count(*) from public.characters c where c.owner = new.owner) >= 8 then
            raise exception 'Máximo 8 personajes por cuenta' using errcode = 'P0001', hint = 'limite_personajes';
        end if;
        new.version := 1;
        new.created_at := now();
        new.updated_at := now();
    else
        new.id := old.id;
        new.owner := old.owner;
        new.created_at := old.created_at;
        new.version := old.version + 1;
        new.updated_at := now();
    end if;
    return new;
end;
$$;

drop trigger if exists characters_antes_de_guardar on public.characters;
create trigger characters_antes_de_guardar
    before insert or update on public.characters
    for each row execute function public.characters_antes_de_guardar();

-- ---------------------------------------------------------------------------
-- Seguridad (RLS y permisos)
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.characters enable row level security;

-- Sin sesión (rol anon) no se puede leer ni escribir nada.
revoke all on public.profiles from anon;
revoke all on public.characters from anon;

-- Perfiles: cada usuario lee el suyo. Se crean solo con el trigger; no se editan desde la app.
revoke insert, update, delete on public.profiles from authenticated;
grant select on public.profiles to authenticated;

drop policy if exists "perfiles: leer el propio" on public.profiles;
create policy "perfiles: leer el propio"
    on public.profiles for select to authenticated
    using ((select auth.uid()) = id);

-- Personajes: cada usuario lee, crea, cambia y borra solo los suyos.
grant select, insert, update, delete on public.characters to authenticated;

drop policy if exists "personajes: leer los propios" on public.characters;
create policy "personajes: leer los propios"
    on public.characters for select to authenticated
    using ((select auth.uid()) = owner);

drop policy if exists "personajes: crear los propios" on public.characters;
create policy "personajes: crear los propios"
    on public.characters for insert to authenticated
    with check ((select auth.uid()) = owner);

drop policy if exists "personajes: cambiar los propios" on public.characters;
create policy "personajes: cambiar los propios"
    on public.characters for update to authenticated
    using ((select auth.uid()) = owner)
    with check ((select auth.uid()) = owner);

drop policy if exists "personajes: borrar los propios" on public.characters;
create policy "personajes: borrar los propios"
    on public.characters for delete to authenticated
    using ((select auth.uid()) = owner);

-- La función del trigger de registro es "security definer": que nadie pueda llamarla por la API.
revoke execute on function public.crear_perfil_de_usuario() from public, anon, authenticated;
