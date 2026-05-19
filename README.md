# Personal Utility App

A Flutter mobile application that brings together everyday productivity tools in one authenticated app. It includes QR business cards, QR scanning history, a unit converter, audio recording/playback, and an admin dashboard backed by Supabase.

## Features

- Supabase email/password authentication
- Forgot-password flow with Android deep-link password reset
- User/admin panel selection
- Database-backed admin role detection through `public.app_admins`
- QR business card CRUD
- QR code generation and scanning
- QR scan history
- Unit converter for common measurements
- Audio recording, upload, listing, playback, editing, and deletion
- Supabase Storage for private audio files
- Admin dashboard with cross-user activity totals and recent records
- Provider-based app state management

## Tech Stack

- Flutter
- Dart
- Provider
- Supabase Auth
- Supabase Postgres
- Supabase Storage
- Row Level Security policies
- `qr_flutter`
- `mobile_scanner`
- `record`
- `audioplayers`

## Project Structure

```text
lib/
  config/
    admin_config.dart
  models/
    business_card.dart
    converter_model.dart
    recording.dart
    scan_history.dart
  providers/
    auth_provider.dart
    business_card_provider.dart
    recording_provider.dart
  screens/
    admin/
    auth/
    converter/
    home/
    qr_card/
    recorder/
  services/
    audio_service.dart
    database_service.dart
  utils/
    app_constants.dart
  widgets/
    common_widgets.dart
  main.dart

android/app/src/main/AndroidManifest.xml
supabase_setup.sql
```

## Prerequisites

- Flutter SDK installed
- Android Studio or another Flutter-compatible IDE
- A Supabase project
- Android emulator or physical Android device

Check your Flutter setup:

```bash
flutter doctor
```

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build a debug APK:

```bash
flutter build apk --debug
```

## Supabase Setup

Run the SQL setup file in your Supabase project:

```text
supabase_setup.sql
```

In Supabase:

1. Open your project dashboard.
2. Go to SQL Editor.
3. Paste the contents of `supabase_setup.sql`.
4. Run the script.

The script creates:

- `business_cards`
- `scan_history`
- `recordings`
- `app_admins`
- Storage bucket `recordings`
- RLS policies for user-owned data
- RLS policies for admin dashboard reads
- Helper function `public.is_app_admin()`

## Supabase Credentials

The Supabase client is initialized in:

```text
lib/main.dart
```

Update these constants for your own Supabase project if needed:

```dart
const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Use the public anon key from:

```text
Supabase Dashboard -> Project Settings -> API
```

## Authentication Flow

The app uses Supabase Auth with email/password sign-in.

Auth state is managed in:

```text
lib/providers/auth_provider.dart
```

The root auth gate is in:

```text
lib/main.dart
```

Routing behavior:

- No session: panel selection screen
- Password recovery session: reset password screen
- Normal user session: home screen
- Admin session: admin dashboard

## Forgot Password Deep Link

The password reset email must use this redirect URL:

```text
personalutilityapp://auth/reset-password
```

The app sends reset emails with:

```dart
Supabase.instance.client.auth.resetPasswordForEmail(
  email.trim(),
  redirectTo: 'personalutilityapp://auth/reset-password',
);
```

Add this URL in Supabase:

```text
Authentication -> URL Configuration -> Additional Redirect URLs
personalutilityapp://auth/reset-password
```

Android handles the deep link in:

```text
android/app/src/main/AndroidManifest.xml
```

The `MainActivity` intent filter uses:

```xml
<data
    android:scheme="personalutilityapp"
    android:host="auth"
    android:pathPrefix="/reset-password" />
```

## Password Reset Flow

1. User enters email on login screen.
2. User taps Forgot Password.
3. Supabase sends a password reset email.
4. Email link opens the Android app through `personalutilityapp://auth/reset-password`.
5. Supabase creates a temporary password recovery session.
6. The app routes to `ResetPasswordScreen`.
7. User enters and confirms a new password.
8. The app calls `updateUser(UserAttributes(password: newPassword))`.
9. The temporary recovery session is signed out.
10. The user is sent back to login.

Expired or reused reset links are handled with a visible error message instead of crashing the app.

## Admin Roles

Admin access is controlled by the database table:

```text
public.app_admins
```

