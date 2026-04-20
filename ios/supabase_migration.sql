-- LocalMarketplace Supabase Migration
-- Run this in your Supabase Dashboard SQL Editor

create extension if not exists "uuid-ossp";

-- Profiles
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  username text not null,
  avatar_url text,
  role text not null default 'buyer',
  is_deleted boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Vendors
create table vendors (
  user_id uuid references profiles(id) on delete cascade primary key,
  store_name text not null default '',
  bio text,
  categories text[] default '{}',
  meetup_address text not null default '',
  meetup_spot_note text,
  profile_image_url text,
  cover_image_url text,
  lat double precision,
  lng double precision,
  approved boolean default false,
  is_disabled boolean default false,
  is_active boolean default false,
  active_until timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Vendor Applications
create table vendor_applications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) on delete cascade not null,
  status text not null default 'pending',
  contact_email text not null,
  contact_phone text not null,
  answers_json jsonb default '{}',
  admin_note text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Binders
create table binders (
  id uuid default uuid_generate_v4() primary key,
  vendor_id uuid references vendors(user_id) on delete cascade not null,
  name text not null,
  sort_order integer default 0,
  is_hidden boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Items
create table items (
  id uuid default uuid_generate_v4() primary key,
  vendor_id uuid references vendors(user_id) on delete cascade not null,
  binder_id uuid references binders(id) on delete set null,
  name text not null,
  price_cad double precision not null,
  category text not null,
  condition text,
  note text,
  status text not null default 'active',
  image1_url text,
  image2_url text,
  tcg_card_id text,
  tcg_card_name text,
  tcg_card_number text,
  tcg_card_display text,
  tcg_card_image_url text,
  slab_grade integer,
  slab_company text,
  slab_company_other text,
  quantity integer default 1,
  sold_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Card Shows (LTE)
create table card_shows (
  id uuid default uuid_generate_v4() primary key,
  creator_vendor_id uuid references vendors(user_id) on delete cascade not null,
  title text not null,
  event_description text not null default '',
  event_date timestamptz not null,
  end_time timestamptz,
  is_multi_day boolean default false,
  day_schedules jsonb default '[]',
  visible_on_map_date timestamptz,
  address text not null,
  lat double precision,
  lng double precision,
  map_image_url text,
  poster_image_url text,
  attendee_vendor_ids text[] default '{}',
  spotlighted_vendor_ids text[] default '{}',
  created_at timestamptz default now()
);

-- Conversations
create table conversations (
  id uuid default uuid_generate_v4() primary key,
  participant1_id uuid references profiles(id) on delete cascade not null,
  participant2_id uuid references profiles(id) on delete cascade not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(participant1_id, participant2_id)
);

-- Messages
create table messages (
  id uuid default uuid_generate_v4() primary key,
  conversation_id uuid references conversations(id) on delete cascade not null,
  sender_id uuid references profiles(id) on delete cascade not null,
  body text not null,
  created_at timestamptz default now()
);

-- Follows
create table follows (
  id uuid default uuid_generate_v4() primary key,
  follower_id uuid references profiles(id) on delete cascade not null,
  vendor_id uuid references profiles(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique(follower_id, vendor_id)
);

-- Blocks
create table blocks (
  id uuid default uuid_generate_v4() primary key,
  blocker_id uuid references profiles(id) on delete cascade not null,
  blocked_id uuid references profiles(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique(blocker_id, blocked_id)
);

-- Reports
create table reports (
  id uuid default uuid_generate_v4() primary key,
  reporter_id uuid references profiles(id) on delete cascade not null,
  reported_user_id uuid,
  reported_vendor_id uuid,
  conversation_id uuid,
  reason text not null,
  details text,
  status text not null default 'open',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Notification Preferences
create table notification_prefs (
  user_id uuid references profiles(id) on delete cascade primary key,
  push_enabled boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============ RLS POLICIES ============

alter table profiles enable row level security;
alter table vendors enable row level security;
alter table vendor_applications enable row level security;
alter table binders enable row level security;
alter table items enable row level security;
alter table card_shows enable row level security;
alter table conversations enable row level security;
alter table messages enable row level security;
alter table follows enable row level security;
alter table blocks enable row level security;
alter table reports enable row level security;
alter table notification_prefs enable row level security;

-- Profiles
create policy "Public profiles viewable" on profiles for select using (true);
create policy "Users insert own profile" on profiles for insert with check (auth.uid() = id);
create policy "Users update own profile" on profiles for update using (auth.uid() = id);

-- Vendors
create policy "Anyone view vendors" on vendors for select using (true);
create policy "Vendors insert own" on vendors for insert with check (auth.uid() = user_id);
create policy "Vendors update own" on vendors for update using (auth.uid() = user_id);

-- Vendor Applications
create policy "Users view own apps" on vendor_applications for select using (auth.uid() = user_id);
create policy "Admins view all apps" on vendor_applications for select using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "Users submit apps" on vendor_applications for insert with check (auth.uid() = user_id);
create policy "Admins update apps" on vendor_applications for update using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- Binders
create policy "Anyone view binders" on binders for select using (true);
create policy "Vendors insert binders" on binders for insert with check (auth.uid() = vendor_id);
create policy "Vendors update binders" on binders for update using (auth.uid() = vendor_id);
create policy "Vendors delete binders" on binders for delete using (auth.uid() = vendor_id);

-- Items
create policy "Anyone view items" on items for select using (true);
create policy "Vendors insert items" on items for insert with check (auth.uid() = vendor_id);
create policy "Vendors update items" on items for update using (auth.uid() = vendor_id);
create policy "Vendors delete items" on items for delete using (auth.uid() = vendor_id);

-- Card Shows
create policy "Anyone view shows" on card_shows for select using (true);
create policy "Vendors create shows" on card_shows for insert with check (auth.uid() = creator_vendor_id);
create policy "Auth users update shows" on card_shows for update using (auth.uid() is not null);
create policy "Creator delete shows" on card_shows for delete using (auth.uid() = creator_vendor_id);

-- Conversations
create policy "Users view own convos" on conversations for select using (auth.uid() = participant1_id or auth.uid() = participant2_id);
create policy "Users create convos" on conversations for insert with check (auth.uid() = participant1_id or auth.uid() = participant2_id);
create policy "Users update own convos" on conversations for update using (auth.uid() = participant1_id or auth.uid() = participant2_id);

-- Messages
create policy "Users view convo msgs" on messages for select using (exists (select 1 from conversations where id = messages.conversation_id and (participant1_id = auth.uid() or participant2_id = auth.uid())));
create policy "Users send msgs" on messages for insert with check (auth.uid() = sender_id);

-- Follows
create policy "Anyone view follows" on follows for select using (true);
create policy "Users insert follows" on follows for insert with check (auth.uid() = follower_id);
create policy "Users delete follows" on follows for delete using (auth.uid() = follower_id);

-- Blocks
create policy "Users view own blocks" on blocks for select using (auth.uid() = blocker_id);
create policy "Users insert blocks" on blocks for insert with check (auth.uid() = blocker_id);
create policy "Users delete blocks" on blocks for delete using (auth.uid() = blocker_id);

-- Reports
create policy "Users submit reports" on reports for insert with check (auth.uid() = reporter_id);
create policy "Admins view reports" on reports for select using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));
create policy "Users view own reports" on reports for select using (auth.uid() = reporter_id);
create policy "Admins update reports" on reports for update using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- Notification Prefs
create policy "Users view own prefs" on notification_prefs for select using (auth.uid() = user_id);
create policy "Users insert prefs" on notification_prefs for insert with check (auth.uid() = user_id);
create policy "Users update prefs" on notification_prefs for update using (auth.uid() = user_id);

-- Wanted Cards
create table wanted_cards (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) on delete cascade not null,
  slot_index integer not null check (slot_index >= 0 and slot_index <= 4),
  tcg_card_id text not null,
  tcg_card_name text not null,
  tcg_card_image_url text not null,
  tcg_card_number text not null default '',
  tcg_card_set_name text not null default '',
  bid_price double precision not null,
  conditions text[] not null default '{}',
  grading_company text,
  grades text[],
  notes text check (char_length(notes) <= 250),
  latitude double precision not null,
  longitude double precision not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, slot_index)
);

-- Wanted Card Stats (background tallies)
create table wanted_card_stats (
  tcg_card_id text primary key,
  active_count integer not null default 0,
  condition_counts jsonb not null default '{}',
  avg_bid_by_condition jsonb not null default '{}',
  updated_at timestamptz default now()
);

alter table wanted_cards enable row level security;
alter table wanted_card_stats enable row level security;

create policy "Anyone view wanted cards" on wanted_cards for select using (true);
create policy "Users insert own wanted cards" on wanted_cards for insert with check (auth.uid() = user_id);
create policy "Users update own wanted cards" on wanted_cards for update using (auth.uid() = user_id);
create policy "Users delete own wanted cards" on wanted_cards for delete using (auth.uid() = user_id);

create policy "Anyone view wanted stats" on wanted_card_stats for select using (true);
create policy "Auth users upsert stats" on wanted_card_stats for insert with check (auth.uid() is not null);
create policy "Auth users update stats" on wanted_card_stats for update using (auth.uid() is not null);

-- ============ STORAGE BUCKETS ============
-- Create these in Supabase Dashboard > Storage:
-- 1. "avatars" (public bucket)
-- 2. "vendors" (public bucket)
-- 3. "items" (public bucket)
-- 4. "events" (public bucket)
--
-- For each bucket, add these storage policies:
-- SELECT: Allow public access (anon role)
-- INSERT: Allow authenticated users
-- UPDATE: Allow authenticated users
-- DELETE: Allow authenticated users
