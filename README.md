# Planner — Tasks, Habits & Goals

A Flutter app that unifies daily tasks, habit streaks, and long-term goals into one Material 3 dashboard, backed by Supabase (Auth + Postgres) and deployed as a PWA on Vercel.

See [`PRD.md`](./PRD.md) for the full product spec and [`supabase/schema.sql`](./supabase/schema.sql) for the database schema.

> **A note on how this codebase was produced:** the app's Dart source, Supabase schema, and web/PWA assets in this repo were hand-authored and are ready to run — but they haven't been compiled here, because this build environment has no network path to `storage.googleapis.com`, which is where the Flutter/Dart SDK's engine artifacts are hosted, and no shell access on your machine either. That means `flutter pub get` / `flutter run` / `flutter build web` need to be run **by you, locally**, where Flutter is already installed. The steps below are exact — follow them in order and everything should build cleanly. If `flutter analyze` turns up anything, it'll be minor (an import order nit, a version-specific API tweak) rather than a structural issue.

## 1. Prerequisites

- Flutter SDK (stable channel, 3.24+) — `flutter doctor` should show no blocking issues for Android + Web.
- A free [Supabase](https://supabase.com) project.
- A [Google Cloud](https://console.cloud.google.com) OAuth client (for Google Sign-In).
- A [Vercel](https://vercel.com) account, and a [GitHub](https://github.com) account for the public repo.

## 2. Set up Supabase

1. Create a new Supabase project.
2. Open **SQL Editor** and run the contents of [`supabase/schema.sql`](./supabase/schema.sql). This creates `profiles`, `tasks`, `habits`, `habit_logs`, `goals`, `goal_milestones` — all with Row Level Security scoped to `auth.uid()` — plus a trigger that auto-creates a profile on first sign-in.
3. Go to **Authentication → Providers → Google**, enable it, and fill in the OAuth **Client ID** and **Client Secret** from a Google Cloud OAuth 2.0 Client (Web application type; see step 3).
4. Go to **Authentication → URL Configuration** and add these **Redirect URLs**:
   - Your local dev URL, e.g. `http://localhost:PORT` (Flutter prints the port when you `flutter run -d chrome`)
   - Your production Vercel URL once you have it, e.g. `https://your-app.vercel.app`
   - `io.nahid.tasktracker://login-callback` (for the Android build)
5. Copy your **Project URL** and **anon public key** from **Project Settings → API** — you'll pass these in as `--dart-define` values, never hard-code them into source (see §5 and §6).

## 3. Set up Google OAuth

1. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials), create an OAuth 2.0 Client ID of type **Web application**.
2. Add your Supabase project's callback URL as an **Authorized redirect URI** — it's shown on the Google provider settings page in Supabase, typically `https://<project-ref>.supabase.co/auth/v1/callback`.
3. Paste the generated **Client ID** and **Client Secret** into the Supabase Google provider settings from step 2.4 above.

## 4. Generate the native platform folders

This repo ships the Dart source (`lib/`), `pubspec.yaml`, and a hand-built `web/` (already PWA-ready with icons + manifest). It intentionally does **not** ship an `android/` folder, because that folder is large, generated boilerplate that must match your exact local Flutter SDK version — generating it here risked shipping one that doesn't match yours and fails to build. Generate it yourself, once:

```bash
cd task-tracker-app
flutter create --org com.nahid.tasktracker --project-name task_tracker_app --platforms=android /tmp/planner_scaffold
cp -r /tmp/planner_scaffold/android ./android
rm -rf /tmp/planner_scaffold
```

This only touches the new `android/` folder — your existing `pubspec.yaml`, `lib/`, and `web/` are untouched.

### Enable the OAuth deep link on Android

Open `android/app/src/main/AndroidManifest.xml`, and inside the `<activity>` block for `MainActivity`, add:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.nahid.tasktracker" android:host="login-callback" />
</intent-filter>
```

## 5. Run it locally

```bash
flutter pub get

# Web
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY

# Android (device/emulator connected)
flutter run -d android \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

Tip: to avoid retyping the defines, create a gitignored `supabase.env.json`:

```json
{
  "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR-ANON-KEY"
}
```

then run with `flutter run --dart-define-from-file=supabase.env.json` (this file is already covered by `.gitignore`... add `supabase.env.json` there too if you create it, it isn't listed by name).

## 6. Push to GitHub (public repo)

```bash
git init
git add .
git commit -m "Initial commit: Planner app"
gh repo create task-tracker-app --public --source=. --remote=origin --push
# or, without the GitHub CLI:
#   git remote add origin https://github.com/<you>/task-tracker-app.git
#   git branch -M main
#   git push -u origin main
```

## 7. Deploy the web build to Vercel

This repo includes `vercel.json` and `vercel-build.sh`. Since Vercel's build machines (unlike this dev sandbox) have normal internet access, `vercel-build.sh` clones the Flutter SDK during the build and runs `flutter build web --release`, so **you don't need to build web locally** before deploying — Vercel does it.

1. In Vercel, **Add New Project** → import the GitHub repo you just pushed.
2. Framework preset: **Other**. Vercel will pick up `vercel.json` (build command `./vercel-build.sh`, output directory `build/web`).
3. Under **Environment Variables**, add:
   - `SUPABASE_URL` = your Supabase project URL
   - `SUPABASE_ANON_KEY` = your Supabase anon public key
4. Deploy. First build takes a few minutes (cloning Flutter); subsequent builds are cached by Vercel.
5. Once live, copy the Vercel URL back into Supabase's **Redirect URLs** (§2.4) so Google Sign-In works in production, and into the Google Cloud OAuth client's **Authorized JavaScript origins**.
6. Open the deployed URL on a phone or desktop Chrome and use the browser's "Install app" / "Add to Home Screen" option — the app is a full PWA (`web/manifest.json` + Flutter's auto-generated service worker).

## 8. Project structure

```
lib/
  core/          # theme, router, constants, Supabase config, date utils
  models/        # TaskModel, HabitModel, GoalModel, ProfileModel
  services/      # Supabase-backed data access (one per module)
  providers/     # Riverpod state: auth, tasks, habits, goals
  screens/       # splash, auth, shell (bottom nav), home, tasks, habits,
                 # goals, analytics, profile
  widgets/common/# progress ring, stat card, chips, empty state, avatar
supabase/
  schema.sql     # full DB schema + RLS policies + new-user trigger
web/             # PWA: manifest.json, icons, index.html
PRD.md
```

## 9. What's deliberately out of scope for v1

See PRD §2.2 — no push notifications, no offline write queue, no team/sharing features, no iOS build, no email/password auth. These are documented as fast-follows, not oversights.
