-- ALX SchoolRun: einmalig einlösbare Sammelkarten-Codes
create extension if not exists pgcrypto;

create table if not exists public.codes (
  code_hash    text primary key,          -- sha256 des Codes, Klartext liegt NICHT in der DB
  character_id text not null,
  redeemed_by  uuid,
  redeemed_at  timestamptz
);

create table if not exists public.settings (
  key   text primary key,
  value jsonb not null
);
insert into public.settings(key, value) values ('shop_open', 'false') on conflict do nothing;

-- Kein direkter Tabellenzugriff von außen, nur über die Funktionen unten
alter table public.codes enable row level security;
alter table public.settings enable row level security;

create or replace function public.redeem_code(p_code text, p_player uuid)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_hash text := encode(digest(upper(p_code), 'sha256'), 'hex');
  v_char text;
  v_by   uuid;
begin
  update codes set redeemed_by = p_player, redeemed_at = now()
   where code_hash = v_hash and redeemed_by is null
   returning character_id into v_char;
  if v_char is not null then return v_char; end if;

  select character_id, redeemed_by into v_char, v_by from codes where code_hash = v_hash;
  if v_char is null then raise exception 'CODE_INVALID'; end if;
  if v_by = p_player then return v_char; end if;   -- eigener Code erneut eingegeben: ok
  raise exception 'CODE_USED';
end $$;

create or replace function public.my_unlocks(p_player uuid)
returns setof text language sql security definer set search_path = public as $$
  select character_id from codes where redeemed_by = p_player;
$$;

create or replace function public.shop_open()
returns boolean language sql security definer set search_path = public as $$
  select coalesce((select value::boolean from settings where key = 'shop_open'), false);
$$;

revoke all on function public.redeem_code(text, uuid) from public;
revoke all on function public.my_unlocks(uuid) from public;
revoke all on function public.shop_open() from public;
grant execute on function public.redeem_code(text, uuid) to anon;
grant execute on function public.my_unlocks(uuid) to anon;
grant execute on function public.shop_open() to anon;

-- Shop nach der Kartenaktion öffnen:
--   update public.settings set value = 'true' where key = 'shop_open';
