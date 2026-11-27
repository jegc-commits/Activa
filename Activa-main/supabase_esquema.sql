-- ===================================================================
-- ACTIVA · Esquema para Supabase (PostgreSQL)
-- Ejecutar en: Supabase Dashboard -> SQL Editor -> New query -> Run
--
-- Diseño: la tabla `usuarios` es la ÚNICA fuente de personas
-- (alumnos, instructores y administradores) e incluye las credenciales
-- (sal + hash). Ya NO se usan las tablas `alumnos` ni `instructores`.
--
-- El script es idempotente: crea lo que falta, agrega columnas nuevas y
-- siembra el catálogo solo si está vacío. No borra datos existentes.
-- ===================================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------------
-- Catálogo
-- ------------------------------------------------------------------
create table if not exists public.categorias (
  id          serial primary key,
  clave       text not null unique,
  nombre      text not null,
  etiqueta    text not null,
  color       bigint not null,
  icono       text not null,
  activa      boolean not null default true
);

create table if not exists public.especialidades_alumno (
  id     serial primary key,
  nombre text not null unique
);

-- ------------------------------------------------------------------
-- Personas + credenciales (alumnos, instructores y admin)
-- ------------------------------------------------------------------
create table if not exists public.usuarios (
  id                      serial primary key,
  rol                     text not null check (rol in ('alumno','instructor','admin')),
  usuario                 text not null unique,
  correo                  text not null default '',
  nombre                  text not null default '',
  apellido_paterno        text not null default '',
  apellido_materno        text not null default '',
  telefono                text not null default '',
  especialidad            text not null default '',
  numero_control          text not null default '',
  grupo                   text not null default '',
  carrera                 text not null default '',
  activo                  boolean not null default true,
  debe_cambiar_contrasena boolean not null default false,
  sal                     text not null default '',
  hash                    text not null default ''
);

-- Por si la tabla ya existía con un esquema viejo:
alter table public.usuarios add column if not exists rol text not null default 'alumno';
alter table public.usuarios add column if not exists usuario text not null default '';
alter table public.usuarios add column if not exists correo text not null default '';
alter table public.usuarios add column if not exists nombre text not null default '';
alter table public.usuarios add column if not exists apellido_paterno text not null default '';
alter table public.usuarios add column if not exists apellido_materno text not null default '';
alter table public.usuarios add column if not exists telefono text not null default '';
alter table public.usuarios add column if not exists especialidad text not null default '';
alter table public.usuarios add column if not exists numero_control text not null default '';
alter table public.usuarios add column if not exists grupo text not null default '';
alter table public.usuarios add column if not exists carrera text not null default '';
alter table public.usuarios add column if not exists activo boolean not null default true;
alter table public.usuarios add column if not exists debe_cambiar_contrasena boolean not null default false;
alter table public.usuarios add column if not exists sal text not null default '';
alter table public.usuarios add column if not exists hash text not null default '';

create index if not exists usuarios_correo_idx on public.usuarios (lower(correo));
create index if not exists usuarios_control_idx on public.usuarios (numero_control);
create index if not exists usuarios_rol_idx on public.usuarios (rol);

-- Un correo y un número de control no deben repetirse. Se crean de forma
-- tolerante: si ya hay datos duplicados, se avisa pero no se detiene el script.
do $$
begin
  begin
    create unique index if not exists usuarios_correo_unico_idx
      on public.usuarios (lower(correo)) where correo <> '';
  exception when others then
    raise notice 'No se creó el índice único de correo: %', sqlerrm;
  end;
  begin
    create unique index if not exists usuarios_control_unico_idx
      on public.usuarios (numero_control) where numero_control <> '';
  exception when others then
    raise notice 'No se creó el índice único de número de control: %', sqlerrm;
  end;
  begin
    create unique index if not exists usuarios_usuario_unico_idx
      on public.usuarios (lower(usuario)) where usuario <> '';
  exception when others then
    raise notice 'No se creó el índice único de usuario: %', sqlerrm;
  end;
end $$;

-- ------------------------------------------------------------------
-- Talleres
-- ------------------------------------------------------------------
create table if not exists public.talleres (
  id            serial primary key,
  nombre        text not null,
  descripcion   text not null default '',
  categoria_id  integer not null references public.categorias(id),
  lugar         text not null default '',
  cupo_maximo   integer not null,
  horas_otorga  integer not null default 60,
  activo        boolean not null default true,
  instructor_id integer not null references public.usuarios(id),
  inscritos     integer not null default 0,
  foto          bytea
);

create table if not exists public.horarios (
  id          serial primary key,
  taller_id   integer not null references public.talleres(id) on delete cascade,
  dia         integer not null,
  hora_inicio text not null,
  hora_fin    text not null,
  orden       integer not null default 0
);

create table if not exists public.aprendizajes (
  id        serial primary key,
  taller_id integer not null references public.talleres(id) on delete cascade,
  texto     text not null,
  orden     integer not null default 0
);

create index if not exists horarios_taller_idx on public.horarios (taller_id);
create index if not exists aprendizajes_taller_idx on public.aprendizajes (taller_id);

-- ------------------------------------------------------------------
-- Inscripciones y asistencia
-- ------------------------------------------------------------------
create table if not exists public.inscripciones (
  folio      text primary key,
  alumno_id  integer not null references public.usuarios(id) on delete cascade,
  taller_id  integer not null references public.talleres(id) on delete cascade,
  estado     text not null default 'activa',
  fecha      text not null,
  horas      integer not null default 0
);

create index if not exists inscripciones_alumno_idx on public.inscripciones (alumno_id);
create index if not exists inscripciones_taller_idx on public.inscripciones (taller_id);

