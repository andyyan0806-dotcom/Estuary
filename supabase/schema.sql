-- Estuary: Han River-Incheon Eutrophication Forecast App
-- Run this in your Supabase SQL editor to set up the schema.

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────────
-- STATIONS
-- ─────────────────────────────────────────────
create table if not exists stations (
  id          text primary key,          -- e.g. "HAN_001"
  name        text not null,
  lat         double precision not null,
  lng         double precision not null,
  region      text not null,             -- "han_estuary" | "incheon_coast"
  created_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- MEASUREMENTS
-- ─────────────────────────────────────────────
create table if not exists measurements (
  id              uuid primary key default uuid_generate_v4(),
  station_id      text references stations(id) on delete cascade,
  ts              timestamptz not null,
  water_temp      double precision,   -- °C
  ph              double precision,
  total_p         double precision,   -- mg/L  (Total Phosphorus)
  dissolved_o2    double precision,   -- mg/L  (DO)
  created_at      timestamptz default now()
);

create index if not exists idx_measurements_station_ts
  on measurements (station_id, ts desc);

-- ─────────────────────────────────────────────
-- RISK STATUS
-- ─────────────────────────────────────────────
create table if not exists risk_status (
  id          uuid primary key default uuid_generate_v4(),
  station_id  text references stations(id) on delete cascade,
  ts          timestamptz not null,
  level       text not null check (level in ('green', 'yellow', 'red')),
  reason      text,                   -- human-readable explanation
  created_at  timestamptz default now()
);

create index if not exists idx_risk_station_ts
  on risk_status (station_id, ts desc);

-- ─────────────────────────────────────────────
-- USER LOCATIONS (registered monitoring points)
-- ─────────────────────────────────────────────
create table if not exists user_locations (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid references auth.users(id) on delete cascade,
  label       text not null,
  lat         double precision not null,
  lng         double precision not null,
  created_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- ALERTS
-- ─────────────────────────────────────────────
create table if not exists alerts (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid references auth.users(id) on delete cascade,
  location_id     uuid references user_locations(id) on delete cascade,
  station_id      text references stations(id),
  level           text not null check (level in ('yellow', 'red')),
  sent_at         timestamptz default now()
);

-- ─────────────────────────────────────────────
-- FCM TOKENS (for push delivery)
-- ─────────────────────────────────────────────
create table if not exists fcm_tokens (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid references auth.users(id) on delete cascade,
  token       text not null unique,
  updated_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- ROW-LEVEL SECURITY
-- ─────────────────────────────────────────────
alter table stations       enable row level security;
alter table measurements   enable row level security;
alter table risk_status    enable row level security;
alter table user_locations enable row level security;
alter table alerts         enable row level security;
alter table fcm_tokens     enable row level security;

-- Public read for stations, measurements, risk_status
create policy "Public read stations"     on stations     for select using (true);
create policy "Public read measurements" on measurements for select using (true);
create policy "Public read risk_status"  on risk_status  for select using (true);

-- Users manage only their own rows
create policy "Own locations" on user_locations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Own alerts" on alerts
  for select using (auth.uid() = user_id);

create policy "Own fcm_tokens" on fcm_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Backend service role can insert/update everything (bypasses RLS)

-- ─────────────────────────────────────────────
-- SEED: initial Han estuary / Incheon stations
-- ─────────────────────────────────────────────
insert into stations (id, name, lat, lng, region) values
  ('HAN_EST_01', '한강하구 전류리',       37.6850, 126.5280, 'han_estuary'),
  ('HAN_EST_02', '한강하구 강화대교',     37.7200, 126.5000, 'han_estuary'),
  ('HAN_EST_03', '한강하구 초지대교',     37.6600, 126.5400, 'han_estuary'),
  ('ICN_CST_01', '인천 소래포구',         37.4110, 126.7330, 'incheon_coast'),
  ('ICN_CST_02', '인천 영종도 해안',      37.4900, 126.4900, 'incheon_coast'),
  ('ICN_CST_03', '인천 강화 동막해변',    37.5900, 126.4200, 'incheon_coast'),
  ('ICN_CST_04', '인천 연안부두',         37.4600, 126.6100, 'incheon_coast')
on conflict (id) do nothing;
