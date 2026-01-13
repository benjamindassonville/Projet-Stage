-- =========================================================
-- EXTENSIONS
-- =========================================================
create extension if not exists "uuid-ossp";

-- =========================================================
-- TABLE ROLES
-- =========================================================
create table if not exists roles (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- TABLE PERMISSIONS
-- =========================================================
create table if not exists permissions (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- TABLE ROLES_PERMISSIONS (MANY-TO-MANY)
-- =========================================================
create table if not exists roles_permissions (
  id uuid primary key default uuid_generate_v4(),
  role_id uuid not null references roles(id) on delete cascade,
  permission_id uuid not null references permissions(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (role_id, permission_id)
);

-- =========================================================
-- TABLE USERS_PROFILES
-- (liée à auth.users via id)
-- =========================================================
create table if not exists users_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  role_id uuid not null references roles(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- =========================================================
-- TABLE CLIENTS
-- =========================================================
create table if not exists clients (
  id uuid primary key default uuid_generate_v4(),
  first_name text not null,
  last_name text not null,
  email text,
  phone text,
  address text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- TABLE INTERVENTIONS
-- =========================================================
create table if not exists interventions (
  id uuid primary key default uuid_generate_v4(),
  client_id uuid not null references clients(id) on delete restrict,
  user_id uuid not null references users_profiles(id) on delete restrict,
  scheduled_at timestamptz not null,
  type text not null,
  status text not null check (status in ('prevue', 'en_cours', 'terminee')),
  notes text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- TABLE SECURITY_LOGS
-- =========================================================
create table if not exists security_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users_profiles(id) on delete set null,
  action text not null,
  details text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- ACTIVER ROW LEVEL SECURITY (RLS)
-- =========================================================
alter table roles enable row level security;
alter table permissions enable row level security;
alter table roles_permissions enable row level security;
alter table users_profiles enable row level security;
alter table clients enable row level security;
alter table interventions enable row level security;
alter table security_logs enable row level security;

-- =========================================================
-- POLITIQUES RLS DE BASE (SÛRES ET RÉALISTES)
-- =========================================================

-- USERS_PROFILES : un utilisateur peut lire son propre profil
create policy "users can read their profile"
on users_profiles
for select
using (auth.uid() = id);

-- CLIENTS : lecture pour utilisateurs authentifiés
create policy "authenticated users can read clients"
on clients
for select
using (auth.role() = 'authenticated');

-- CLIENTS : écriture réservée aux utilisateurs actifs
create policy "active users can write clients"
on clients
for insert with check (
  exists (
    select 1 from users_profiles up
    where up.id = auth.uid() and up.is_active = true
  )
);

create policy "active users can update clients"
on clients
for update
using (
  exists (
    select 1 from users_profiles up
    where up.id = auth.uid() and up.is_active = true
  )
);

-- INTERVENTIONS : un utilisateur voit ses interventions
create policy "users read their interventions"
on interventions
for select
using (user_id = auth.uid());

-- INTERVENTIONS : un utilisateur modifie ses interventions
create policy "users manage their interventions"
on interventions
for insert with check (user_id = auth.uid());

create policy "users update their interventions"
on interventions
for update
using (user_id = auth.uid());

-- SECURITY_LOGS : accès restreint (aucun accès public)
-- (les règles admin seront ajoutées plus tard)
