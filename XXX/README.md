# XXX Manager

Standalone Flutter manager app for Sayed Al-Dukan.

- Email/password manager login (Supabase Auth)
- Manager authorization must be enforced server-side with a manager role
- Product management UI
- Biometric unlock planned after first successful login

## Setup

Provide Supabase URL and anon key via build-time Dart defines:
`flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

Never embed service-role keys in the app.
