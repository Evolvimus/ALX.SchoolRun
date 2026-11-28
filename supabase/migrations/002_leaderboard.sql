-- ALX SchoolRun: globale Rangliste (für alle, nicht nach Stufen getrennt) und Tagesrangliste.
-- Namen sind zufällig erzeugt („Flinker Bücherwurm 42“), freie Namen werden abgelehnt.

create table if not exists public.scores (
  player     uuid not null,
  name       text not null,
  level      text not null,
  best_time  real not null,
  points     integer not null,
  updated_at timestamptz not null default now(),
  primary key (player, level)
);

create table if not exists public.daily_scores (
  day        date not null,
  player     uuid not null,
  name       text not null,
  best_time  real not null,
  level      text not null,
  updated_at timestamptz not null default now(),
  primary key (day, player)
);

create index if not exists scores_level_time on public.scores(level, best_time);
create index if not exists daily_day_time on public.daily_scores(day, best_time);

alter table public.scores enable row level security;
alter table public.daily_scores enable row level security;

-- Nur Namen im Format „Adjektiv Nomen 12“ (so erzeugt sie das Spiel)
create or replace function public._valid_name(p_name text)
returns boolean language sql immutable as $$
  select p_name ~ '^[A-ZÄÖÜ][a-zäöüß]+ [A-ZÄÖÜ][A-Za-zäöüß]+ [0-9]{2}$' and length(p_name) <= 40;
$$;

-- Ergebnis eines Levels melden. Gespeichert wird je Spieler und Level das Beste.
create or replace function public.submit_score(p_player uuid, p_name text, p_level text, p_time real, p_points integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not _valid_name(p_name) then raise exception 'NAME_INVALID'; end if;
  if p_time < 5 or p_time > 3600 or p_points < 0 or p_points > 5000 then raise exception 'SCORE_INVALID'; end if;
  insert into scores(player, name, level, best_time, points) values (p_player, p_name, p_level, p_time, p_points)
  on conflict (player, level) do update set
    name = excluded.name,
    best_time = least(scores.best_time, excluded.best_time),
    points = greatest(scores.points, excluded.points),
    updated_at = now();
  update scores set name = p_name where player = p_player;  -- Namenswechsel überall übernehmen
end $$;

create or replace function public.submit_daily(p_player uuid, p_name text, p_day date, p_level text, p_time real)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not _valid_name(p_name) then raise exception 'NAME_INVALID'; end if;
  if p_time < 5 or p_time > 3600 then raise exception 'SCORE_INVALID'; end if;
  if abs(p_day - current_date) > 1 then raise exception 'DAY_INVALID'; end if;
  insert into daily_scores(day, player, name, best_time, level) values (p_day, p_player, p_name, p_time, p_level)
  on conflict (day, player) do update set best_time = least(daily_scores.best_time, excluded.best_time), name = excluded.name, updated_at = now();
end $$;

-- Ranglisten: kind = 'total' (Punkte aller Level), 'level' (Bestzeit eines Levels), 'daily' (Bestzeit des Tages).
-- Liefert die Top p_limit und – falls nicht darunter – die eigene Zeile. Felder: rank, name, value, me
create or replace function public.leaderboard(p_kind text, p_key text, p_player uuid, p_limit integer default 10)
returns table(rank bigint, name text, value real, me boolean) language sql security definer set search_path = public as $$
  with board as (
    select player, max(name) as name, sum(points)::real as value, rank() over (order by sum(points) desc) as rank
      from scores where p_kind = 'total' group by player
    union all
    select player, name, best_time, rank() over (order by best_time asc)
      from scores where p_kind = 'level' and level = p_key
    union all
    select player, name, best_time, rank() over (order by best_time asc)
      from daily_scores where p_kind = 'daily' and day = p_key::date
  )
  select rank, name, value, player = p_player from board
   where rank <= least(p_limit, 50) or player = p_player
   order by rank, name;
$$;

revoke all on function public.submit_score(uuid, text, text, real, integer) from public;
revoke all on function public.submit_daily(uuid, text, date, text, real) from public;
revoke all on function public.leaderboard(text, text, uuid, integer) from public;
grant execute on function public.submit_score(uuid, text, text, real, integer) to anon;
grant execute on function public.submit_daily(uuid, text, date, text, real) to anon;
grant execute on function public.leaderboard(text, text, uuid, integer) to anon;
