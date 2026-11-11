create extension if not exists pgcrypto with schema extensions;

drop view  if exists public.em_analise, public.aprovados, public.recusados;
drop table if exists public.decisoes cascade;
drop table if exists public.relatos  cascade;
drop table if exists public.limites  cascade;
drop table if exists public.gestores cascade;
drop table if exists public.usuarios cascade;

create table public.usuarios (
  autor_id    text primary key,
  email       text not null unique,
  chave_hash  text,
  criado_em   timestamptz not null default now()
);

create table public.relatos (
  id            text primary key,
  autor_id      text not null references public.usuarios (autor_id) on delete cascade,
  categoria     text not null check (categoria in
                  ('lixoAcumulado', 'entulho', 'onibusLotado', 'semaforo', 'alagamento', 'outro')),
  bairro        text not null check (char_length(bairro) between 2 and 60),
  descricao     text not null check (char_length(descricao) between 20 and 300),
  urgencia      text not null check (urgencia in ('baixa', 'media', 'alta')),
  observado_em  timestamptz not null,
  criado_em     timestamptz not null default now()
);
create index relatos_autor_idx on public.relatos (autor_id);

create table public.gestores (
  email     text primary key,
  pin_hash  text not null
);

create table public.decisoes (
  alerta_id      text primary key,
  decisao        text not null check (decisao in ('em_analise', 'aprovado', 'recusado')),
  nota           text not null default '' check (char_length(nota) <= 200),
  decidido_em    timestamptz not null default now(),
  gestor_id      text references public.usuarios (autor_id) on delete set null,
  titulo_alerta  text not null,
  indicador      text not null
);

create table public.limites (
  id             int primary key default 1 check (id = 1),
  sensacao_c     numeric not null check (sensacao_c between 30 and 50),
  uv             numeric not null check (uv between 3 and 15),
  chuva_mm       numeric not null check (chuva_mm between 10 and 200),
  escore_z       numeric not null check (escore_z between 1.5 and 4),
  atualizado_em  timestamptz not null default now(),
  gestor_id      text references public.usuarios (autor_id) on delete set null
);
insert into public.limites (sensacao_c, uv, chuva_mm, escore_z) values (33, 11, 40, 2);

create view public.em_analise with (security_invoker = true) as
  select d.alerta_id, d.titulo_alerta, d.indicador, d.nota, u.email as gestor, d.decidido_em
  from public.decisoes d left join public.usuarios u on u.autor_id = d.gestor_id
  where d.decisao = 'em_analise'
  order by d.decidido_em desc;

create view public.aprovados with (security_invoker = true) as
  select d.alerta_id, d.titulo_alerta, d.indicador, d.nota, u.email as gestor, d.decidido_em
  from public.decisoes d left join public.usuarios u on u.autor_id = d.gestor_id
  where d.decisao = 'aprovado'
  order by d.decidido_em desc;

create view public.recusados with (security_invoker = true) as
  select d.alerta_id, d.titulo_alerta, d.indicador, d.nota, u.email as gestor, d.decidido_em
  from public.decisoes d left join public.usuarios u on u.autor_id = d.gestor_id
  where d.decisao = 'recusado'
  order by d.decidido_em desc;

alter table public.usuarios enable row level security;
alter table public.relatos  enable row level security;
alter table public.gestores enable row level security;
alter table public.decisoes enable row level security;
alter table public.limites  enable row level security;

revoke all on public.usuarios, public.relatos, public.gestores, public.decisoes, public.limites
  from anon, authenticated;
revoke all on public.em_analise, public.aprovados, public.recusados from anon, authenticated;

create or replace function public._autor(p_email text) returns text
language sql immutable set search_path = '' as $$
  select encode(extensions.digest(lower(trim(p_email)), 'sha256'), 'hex')
$$;

