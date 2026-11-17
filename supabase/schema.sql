-- =====================================================================
-- Sayed Al-Dukan  |  PostgreSQL / Supabase schema  (run once, in order)
-- Shared by the customer app and the future admin app "XXX".
-- Admins = rows in public.admins. Customers can only touch their own rows.
-- No demo data is inserted on purpose.
-- =====================================================================
create extension if not exists pgcrypto;

-- ---------- helpers ---------------------------------------------------
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at = now(); return new; end $$;

-- ---------- users / sign-in methods ----------------------------------
-- auth.users + auth.identities (managed by Supabase) hold phone/Google/Apple.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  contact_phone text,
  preferred_language text not null default 'ar' check (preferred_language in ('ar','en')),
  region text not null default 'EG',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'))
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- catalogue -------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  unit_price numeric(12,2) not null check (unit_price > 0),
  min_order_value numeric(12,2) not null default 0 check (min_order_value >= 0), -- MONEY value
  ingredients text[] not null default '{}',
  image_url text,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger products_touch before update on public.products
  for each row execute function public.touch_updated_at();

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  url text not null,
  sort_order int not null default 0
);
create index if not exists product_images_product on public.product_images(product_id);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  author_name text not null default '',
  rating int not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists reviews_product on public.reviews(product_id);

-- ---------- cart ------------------------------------------------------
create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity int not null check (quantity > 0),
  note text not null default '',           -- per-product note ("نبذة عن طلبك")
  updated_at timestamptz not null default now(),
  unique (user_id, product_id)
);

-- ---------- addresses -------------------------------------------------
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  address_text text not null default '',
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  landmark text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index if not exists one_default_address_per_user
  on public.addresses(user_id) where is_default;

-- ---------- orders ----------------------------------------------------
-- Statuses are a lookup table so XXX can define the real workflow later.
create table if not exists public.order_statuses (
  code text primary key,
  sort_order int not null default 0
);
insert into public.order_statuses(code, sort_order) values ('pending', 0)
  on conflict do nothing;

create sequence if not exists public.order_number_seq;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  user_id uuid not null references auth.users(id),
  address_snapshot jsonb not null,           -- address as it was when ordered
  status text not null default 'pending' references public.order_statuses(code),
  subtotal numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,    -- = subtotal (no fees/taxes/payment methods approved yet)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger orders_touch before update on public.orders
  for each row execute function public.touch_updated_at();
create index if not exists orders_user on public.orders(user_id, created_at desc);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price numeric(12,2) not null,
  quantity int not null check (quantity > 0),
  note text not null default '',
  line_total numeric(12,2) not null
);
create index if not exists order_items_order on public.order_items(order_id);

