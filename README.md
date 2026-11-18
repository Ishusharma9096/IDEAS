# GoaBusConnect

GoaBusConnect helps passengers discover public transport information, verify its source, and plan journeys across Goa. It is an information and journey-planning app; it does not book tickets.

## Passenger experience

The Flutter app includes onboarding, a four-tab passenger shell (Home, Explore, Journeys, Profile), journey search, route and stop discovery entry points, GPS availability, passenger issue reporting, travel alerts, and offers. Where there is no connected transport data, the interface says so instead of showing invented buses, ETAs, GPS movement, verified reports, or active promotions.

## Project structure

- `lib/app`: GoRouter and app configuration
- `lib/screens`: splash, onboarding, and primary passenger tabs
- `lib/widgets`: reusable passenger widgets
- `lib/features/information`: transport information, availability, journey results, and report screens
- `lib/theme`: Material 3 theme

## Data integrations

Supabase/PostgreSQL/PostGIS, Google Maps, Firebase Cloud Messaging, authentication, and server-backed report moderation still need environment configuration and backend implementation. No API keys or secrets are stored in the client. Live bus status must only be surfaced after a genuine GPS feed is connected; published timetable data must remain distinct from live tracking.

## Development

Use Flutter and Dart with the Android and iOS projects in this repository. After installing dependencies, run `dart format lib test`, `flutter analyze`, and `flutter test`.
