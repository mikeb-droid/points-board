-- Peyton's Points Board — database setup
-- Paste this whole file into Supabase > SQL Editor > New query, then click Run.
-- Safe to run once on a fresh project.

-- ---------- Family members (who can sign in, and as what) ----------
create table if not exists members (
  user_id uuid primary key references auth.users on delete cascade,
  role    text not null check (role in ('parent','kid')),
  name    text not null default ''
);

create or replace function is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members where user_id = auth.uid());
$$;

create or replace function is_parent() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members where user_id = auth.uid() and role = 'parent');
$$;

-- ---------- Board data ----------
create table if not exists settings (
  id        int primary key default 1 check (id = 1),
  kid_name  text not null default 'Peyton'
);
insert into settings (id) values (1) on conflict do nothing;

create table if not exists tasks (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  points      int  not null check (points > 0),
  category    text not null default 'Other',
  days        int[] not null default '{}',     -- 0=Sun … 6=Sat
  once        date,                            -- set for one-time tasks
  start_date  date not null default current_date,
  active      boolean not null default true,   -- false = paused
  archived    boolean not null default false,  -- removed from lists, past points kept
  sort        int not null default 99,
  created_at  timestamptz not null default now()
);

create table if not exists rewards (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  target       int  not null check (target > 0),
  period_type  text not null check (period_type in ('week','month','goal')),
  start_date   date,                           -- big goals only
  end_date     date,                           -- big goals only, optional
  active       boolean not null default true,
  archived     boolean not null default false,
  created_at   timestamptz not null default now()
);

create table if not exists completions (
  day              date not null,
  task_id          uuid not null references tasks on delete cascade,
  done             boolean not null default false,  -- Peyton checked it off
  approved_points  int,                             -- set only by a parent
  updated_at       timestamptz not null default now(),
  primary key (day, task_id)
);

create table if not exists bonus (
  id          uuid primary key default gen_random_uuid(),
  day         date not null default current_date,
  points      int  not null check (points <> 0),
  note        text not null default '',
  created_at  timestamptz not null default now()
);

create table if not exists claims (
  reward_id  uuid not null references rewards on delete cascade,
  period     text not null,                 -- e.g. w2026-11-02, m2026-11, g2026-11-05
  given_on   date not null default current_date,
  primary key (reward_id, period)
);

-- A kid can check things off, but can never approve or change points.
create or replace function guard_completion() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not is_parent() then
    if tg_op = 'INSERT' then
      new.approved_points := null;
    else
      new.approved_points := old.approved_points;
      if old.approved_points is not null then
        new.done := old.done;   -- can't un-check something already approved
      end if;
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists completions_guard on completions;
create trigger completions_guard before insert or update on completions
  for each row execute function guard_completion();

-- ---------- Row security ----------
alter table members     enable row level security;
alter table settings    enable row level security;
alter table tasks       enable row level security;
alter table rewards     enable row level security;
alter table completions enable row level security;
alter table bonus       enable row level security;
alter table claims      enable row level security;

create policy "family reads members"   on members     for select using (is_member());

create policy "family reads settings"  on settings    for select using (is_member());
create policy "parents edit settings"  on settings    for all    using (is_parent()) with check (is_parent());

create policy "family reads tasks"     on tasks       for select using (is_member());
create policy "parents edit tasks"     on tasks       for all    using (is_parent()) with check (is_parent());

create policy "family reads rewards"   on rewards     for select using (is_member());
create policy "parents edit rewards"   on rewards     for all    using (is_parent()) with check (is_parent());

create policy "family reads bonus"     on bonus       for select using (is_member());
create policy "parents edit bonus"     on bonus       for all    using (is_parent()) with check (is_parent());

create policy "family reads claims"    on claims      for select using (is_member());
create policy "parents edit claims"    on claims      for all    using (is_parent()) with check (is_parent());

create policy "family reads completions"   on completions for select using (is_member());
create policy "family adds completions"    on completions for insert with check (is_member());
create policy "family updates completions" on completions for update using (is_member()) with check (is_member());
create policy "parents delete completions" on completions for delete using (is_parent());

-- ---------- Live updates across phones ----------
alter publication supabase_realtime add table settings, tasks, rewards, completions, bonus, claims;

-- ---------- Starter tasks and prizes (edit or remove in the app) ----------
insert into tasks (title, points, category, days, start_date, sort) values
  ('Homework done and shown to a parent', 10, 'Homework', '{1,2,3,4,5}',     current_date, 1),
  ('Backpack packed for tomorrow',         3, 'Homework', '{0,1,2,3,4}',     current_date, 2),
  ('Read for 20 minutes',                  5, 'Reading',  '{0,1,2,3,4,5,6}', current_date, 3),
  ('Make bed',                             2, 'Chores',   '{0,1,2,3,4,5,6}', current_date, 4),
  ('Clear and rinse dinner dishes',        4, 'Chores',   '{0,1,2,3,4,5,6}', current_date, 5),
  ('Clean bedroom',                       10, 'Chores',   '{6}',             current_date, 6);

insert into rewards (title, target, period_type, start_date) values
  ('Pick the weekend family movie and snack', 100, 'week',  null),
  ('Month-end outing of her choice',          400, 'month', null),
  ('Big goal prize (you pick!)',             1200, 'goal',  current_date);