create or replace function public._email_valido(p_email text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(p_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(p_email) <= 254, false)
$$;

create or replace function public._garantir_usuario(p_email text) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_autor text := public._autor(p_email);
begin
  if not public._email_valido(p_email) then
    raise exception 'email_invalido' using errcode = '22023';
  end if;
  insert into public.usuarios (autor_id, email)
  values (v_autor, lower(trim(p_email)))
  on conflict (autor_id) do nothing;
  return v_autor;
end $$;

create or replace function public._e_titular(p_email text, p_chave text) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((
    select u.chave_hash = extensions.crypt(p_chave, u.chave_hash)
    from public.usuarios u
    where u.autor_id = public._autor(p_email) and u.chave_hash is not null
  ), false)
$$;

create or replace function public._e_gestor(p_email text, p_pin text) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((
    select g.pin_hash = extensions.crypt(p_pin, g.pin_hash)
    from public.gestores g
    where g.email = lower(trim(p_email))
  ), false)
$$;

create or replace function public.entrar(p_email text, p_chave text) returns json
language plpgsql security definer set search_path = '' as $$
declare
  v_autor text;
begin
  if p_chave is null or char_length(p_chave) < 16 then
    raise exception 'chave_invalida' using errcode = '22023';
  end if;
  v_autor := public._garantir_usuario(p_email);
  update public.usuarios
     set chave_hash = extensions.crypt(p_chave, extensions.gen_salt('bf'))
   where autor_id = v_autor and chave_hash is null;
  return json_build_object(
    'titular', public._e_titular(p_email, p_chave),
    'gestor', exists (select 1 from public.gestores g where g.email = lower(trim(p_email)))
  );
end $$;

create or replace function public.listar_relatos(p_email text default null)
returns table (
  id text, categoria text, bairro text, descricao text, urgencia text,
  observado_em timestamptz, criado_em timestamptz, meu boolean
)
language sql stable security definer set search_path = '' as $$
  select r.id, r.categoria, r.bairro, r.descricao, r.urgencia, r.observado_em, r.criado_em,
         (p_email is not null and r.autor_id = public._autor(p_email)) as meu
  from public.relatos r
  order by r.criado_em desc
  limit 500
$$;

create or replace function public.registrar_relato(
  p_email text, p_id text, p_categoria text, p_bairro text, p_descricao text,
  p_urgencia text, p_observado_em timestamptz, p_criado_em timestamptz
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_autor text;
begin
  v_autor := public._garantir_usuario(p_email);
  if p_observado_em > now() + interval '1 day' or p_observado_em < now() - interval '30 days' then
    raise exception 'data_invalida' using errcode = '22023';
  end if;
  insert into public.relatos
    (id, autor_id, categoria, bairro, descricao, urgencia, observado_em, criado_em)
  values
    (p_id, v_autor, p_categoria, p_bairro, p_descricao, p_urgencia, p_observado_em,
     least(coalesce(p_criado_em, now()), now()))
  on conflict (id) do nothing;
end $$;

create or replace function public.apagar_meus_dados(p_email text, p_chave text) returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_autor text := public._autor(p_email);
  v_qtd integer;
begin
  if not public._e_titular(p_email, p_chave) then
    raise exception 'nao_autorizado' using errcode = '42501';
  end if;
  select count(*) into v_qtd from public.relatos where autor_id = v_autor;
  delete from public.usuarios where autor_id = v_autor;
  return v_qtd;
end $$;

create or replace function public.listar_decisoes(p_email text default null)
returns table (
  alerta_id text, decisao text, nota text, decidido_em timestamptz,
  titulo_alerta text, indicador text, minha boolean
)
language sql stable security definer set search_path = '' as $$
  select d.alerta_id, d.decisao, d.nota, d.decidido_em, d.titulo_alerta, d.indicador,
         (p_email is not null and d.gestor_id = public._autor(p_email)) as minha
  from public.decisoes d
  order by d.decidido_em desc
$$;

create or replace function public.validar_gestor(p_email text, p_pin text) returns boolean
language sql stable security definer set search_path = '' as $$
  select public._e_gestor(p_email, p_pin)
$$;

create or replace function public.decidir(
  p_email text, p_pin text, p_alerta_id text, p_decisao text, p_nota text,
  p_decidido_em timestamptz, p_titulo text, p_indicador text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_autor text;
  v_quando timestamptz := least(coalesce(p_decidido_em, now()), now());
begin
  if not public._e_gestor(p_email, p_pin) then
    raise exception 'nao_autorizado' using errcode = '42501';
  end if;
  v_autor := public._garantir_usuario(p_email);
  insert into public.decisoes
    (alerta_id, decisao, nota, decidido_em, gestor_id, titulo_alerta, indicador)
  values
    (p_alerta_id, p_decisao, coalesce(p_nota, ''), v_quando, v_autor, p_titulo, p_indicador)
  on conflict (alerta_id) do update
    set decisao = excluded.decisao,
        nota = excluded.nota,
        decidido_em = excluded.decidido_em,
        gestor_id = excluded.gestor_id,
        titulo_alerta = excluded.titulo_alerta,
        indicador = excluded.indicador
    where public.decisoes.decidido_em <= excluded.decidido_em;
end $$;

create or replace function public.ler_limites() returns json
language sql stable security definer set search_path = '' as $$
  select json_build_object(
    'sensacaoC', l.sensacao_c, 'uv', l.uv, 'chuvaMm', l.chuva_mm,
    'escoreZ', l.escore_z, 'atualizadoEm', l.atualizado_em
  )
  from public.limites l
  where l.id = 1
$$;

create or replace function public.salvar_limites(
  p_email text, p_pin text, p_sensacao_c numeric, p_uv numeric, p_chuva_mm numeric, p_escore_z numeric
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public._e_gestor(p_email, p_pin) then
    raise exception 'nao_autorizado' using errcode = '42501';
  end if;
  update public.limites
     set sensacao_c = p_sensacao_c, uv = p_uv, chuva_mm = p_chuva_mm, escore_z = p_escore_z,
         atualizado_em = now(), gestor_id = public._garantir_usuario(p_email)
   where id = 1;
end $$;

revoke execute on function
  public._autor(text), public._email_valido(text), public._garantir_usuario(text),
  public._e_titular(text, text), public._e_gestor(text, text)
  from public, anon, authenticated;

grant execute on function
  public.entrar(text, text),
  public.listar_relatos(text),
  public.registrar_relato(text, text, text, text, text, text, timestamptz, timestamptz),
  public.apagar_meus_dados(text, text),
  public.listar_decisoes(text),
  public.validar_gestor(text, text),
  public.decidir(text, text, text, text, text, timestamptz, text, text),
  public.ler_limites(),
  public.salvar_limites(text, text, numeric, numeric, numeric, numeric)
  to anon, authenticated;

notify pgrst, 'reload schema';
