create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'passenger' check (role in ('passenger','operator','owner','admin')),
  created_at timestamptz not null default now()
);
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 120),
  owner_user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.buses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  identifier text not null,
  operator_name text not null,
  ownership text not null check (ownership in ('government','private')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (organization_id, identifier), unique (organization_id, id)
);
create table public.drivers (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  full_name text not null, phone text, active boolean not null default true, created_at timestamptz not null default now(), unique (organization_id,id)
);
create table public.conductors (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  full_name text not null, phone text, active boolean not null default true, created_at timestamptz not null default now(), unique (organization_id,id)
);
create table public.routes (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null, source_label text not null, destination_label text not null, active boolean not null default true, unique (organization_id,id)
);
create table public.stops (
  id uuid primary key default gen_random_uuid(), organization_id uuid references public.organizations(id) on delete cascade,
  name text not null, area text not null default '', latitude double precision, longitude double precision,
  check ((latitude is null and longitude is null) or (latitude between -90 and 90 and longitude between -180 and 180))
);
create table public.trips (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  bus_id uuid not null references public.buses(id) on delete cascade, route_id uuid not null references public.routes(id) on delete cascade,
  driver_id uuid references public.drivers(id) on delete set null, conductor_id uuid references public.conductors(id) on delete set null,
  service_date date not null, departure_time time, arrival_time time, fare numeric(8,2) check (fare is null or fare >= 0),
  data_source text not null default 'Owner-entered schedule', verification_status text not null default 'unverified' check(verification_status in ('unverified','verified','expired')),
  source_updated_at timestamptz, active boolean not null default true, unique(organization_id,id),
  foreign key (organization_id,bus_id) references public.buses(organization_id,id),
  foreign key (organization_id,route_id) references public.routes(organization_id,id),
  foreign key (organization_id,driver_id) references public.drivers(organization_id,id),
  foreign key (organization_id,conductor_id) references public.conductors(organization_id,id)
);
create table public.stop_times (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  trip_id uuid not null references public.trips(id) on delete cascade, stop_id uuid not null references public.stops(id) on delete restrict,
  stop_sequence integer not null check (stop_sequence > 0), arrival_time time, departure_time time, primary key (trip_id, stop_sequence),
  foreign key (organization_id,trip_id) references public.trips(organization_id,id)
);
create table public.bus_assignments (
  bus_id uuid not null references public.buses(id) on delete cascade, operator_id uuid not null references public.profiles(id) on delete cascade,
  assigned_at timestamptz not null default now(), primary key (bus_id, operator_id)
);
create table public.gps_locations (
  bus_id uuid primary key references public.buses(id) on delete cascade,
  operator_id uuid references public.profiles(id), latitude double precision not null check (latitude between -90 and 90), longitude double precision not null check (longitude between -180 and 180),
  accuracy_meters double precision, recorded_at timestamptz not null, is_active boolean not null default true
);
create table public.complaints (
  id uuid primary key default gen_random_uuid(), passenger_id uuid not null references public.profiles(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade, bus_id uuid not null references public.buses(id) on delete cascade,
  driver_id uuid references public.drivers(id) on delete set null, conductor_id uuid references public.conductors(id) on delete set null,
  subject_type text not null default 'bus' check(subject_type in ('bus','driver','conductor')),
  category text not null, description text not null check (length(trim(description)) between 5 and 4000), occurred_at timestamptz,
  status text not null default 'submitted' check(status in ('submitted','reviewing','resolved','dismissed')), created_at timestamptz not null default now(),
  foreign key (organization_id,bus_id) references public.buses(organization_id,id),
  foreign key (organization_id,driver_id) references public.drivers(organization_id,id),
  foreign key (organization_id,conductor_id) references public.conductors(organization_id,id)
);
create table public.saved_journeys (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  source_label text not null, destination_label text not null, route_id uuid references public.routes(id) on delete set null, created_at timestamptz not null default now()
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), organization_id uuid references public.organizations(id) on delete cascade,
  recipient_id uuid references public.profiles(id) on delete cascade, title text not null, body text not null, created_at timestamptz not null default now()
);

create index buses_org_idx on public.buses(organization_id);
create index drivers_org_idx on public.drivers(organization_id);
create index conductors_org_idx on public.conductors(organization_id);
create index routes_org_idx on public.routes(organization_id);
create index trips_bus_date_idx on public.trips(bus_id, service_date);
create index trips_route_idx on public.trips(route_id);
create index stop_times_stop_idx on public.stop_times(stop_id);
create index stop_times_org_idx on public.stop_times(organization_id);
create index gps_recorded_idx on public.gps_locations(recorded_at desc);
create index complaints_org_status_idx on public.complaints(organization_id, status, created_at desc);
create index complaints_passenger_idx on public.complaints(passenger_id, created_at desc);
create index notifications_recipient_idx on public.notifications(recipient_id, created_at desc);

