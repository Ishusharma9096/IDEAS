# GoaBusConnect backend and GPS setup

## Local Supabase configuration

The Flutter app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` using compile-time `String.fromEnvironment` values. The `SUPABASE_ANON_KEY` setting accepts the Supabase **Publishable** key (the key formerly called anon/public). Never use a secret/service-role key in a Flutter client.

1. Copy `supabase.local.json.example` to `supabase.local.json` in the project root.
2. Open `supabase.local.json` locally and replace `PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE` with the Publishable key from Supabase **Project Settings → API Keys**. The project URL is already filled in. Do not paste the key into chat or commit this file; `.gitignore` excludes it.
3. Run `flutter pub get`, then start the app with:

```powershell
flutter run --dart-define-from-file=supabase.local.json
```

For a release Android build with the same configuration:

```powershell
flutter build apk --release --dart-define-from-file=supabase.local.json
```

`.env.example` is documentation only; Flutter does not parse dotenv files. `supabase.local.json.example` is the copyable template for Flutter's `--dart-define-from-file` option. Do not put credentials in source code, a checked-in file, or a service-role key in this config.

`SupabaseService.initializeIfConfigured()` initializes Supabase before `runApp` when both compile-time values are present. With missing values or an initialization/network failure, app startup continues in demo/offline mode. Authentication calls surface their own errors; database features use Supabase client requests and show offline/error states. Initializing the client does not prove database access. A successful authenticated request to a migrated table is needed to verify the schema and RLS.

## Database migration (not applied)

The migration has not been run. After local configuration is ready, open the Supabase Dashboard for this project, go to **SQL Editor**, review `supabase/migrations/202611170001_initial_schema.sql`, and execute it there (or use the Supabase CLI after linking the project). Then create/provision an organization, trusted owner/operator profiles and bus assignments. Do not grant roles from the passenger client. Verify RLS with separate passenger, operator and owner accounts before using real data.

## Current data boundary

No GTFS archive or table files were present in this repository when the app was inspected. Bundled route, stop, bus, time and fare examples are **DEMO DATA / UNVERIFIED** and must not be treated as official schedules. Import future feeds into separate staging tables, retain their agency/source and feed timestamp, and publish only after verification.

## GPS permissions and limits

Android declares coarse/fine location permission. iOS requests When-In-Use location. Tracking runs only while the operator screen is active; background tracking is not configured. The app obtains device fixes through Geolocator and only then attempts an upsert. `LIVE GPS · uploaded` is tied to a successful latest database write; missing permission, no fix, no assignment and network/backend errors remain offline. Old records include `recorded_at`; clients must display age and not interpret a stale row as current live data.

## Map

The app uses `flutter_map`. The default raster source is OpenStreetMap's public tile endpoint with attribution. For production, set `MAP_TILE_URL` in the local JSON config to a provider URL and comply with its tile policy. `MAP_PROVIDER_KEY` is not automatically inserted into a URL. No road geometry or verified stop coordinates are bundled; the app does not invent route lines or stop markers.

## RLS and privacy

The migration enables RLS on application tables. Passenger complaints are private to their `passenger_id`; owners can read/update complaints for their organization. Complaint insertion requires an authenticated profile and a bus belonging to the supplied organization. Local demo complaints remain on-device. Do not disable RLS or ship a service-role credential.

The migration is a starting schema, not a production security certification. Apply it to a disposable Supabase project first, inspect policies with separate passenger/operator/owner accounts, and review grants, backups, retention and abuse controls before handling passenger data.

## Tests and checks

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```