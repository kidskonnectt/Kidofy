-- Users Table (Admins/Parents) extends auth.users
create table public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  email text,
  is_admin boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Users
alter table public.users enable row level security;

-- Helper: avoid infinite recursion in RLS policies by using a SECURITY DEFINER function.
-- This reads `public.users` as the table owner, bypassing RLS (unless FORCE RLS is enabled).
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid() and is_admin = true
  );
$$;

-- Admins can view/edit all users
drop policy if exists "Admins can view all users" on public.users;
drop policy if exists "Admins can update users" on public.users;
drop policy if exists "Users can view own profile" on public.users;

create policy "Admins can view all users"
  on public.users for select
  using ( public.is_admin() );

create policy "Admins can update users"
  on public.users for update
  using ( public.is_admin() )
  with check ( public.is_admin() );

-- Users can view their own profile
create policy "Users can view own profile"
  on public.users for select
  using ( id = auth.uid() );

-- Trigger to create public user entry on Signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, is_admin)
  values (new.id, new.email, false);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Update Policies for Categories/Videos for Admin Use

-- NOTE: If you're migrating an existing project, also add these columns:
--   alter table public.categories add column if not exists icon_path text;
--   alter table public.videos add column if not exists channel_avatar_path text;
--   alter table public.videos add column if not exists is_shorts boolean not null default false;

drop policy if exists "Admins can modify categories" on public.categories;
drop policy if exists "Admins can insert categories" on public.categories;
drop policy if exists "Admins can update categories" on public.categories;
drop policy if exists "Admins can delete categories" on public.categories;

drop policy if exists "Admins can modify videos" on public.videos;
drop policy if exists "Admins can insert videos" on public.videos;
drop policy if exists "Admins can update videos" on public.videos;
drop policy if exists "Admins can delete videos" on public.videos;

-- Allow Admins to Insert/Update/Delete Categories
create policy "Admins can insert categories"
  on public.categories for insert
  with check ( public.is_admin() );

create policy "Admins can update categories"
  on public.categories for update
  using ( public.is_admin() )
  with check ( public.is_admin() );

create policy "Admins can delete categories"
  on public.categories for delete
  using ( public.is_admin() );

-- Allow Admins to Insert/Update/Delete Videos
create policy "Admins can insert videos"
  on public.videos for insert
  with check ( public.is_admin() );

create policy "Admins can update videos"
  on public.videos for update
  using ( public.is_admin() )
  with check ( public.is_admin() );

create policy "Admins can delete videos"
  on public.videos for delete
  using ( public.is_admin() );

