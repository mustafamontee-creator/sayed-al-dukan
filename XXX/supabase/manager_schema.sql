-- XXX manager additive schema (not deployed automatically)
create extension if not exists pgcrypto;

create table if not exists public.xxx_manager_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.xxx_is_manager()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.xxx_manager_users m where m.user_id = auth.uid()) $$;

create table if not exists public.xxx_settings (
  id uuid primary key default gen_random_uuid(),
  setting_key text not null unique,
  setting_value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);
create table if not exists public.xxx_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(12,2) not null default 0,
  description text not null default '',
  image_url text,
  category text,
  stock_quantity integer,
  visible boolean not null default true,
  draft boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.xxx_pages (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  page_key text not null unique,
  icon_name text,
  payload jsonb not null default '{}'::jsonb,
  visible boolean not null default true,
  draft boolean not null default true,
  sort_order integer not null default 0,
  updated_at timestamptz not null default now()
);
create table if not exists public.xxx_categories (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text,
  sort_order integer not null default 0,
  visible boolean not null default true,
  draft boolean not null default true
);
create table if not exists public.xxx_banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text,
  link_payload jsonb not null default '{}'::jsonb,
  starts_at timestamptz,
  ends_at timestamptz,
  visible boolean not null default false,
  draft boolean not null default true
);
create table if not exists public.xxx_customer_messages (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references auth.users(id) on delete set null,
  customer_name text,
  subject text,
  order_id text,
  message text not null,
  manager_reply text,
  status text not null default 'new' check(status in ('new','open','replied','closed')),
  created_at timestamptz not null default now(),
  replied_at timestamptz
);
create table if not exists public.xxx_broadcasts (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  audience text not null default 'all' check(audience in ('all','selected','orders')),
  scheduled_at timestamptz,
  sent_at timestamptz,
  draft boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.xxx_coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_type text not null check(discount_type in ('percent','amount')),
  discount_value numeric(12,2) not null,
  starts_at timestamptz,
  ends_at timestamptz,
  usage_limit integer,
  active boolean not null default false
);
create table if not exists public.xxx_change_log (
  id uuid primary key default gen_random_uuid(),
  actor uuid references auth.users(id),
  action text not null,
  target_table text,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists public.xxx_admin_notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  starts_at timestamptz,
  ends_at timestamptz,
  draft boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.xxx_manager_users enable row level security;
alter table public.xxx_settings enable row level security;
alter table public.xxx_products enable row level security;
alter table public.xxx_pages enable row level security;
alter table public.xxx_categories enable row level security;
alter table public.xxx_banners enable row level security;
alter table public.xxx_customer_messages enable row level security;
alter table public.xxx_broadcasts enable row level security;
alter table public.xxx_coupons enable row level security;
alter table public.xxx_change_log enable row level security;
alter table public.xxx_admin_notices enable row level security;

-- Only explicitly enrolled managers may access manager tables.
do $$ declare t text; begin
 foreach t in array array['xxx_manager_users','xxx_settings','xxx_products','xxx_pages','xxx_categories','xxx_banners','xxx_customer_messages','xxx_broadcasts','xxx_coupons','xxx_change_log','xxx_admin_notices'] loop
   execute format('drop policy if exists xxx_manager_access on public.%I',t);
   execute format('create policy xxx_manager_access on public.%I for all to authenticated using (public.xxx_is_manager()) with check (public.xxx_is_manager())',t);
 end loop;
end $$;

grant select, insert, update, delete on public.xxx_manager_users, public.xxx_settings, public.xxx_products, public.xxx_pages, public.xxx_categories, public.xxx_banners, public.xxx_customer_messages, public.xxx_broadcasts, public.xxx_coupons, public.xxx_change_log, public.xxx_admin_notices to authenticated;