create or replace function public.owns_org(org uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from organizations o join profiles p on p.id=o.owner_user_id where o.id=org and o.owner_user_id=auth.uid() and p.role in ('owner','admin')) $$;
create or replace function public.assigned_bus(bus uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from bus_assignments a join profiles p on p.id=a.operator_id where a.bus_id=bus and a.operator_id=auth.uid() and p.role='operator') $$;
revoke all on function public.owns_org(uuid) from public, anon;
revoke all on function public.assigned_bus(uuid) from public, anon;
grant execute on function public.owns_org(uuid) to authenticated;
grant execute on function public.assigned_bus(uuid) to authenticated;
create or replace function public.create_profile_for_auth_user() returns trigger language plpgsql security definer set search_path = public as $$ begin insert into public.profiles(id, display_name, role) values(new.id, coalesce(new.raw_user_meta_data->>'display_name',''), 'passenger') on conflict(id) do nothing; return new; end $$;
create trigger auth_user_profile after insert on auth.users for each row execute function public.create_profile_for_auth_user();
create or replace function public.prevent_profile_role_escalation() returns trigger language plpgsql security definer set search_path = public as $$ begin if auth.uid() is not null and new.role is distinct from old.role and coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then raise exception 'Profile roles are assigned by an administrator'; end if; return new; end $$;
create trigger profile_role_guard before update on public.profiles for each row execute function public.prevent_profile_role_escalation();
alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.buses enable row level security;
alter table public.drivers enable row level security;
alter table public.conductors enable row level security;
alter table public.routes enable row level security;
alter table public.stops enable row level security;
alter table public.trips enable row level security;
alter table public.stop_times enable row level security;
alter table public.bus_assignments enable row level security;
alter table public.gps_locations enable row level security;
alter table public.complaints enable row level security;
alter table public.saved_journeys enable row level security;
alter table public.notifications enable row level security;

create policy profile_self_read on public.profiles for select using(id=auth.uid());
create policy profile_self_update on public.profiles for update using(id=auth.uid()) with check(id=auth.uid());
create policy organization_owner_read on public.organizations for select using(public.owns_org(id));
create policy organization_owner_manage on public.organizations for all using(public.owns_org(id)) with check(owner_user_id=auth.uid() and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('owner','admin')));
create policy bus_public_read on public.buses for select using(active=true);
create policy bus_owner_manage on public.buses for all using(public.owns_org(organization_id)) with check(public.owns_org(organization_id));
create policy drivers_owner on public.drivers for all using(public.owns_org(organization_id)) with check(public.owns_org(organization_id));
create policy conductors_owner on public.conductors for all using(public.owns_org(organization_id)) with check(public.owns_org(organization_id));
create policy routes_read on public.routes for select using(active=true);
create policy routes_owner on public.routes for all using(public.owns_org(organization_id)) with check(public.owns_org(organization_id));
create policy stops_read on public.stops for select using(organization_id is null);
create policy stops_owner on public.stops for all using(organization_id is not null and public.owns_org(organization_id)) with check(organization_id is not null and public.owns_org(organization_id));
create policy trips_read on public.trips for select using(active=true);
create policy trips_owner on public.trips for all using(public.owns_org(organization_id)) with check(public.owns_org(organization_id));
create policy stop_times_read on public.stop_times for select using(exists(select 1 from trips t where t.id=trip_id and t.active));
create policy stop_times_owner on public.stop_times for all using(exists(select 1 from trips t where t.id=trip_id and public.owns_org(t.organization_id))) with check(exists(select 1 from trips t where t.id=trip_id and public.owns_org(t.organization_id)));
create policy assignments_owner on public.bus_assignments for all using(exists(select 1 from buses b where b.id=bus_id and public.owns_org(b.organization_id))) with check(exists(select 1 from buses b where b.id=bus_id and public.owns_org(b.organization_id)));
create policy assignments_operator_read on public.bus_assignments for select using(operator_id=auth.uid() and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='operator'));
create policy gps_passenger_read on public.gps_locations for select to anon, authenticated using(true);
create policy gps_operator_write on public.gps_locations for insert to authenticated with check(operator_id=auth.uid() and public.assigned_bus(bus_id));
create policy gps_operator_update on public.gps_locations for update to authenticated using(operator_id=auth.uid() and public.assigned_bus(bus_id)) with check(operator_id=auth.uid() and public.assigned_bus(bus_id));
create policy gps_owner_read on public.gps_locations for select to authenticated using(exists(select 1 from buses b where b.id=bus_id and public.owns_org(b.organization_id)));
create policy complaint_passenger_read on public.complaints for select to authenticated using(passenger_id=auth.uid());
create policy complaint_passenger_insert on public.complaints for insert to authenticated with check(passenger_id=auth.uid() and exists(select 1 from buses b where b.id=bus_id and b.organization_id=organization_id));
create policy complaint_owner_read on public.complaints for select to authenticated using(public.owns_org(organization_id));
create policy complaint_owner_update on public.complaints for update to authenticated using(public.owns_org(organization_id)) with check(public.owns_org(organization_id));
create policy saved_journeys_self on public.saved_journeys for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy notifications_read on public.notifications for select to authenticated using(recipient_id=auth.uid() or (organization_id is not null and public.owns_org(organization_id)));
create policy notifications_owner_insert on public.notifications for insert to authenticated with check(organization_id is null or public.owns_org(organization_id));

grant select on public.buses, public.routes, public.stops, public.trips, public.stop_times, public.gps_locations to anon, authenticated;
grant select, insert, update, delete on public.profiles, public.organizations, public.buses, public.drivers, public.conductors, public.routes, public.stops, public.trips, public.stop_times, public.bus_assignments, public.gps_locations, public.complaints, public.saved_journeys, public.notifications to authenticated;

do $$ begin
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='gps_locations') then
    alter publication supabase_realtime add table public.gps_locations;
  end if;
end $$;