create table if not exists public.order_events (            -- order audit log
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  status text not null references public.order_statuses(code),
  note text,
  actor uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- Editable "about" content (no invented copy in the app).
create table if not exists public.app_content (
  id uuid primary key default gen_random_uuid(),
  section text not null check (section in ('about_main','extra')),
  sort_order int not null default 0,
  title text not null default '',
  body text not null default '',
  image_url text,
  is_published boolean not null default true
);

-- ---------- place_order(): the ONLY way to create an order -------------
create or replace function public.place_order(p_address_id uuid, p_items jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_addr public.addresses%rowtype;
  v_prod public.products%rowtype;
  v_item jsonb;
  v_order uuid := gen_random_uuid();
  v_number text;
  v_qty int;
  v_min int;
  v_line numeric(12,2);
  v_total numeric(12,2) := 0;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode = '28000'; end if;
  select * into v_addr from public.addresses where id = p_address_id and user_id = v_uid;
  if not found then raise exception 'address_not_found'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'empty_cart';
  end if;

  v_number := 'SD-' || to_char(now() at time zone 'Africa/Cairo', 'YYMMDD') || '-' ||
              lpad(nextval('public.order_number_seq')::text, 5, '0');

  insert into public.orders(id, order_number, user_id, address_snapshot, status)
  values (v_order, v_number, v_uid,
          jsonb_build_object('address_text', v_addr.address_text, 'latitude', v_addr.latitude,
                             'longitude', v_addr.longitude, 'landmark', v_addr.landmark),
          'pending');

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_prod from public.products
      where id = (v_item->>'product_id')::uuid and is_active;
    if not found then raise exception 'product_unavailable'; end if;
    v_qty := (v_item->>'quantity')::int;
    v_min := case when v_prod.min_order_value > 0
                  then greatest(ceil(v_prod.min_order_value / v_prod.unit_price)::int, 1)
                  else 1 end;
    if v_qty is null or v_qty < v_min then raise exception 'below_minimum'; end if;
    v_line := v_qty * v_prod.unit_price;               -- price comes from the DB, never the client
    v_total := v_total + v_line;
    insert into public.order_items(order_id, product_id, product_name, unit_price, quantity, note, line_total)
    values (v_order, v_prod.id, v_prod.name, v_prod.unit_price, v_qty,
            coalesce(v_item->>'note', ''), v_line);
  end loop;

  update public.orders set subtotal = v_total, total = v_total where id = v_order;
  insert into public.order_events(order_id, status, actor) values (v_order, 'pending', v_uid);
  delete from public.cart_items where user_id = v_uid;
  return jsonb_build_object('order_id', v_order, 'order_number', v_number);
end $$;

revoke all on function public.place_order(uuid, jsonb) from public, anon;
grant execute on function public.place_order(uuid, jsonb) to authenticated;

-- ---------- Row Level Security ---------------------------------------
alter table public.admins          enable row level security;
alter table public.profiles        enable row level security;
alter table public.products        enable row level security;
alter table public.product_images  enable row level security;
alter table public.reviews         enable row level security;
alter table public.cart_items      enable row level security;
alter table public.addresses       enable row level security;
alter table public.order_statuses  enable row level security;
alter table public.orders          enable row level security;
alter table public.order_items     enable row level security;
alter table public.order_events    enable row level security;
alter table public.app_content     enable row level security;

create policy admins_self_read   on public.admins for select using (user_id = auth.uid());

create policy profiles_own_read  on public.profiles for select using (id = auth.uid() or public.is_admin());
create policy profiles_own_write on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy products_read      on public.products for select using (is_active or public.is_admin());
create policy products_admin     on public.products for all using (public.is_admin()) with check (public.is_admin());

create policy pimages_read       on public.product_images for select using (
  public.is_admin() or exists (select 1 from public.products p where p.id = product_id and p.is_active));
create policy pimages_admin      on public.product_images for all using (public.is_admin()) with check (public.is_admin());

create policy reviews_read       on public.reviews for select using (true);
create policy reviews_insert_own on public.reviews for insert with check (user_id = auth.uid());
create policy reviews_admin      on public.reviews for all using (public.is_admin()) with check (public.is_admin());

create policy cart_own           on public.cart_items for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy addr_own           on public.addresses for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy addr_admin_read    on public.addresses for select using (public.is_admin());

create policy statuses_read      on public.order_statuses for select using (true);
create policy statuses_admin     on public.order_statuses for all using (public.is_admin()) with check (public.is_admin());

-- Customers: read-only on their own orders (creation only via place_order()).
create policy orders_read        on public.orders for select using (user_id = auth.uid() or public.is_admin());
create policy orders_admin_write on public.orders for update using (public.is_admin()) with check (public.is_admin());

create policy oitems_read        on public.order_items for select using (
  public.is_admin() or exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));
create policy oitems_admin       on public.order_items for all using (public.is_admin()) with check (public.is_admin());

create policy oevents_read       on public.order_events for select using (
  public.is_admin() or exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));
create policy oevents_admin      on public.order_events for all using (public.is_admin()) with check (public.is_admin());

create policy content_read       on public.app_content for select using (is_published or public.is_admin());
create policy content_admin      on public.app_content for all using (public.is_admin()) with check (public.is_admin());

-- ---------- Storage: public product images, admin-only writes ----------
insert into storage.buckets (id, name, public) values ('product-images', 'product-images', true)
  on conflict (id) do nothing;
create policy "product images public read" on storage.objects for select
  using (bucket_id = 'product-images');
create policy "product images admin write" on storage.objects for all
  using (bucket_id = 'product-images' and public.is_admin())
  with check (bucket_id = 'product-images' and public.is_admin());

-- ---------- Contract for the future admin app XXX -------------------------
-- XXX (signed in as a row of public.admins) can, with plain table writes:
--   products        insert / update name, description, unit_price, min_order_value,
--                   ingredients, image_url, sort_order, is_active (hide/show)
--   product_images  insert / update / delete  (+ files in bucket 'product-images')
--   orders          update status;  order_events insert (audit trail)
--   order_statuses  define the real status workflow
--   app_content     edit the About page content
-- The customer app reads these tables live, so no new APK is needed.

-- To make someone an admin (for the XXX app), run once as project owner:
--   insert into public.admins(user_id) values ('<auth user uuid>');