The app does not use a hardcoded admin password as the source of truth. After any successful Supabase sign-in, the app checks whether the signed-in user's `user_id` exists in `public.app_admins`.

Add or repair an admin account with:

```sql
insert into public.app_admins (user_id, email)
select id, email
from auth.users
where lower(email) = lower('admin@example.com')
on conflict (user_id) do update
set email = excluded.email;
```

Check whether an admin row exists:

```sql
select id, email
from auth.users
where lower(email) = lower('admin@example.com');

select *
from public.app_admins
where lower(email) = lower('admin@example.com');
```

Replace `admin@example.com` with the real admin email.

## User Data and RLS

Normal users can only read and write their own records through RLS:

- `business_cards.user_id = auth.uid()`
- `scan_history.user_id = auth.uid()`
- `recordings.user_id = auth.uid()`
- audio files are stored under the user's ID folder in Supabase Storage

Admins listed in `public.app_admins` can read all module data for the admin dashboard.

## Main Modules

### QR Business Cards

Users can create, edit, delete, and view business card profiles. The app can generate QR codes for saved cards.

Relevant files:

- `lib/screens/qr_card/card_list_screen.dart`
- `lib/screens/qr_card/card_form_screen.dart`
- `lib/screens/qr_card/qr_view_screen.dart`
- `lib/providers/business_card_provider.dart`
- `lib/services/database_service.dart`

### QR Scanner and Scan History

Users can scan QR codes and save scan results to their own history.

Relevant files:

- `lib/screens/qr_card/qr_scanner_screen.dart`
- `lib/screens/qr_card/scan_history_screen.dart`

### Unit Converter

A local-only converter module. It does not require Supabase storage.

Relevant files:

- `lib/screens/converter/converter_screen.dart`
- `lib/models/converter_model.dart`

### Audio Recorder

Users can record audio, upload private files to Supabase Storage, store metadata in Postgres, play recordings, edit titles/notes, and delete recordings.

Relevant files:

- `lib/screens/recorder/record_screen.dart`
- `lib/screens/recorder/recording_list_screen.dart`
- `lib/screens/recorder/playback_screen.dart`
- `lib/screens/recorder/edit_recording_screen.dart`
- `lib/providers/recording_provider.dart`
- `lib/services/audio_service.dart`
- `lib/services/database_service.dart`

### Admin Dashboard

Admins can see cross-user totals and recent activity for cards, scans, and recordings.

Relevant files:

- `lib/screens/admin/admin_dashboard_screen.dart`
- `lib/services/database_service.dart`
- `lib/providers/auth_provider.dart`

## Android Permissions

The Android manifest declares permissions for:

- Internet access for Supabase
- Camera access for QR scanning
- Microphone access for recording
- Storage/media access for audio handling on supported Android versions

Manifest path:

```text
android/app/src/main/AndroidManifest.xml
```

## App Icons

Launcher icon generation is configured in `pubspec.yaml` using:

```text
assets/icon/app_icon.png
```

Regenerate launcher icons:

```bash
dart run flutter_launcher_icons
```

## Troubleshooting

### Password reset link opens the app but shows expired

Use the newest email link only. Supabase reset links are one-time and can expire. Request a new reset email and open the latest link on the same device.

### Password reset link opens a blank browser page

Confirm this redirect URL is added in Supabase:

```text
personalutilityapp://auth/reset-password
```

Also confirm the Android manifest contains the matching `VIEW` intent filter.

### Admin login goes to the user panel

Confirm the admin account exists in `public.app_admins`:

```sql
select *
from public.app_admins
where lower(email) = lower('admin@example.com');
```

If no row exists, insert it using the admin SQL shown above.

### User login signs out immediately

Run the latest build and check logs for:

```text
Role fetched ... isAdmin=false role=user rows=0
Final navigation decision: user panel
```

Normal users do not need a row in `public.app_admins`.

## Development Notes

- Keep password reset redirect URLs consistent everywhere.
- Do not create or upsert a normal user role during password recovery.
- Do not overwrite rows in `public.app_admins` unless intentionally changing admin access.
- Keep RLS enabled on Supabase tables.
- Run `flutter analyze` and `flutter test` before release builds.

## License

This project is intended for academic and personal utility app development. Add a formal license before publishing or distributing publicly.
