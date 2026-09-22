-- ============================================================================
-- Planner — Supabase schema (Postgres)
-- Run this once in the Supabase SQL editor (or via `supabase db push`) for a
-- fresh project. Safe to re-run: guarded with IF NOT EXISTS / OR REPLACE.
-- ============================================================================

create extension if not exists "pgcrypto"; -- for gen_random_uuid()

-- ----------------------------------------------------------------------------
-- 1. profiles — one row per authenticated user
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by owner" on public.profiles;
create policy "Profiles are viewable by owner"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Profiles are updatable by owner" on public.profiles;
create policy "Profiles are updatable by owner"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up (e.g. via Google).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.email,
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 2. tasks
-- ----------------------------------------------------------------------------
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'General',
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  status text not null default 'todo' check (status in ('todo', 'in_progress', 'completed')),
  due_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tasks_user_id_idx on public.tasks (user_id);
create index if not exists tasks_due_date_idx on public.tasks (due_date);

alter table public.tasks enable row level security;

drop policy if exists "Tasks are fully managed by owner" on public.tasks;
create policy "Tasks are fully managed by owner"
  on public.tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. habits
-- ----------------------------------------------------------------------------
create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  icon text not null default 'star',
  color text not null default '#6C5CE7',
  frequency text not null default 'daily' check (frequency in ('daily', 'weekly', 'custom')),
  target_per_period int not null default 1,
  created_at timestamptz not null default now()
);

create index if not exists habits_user_id_idx on public.habits (user_id);

alter table public.habits enable row level security;

drop policy if exists "Habits are fully managed by owner" on public.habits;
create policy "Habits are fully managed by owner"
  on public.habits for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 4. habit_logs — one row per habit per completed day
-- ----------------------------------------------------------------------------
create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  completed_date date not null default (now() at time zone 'utc')::date,
  created_at timestamptz not null default now(),
  unique (habit_id, completed_date)
);

create index if not exists habit_logs_habit_id_idx on public.habit_logs (habit_id);
create index if not exists habit_logs_user_id_idx on public.habit_logs (user_id);

alter table public.habit_logs enable row level security;

drop policy if exists "Habit logs are fully managed by owner" on public.habit_logs;
create policy "Habit logs are fully managed by owner"
  on public.habit_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 5. goals
-- ----------------------------------------------------------------------------
create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'General',
  icon text not null default 'flag',
  color text not null default '#6C5CE7',
  target_date date,
  status text not null default 'active' check (status in ('active', 'completed', 'archived')),
  manual_progress numeric not null default 0 check (manual_progress >= 0 and manual_progress <= 100),
  created_at timestamptz not null default now()
);

create index if not exists goals_user_id_idx on public.goals (user_id);

alter table public.goals enable row level security;

drop policy if exists "Goals are fully managed by owner" on public.goals;
create policy "Goals are fully managed by owner"
  on public.goals for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 6. goal_milestones — optional sub-steps under a goal
-- ----------------------------------------------------------------------------
create table if not exists public.goal_milestones (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  is_completed boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists goal_milestones_goal_id_idx on public.goal_milestones (goal_id);

alter table public.goal_milestones enable row level security;

drop policy if exists "Goal milestones are fully managed by owner" on public.goal_milestones;
create policy "Goal milestones are fully managed by owner"
  on public.goal_milestones for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================================
-- Done. Next steps:
--   1. Enable the Google provider under Authentication > Providers, and add
--      your OAuth client ID/secret from Google Cloud Console.
--   2. Add your app's redirect URLs (web origin + io.nahid.tasktracker://login-callback)
--      under Authentication > URL Configuration > Redirect URLs.
--   3. Copy your Project URL and anon public key into lib/core/supabase/supabase_config.dart.
-- ============================================================================