create table if not exists public.asistencias (
  taller_id       integer not null references public.talleres(id) on delete cascade,
  fecha           text not null,
  numero_control  text not null,
  presente        boolean not null default false,
  primary key (taller_id, fecha, numero_control)
);

create table if not exists public.roster (
  taller_id integer not null references public.talleres(id) on delete cascade,
  alumno_id integer not null references public.usuarios(id) on delete cascade,
  primary key (taller_id, alumno_id)
);

-- ------------------------------------------------------------------
-- Avisos y chats
-- ------------------------------------------------------------------
create table if not exists public.avisos (
  id        serial primary key,
  taller_id integer references public.talleres(id) on delete cascade,
  tipo      text not null,
  titulo    text not null,
  mensaje   text not null default '',
  fecha     text not null,
  leido     boolean not null default false,
  archivado boolean not null default false
);

create table if not exists public.mensajes (
  id        serial primary key,
  taller_id integer not null references public.talleres(id) on delete cascade,
  rol       text not null,
  autor     text not null,
  texto     text not null,
  fecha     text not null
);

create index if not exists mensajes_taller_idx on public.mensajes (taller_id);

create table if not exists public.chats_estado (
  taller_id integer primary key references public.talleres(id) on delete cascade,
  anclado   boolean not null default false,
  fondo     integer not null default 0
);

-- ------------------------------------------------------------------
-- Encuestas, solicitudes y preferencias
-- ------------------------------------------------------------------
create table if not exists public.encuestas (
  id               serial primary key,
  taller_id        integer not null references public.talleres(id) on delete cascade,
  numero_control   text not null,
  calif_club       integer not null,
  calif_instructor integer not null,
  comentario       text not null default '',
  fecha            text not null
);

create table if not exists public.solicitudes (
  id                serial primary key,
  taller_id         integer not null references public.talleres(id) on delete cascade,
  instructor_id     integer not null references public.usuarios(id) on delete cascade,
  instructor_nombre text not null,
  tipo              text not null,
  mensaje           text not null default '',
  fecha             text not null,
  estado            text not null default 'pendiente',
  respuesta         text not null default '',
  cupo_extra        integer not null default 0
);

create table if not exists public.favoritos (
  taller_id integer primary key references public.talleres(id) on delete cascade
);

create table if not exists public.bajas (
  taller_id integer primary key references public.talleres(id) on delete cascade,
  total     integer not null default 0
);

create table if not exists public.horas_validadas (
  numero_control text primary key,
  fecha          text not null
);

create table if not exists public.reportes (
  id     serial primary key,
  tipo   text not null,
  formato text not null,
  fecha  text not null
);

create table if not exists public.contadores (
  clave text primary key,
  valor integer not null
);

-- ------------------------------------------------------------------
-- Semilla (solo inserta si no existe)
-- ------------------------------------------------------------------
insert into public.categorias (id, clave, nombre, etiqueta, color, icono, activa) values
  (1, 'deportes',   'Deportes',   'Deportiva',  4292905532, 'deportes',   true),
  (2, 'cultura',    'Cultura',    'Cultural',   4291904891, 'cultura',    true),
  (3, 'recreativa', 'Recreativa', 'Recreativa', 4285288401, 'recreativa', true),
  (4, 'otros',      'Otros',      'Otra',       4282158560, 'otros',      true)
on conflict (id) do nothing;

insert into public.especialidades_alumno (nombre) values
  ('Administración de Recursos Humanos'),
  ('Contabilidad'),
  ('Electricidad'),
  ('Logística'),
  ('Mecánica Industrial'),
  ('Programación'),
  ('Soporte y Mantenimiento de Equipo de Cómputo')
on conflict (nombre) do nothing;

-- Administrador inicial: admin / Activa2026!
-- sal + SHA-256("sal:contraseña") generados con la misma lógica de la app.
insert into public.usuarios
  (rol, usuario, correo, nombre, apellido_paterno, apellido_materno,
   telefono, especialidad, numero_control, grupo, carrera,
   activo, debe_cambiar_contrasena, sal, hash)
values
  ('admin', 'admin', 'admin@utng.edu.mx', 'Coordinación', 'de Paraescolares', '',
   '', '', '', '', '',
   true, false,
   'gwmeSN43ukKxvMrrVubNGg',
   '0689dc2433d909d015500d44ca87c8c9793002603290955437020ec171d1e7ff')
on conflict (usuario) do nothing;

insert into public.contadores (clave, valor) values
  ('folio', 1),
  ('usuario', 2)
on conflict (clave) do nothing;

-- ------------------------------------------------------------------
-- Seguridad (RLS)
-- La app usa la publishable/anon key directamente desde el cliente.
-- Estas políticas permiten leer/escribir con esa clave.
-- ⚠️ Para producción real conviene migrar a Supabase Auth y políticas
--    por usuario. Para el proyecto escolar esto deja la app funcional.
-- ------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'categorias','especialidades_alumno','usuarios','talleres','horarios',
    'aprendizajes','inscripciones','asistencias','roster','avisos','mensajes',
    'chats_estado','encuestas','solicitudes','favoritos','bajas',
    'horas_validadas','reportes','contadores'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists activa_acceso_total on public.%I', t);
    execute format(
      'create policy activa_acceso_total on public.%I for all to anon, authenticated using (true) with check (true)',
      t
    );
  end loop;
end $$;

grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;

-- ------------------------------------------------------------------
-- Limpieza opcional de tablas viejas (ejecutar solo si quieres
-- eliminar la duplicación alumnos/instructores y sus datos):
--
-- drop table if exists public.alumnos cascade;
-- drop table if exists public.instructores cascade;
-- ------------------------------------------------------------------
