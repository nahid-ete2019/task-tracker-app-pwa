# Product Requirements Document
## Planner — Tasks, Habits & Goals

**Author:** Md. Nahid Hasan
**Date:** September 22, 2026
**Status:** v1.0 — Approved for build
**Platforms:** Flutter (Web PWA + Android)
**Backend:** Supabase (Auth + Postgres)
**Deployment:** Vercel (web), GitHub (public repo)

---

## 1. Summary

Planner is a single-user productivity app that unifies three things people normally track in separate apps — **daily tasks, recurring habits, and long-term goals** — into one clean, Material 3 dashboard. It ships as a Flutter codebase that builds to a Progressive Web App (deployed on Vercel) and to Android, backed by Supabase for authentication and data sync.

The product's job: let a user open one app in the morning, see exactly what's due today, check off tasks, log habit streaks, and glance at how their longer-term goals are progressing — with data safely synced to their account via Google Sign-In.

## 2. Goals & Non-Goals

### 2.1 Goals (v1)
- One account (Google Sign-In via Supabase Auth), all data scoped to that user.
- Full CRUD on Tasks, Habits, and Goals.
- A home dashboard that summarizes today's state at a glance (reference: attached "Modern Dashboard App" UI kit).
- Habit streak tracking (daily check-off + current streak).
- Goal progress tracking (manual progress % and/or milestone checklist).
- A lightweight Analytics screen (productivity score, task completion trend, category breakdown).
- Clean, minimal Material 3 UI — light theme first.
- Installable PWA (manifest + service worker, "Add to Home Screen").
- Public GitHub repo; automatic web deploy to Vercel.

### 2.2 Non-Goals (v1 — explicitly deferred)
- Multi-user collaboration / sharing tasks or goals with others.
- Push notifications / reminders (local notifications may be a fast-follow).
- Offline-first conflict resolution (basic offline read cache is fine; write requires connectivity).
- Dark mode (structured in the theme layer, but not polished/shipped in v1).
- iOS build (Android + Web only per current scope).
- Email/password auth (Google Sign-In only).

## 3. Reference Design

The attached UI kit ("Modern Dashboard App UI/UX Design — Productivity & Analytics App") is the visual reference for tone and layout: soft lavender/white backgrounds, an indigo/violet primary color, rounded 16–20px cards, circular progress rings, a 5-tab bottom nav with a raised center action button, and colour-coded priority/category chips. Planner adapts this reference to its own three-module structure (Tasks / Habits / Goals) rather than copying it screen-for-screen.

## 4. User & Problem

**User:** Nahid — a working professional who currently splits tasks, habit tracking, and goal-setting across separate tools/notes. He wants one place that's fast to open, clear at a glance, and reliably synced.

**Problem:** Task lists show *what* to do, habit trackers show *consistency*, and goal trackers show *progress toward outcomes* — but none of them show how those three relate on a single day. Planner's dashboard is the answer to "what does today look like, across everything I'm tracking?"

## 5. Information Architecture

```
Splash → (auth check) → Login (Google) → Main Shell
                                             ├── Home (Dashboard)
                                             ├── Tasks
                                             ├── Habits
                                             ├── Goals
                                             ├── Analytics
                                             └── Profile
```

Bottom navigation: **Home · Tasks · (+ Add) · Habits/Goals via tabs on a Planner tab · Profile.** Given three core modules plus analytics and profile, the v1 nav is 5 items: **Home, Tasks, Habits, Goals, Profile**, with a floating "+" action that opens a quick-add sheet (choose Task / Habit / Goal) and Analytics reachable from the Home app bar.

## 6. Functional Requirements

### 6.1 Authentication
- FR-1: User signs in with Google via Supabase Auth (`signInWithOAuth`).
- FR-2: On first sign-in, a `profiles` row is auto-created (DB trigger) from the Google identity (name, avatar, email).
- FR-3: Session persists across app restarts (Supabase local session persistence).
- FR-4: Sign-out available from Profile; clears local session and returns to Login.
- FR-5: All data reads/writes are scoped to the signed-in user via Postgres Row Level Security — no user can see another user's rows, enforced at the database, not just the client.

### 6.2 Tasks
- FR-6: Create a task with title (required), description, category, priority (Low/Medium/High), due date/time, status (To Do/In Progress/Completed).
- FR-7: List view with filter tabs: All / Today / Upcoming / Completed, matching the reference "My Tasks" screen.
- FR-8: Toggle completion from the list (checkbox) without opening the detail view.
- FR-9: Edit and delete existing tasks.
- FR-10: Sort by due date by default; overdue tasks are visually flagged.
- FR-11: Search/filter tasks by keyword and category.

### 6.3 Habits
- FR-12: Create a habit with title, icon/color, frequency (Daily / specific weekdays), and an optional target count per period.
- FR-13: "Check off" a habit for today from the Habits list; this writes a `habit_logs` row for that date (idempotent — one log per habit per day).
- FR-14: Each habit shows current streak (consecutive completed days) and completion rate.
- FR-15: Edit and delete habits (deleting a habit removes its logs via cascade).
- FR-16: Home dashboard surfaces today's incomplete habits as quick-check items.

### 6.4 Goals
- FR-17: Create a goal with title, description, category, target date, and an icon/color.
- FR-18: Track progress via a milestone checklist (e.g., "Learn New Skills — 3/5 completed"); progress % is derived from completed/total milestones, or set manually if no milestones exist.
- FR-19: Goals list groups by status: Active / Completed.
- FR-20: Edit and delete goals (and their milestones, via cascade).

### 6.5 Home Dashboard
- FR-21: Greeting header with user's name/avatar and current date.
- FR-22: "Daily Progress" ring showing tasks completed today / total tasks due today.
- FR-23: Stat cards: Total Tasks, In Progress, Completed, Overdue (today's counts).
- FR-24: Quick Actions row: Add Task, Add Habit, Add Goal, Open Analytics.
- FR-25: "Today's Tasks" preview list (top 3–5, tap to see all).
- FR-26: "Today's Habits" quick-check row.

### 6.6 Analytics
- FR-27: Productivity score (ring) — % of today's/this-week's tasks completed.
- FR-28: Task completion trend — last 7 days, line/bar chart.
- FR-29: Category breakdown — donut chart of open tasks by category.
- FR-30: Habit consistency — completion rate per habit over last 30 days.

### 6.7 Profile
- FR-31: Show name, email, avatar, and summary counts (tasks, goals, current best streak).
- FR-32: Sign out.
- FR-33: App info (version) and a placeholder Settings entry (theme, notifications — disabled/"coming soon" in v1).

## 7. Data Model (Supabase / Postgres)

| Table | Purpose | Key columns |
|---|---|---|
| `profiles` | 1 row per user | `id (uuid, = auth.users.id)`, `full_name`, `avatar_url`, `email`, `created_at` |
| `tasks` | User's tasks | `id`, `user_id`, `title`, `description`, `category`, `priority`, `status`, `due_date`, `created_at`, `updated_at` |
| `habits` | User's habits | `id`, `user_id`, `title`, `icon`, `color`, `frequency`, `target_per_period`, `created_at` |
| `habit_logs` | Daily completions | `id`, `habit_id`, `user_id`, `completed_date`, `created_at` — unique on `(habit_id, completed_date)` |
| `goals` | User's goals | `id`, `user_id`, `title`, `description`, `category`, `icon`, `color`, `target_date`, `status`, `manual_progress`, `created_at` |
| `goal_milestones` | Goal sub-steps | `id`, `goal_id`, `user_id`, `title`, `is_completed`, `created_at` |

All tables: `user_id` references `auth.users(id)`, RLS enabled, policy `user_id = auth.uid()` for select/insert/update/delete. See `supabase/schema.sql` for full DDL.

## 8. Non-Functional Requirements

- NFR-1: Cold start under ~2s on a modern laptop for the web build.
- NFR-2: Responsive layout — usable from a 360px-wide phone browser up to desktop width (web is a "first-class" target since Android is the secondary platform in this phase).
- NFR-3: All Supabase calls go through a typed service layer (no raw Supabase calls scattered in widgets), so the backend could be swapped later without a UI rewrite.
- NFR-4: State managed via Riverpod; UI is a pure function of state (no business logic in widgets).
- NFR-5: Installable as a PWA — manifest, icons, `display: standalone`, theme color matching the app's primary color.
- NFR-6: Public GitHub repo with a clear README (setup, run, build, deploy).

## 9. Tech Stack

- **Framework:** Flutter (stable channel), Dart 3.
- **State management:** `flutter_riverpod`.
- **Routing:** `go_router` (auth-aware redirects).
- **Backend/Auth/DB:** `supabase_flutter` (Postgres + Row Level Security + Google OAuth).
- **Charts:** `fl_chart` for Analytics.
- **Design system:** Material 3 (`useMaterial3: true`), custom `ColorScheme` derived from the reference UI's indigo/violet palette.
- **Deployment:** `flutter build web` → static output deployed to **Vercel**; **GitHub** as the public source repo (Vercel's GitHub integration auto-deploys on push).

## 10. Success Criteria (v1 "done")

1. A new user can sign in with Google and land on an empty-state dashboard within a few seconds.
2. They can create at least one task, one habit, and one goal, and see all three reflected correctly on the Home dashboard and Analytics.
3. Data persists across sessions/devices under the same Google account (verified by signing in on web and Android with the same account).
4. `flutter build web` output is live on a public Vercel URL, installable as a PWA.
5. Source is pushed to a public GitHub repository with a working README.

## 11. Open Questions / Assumptions Made

- **Assumption:** Single-tenant per user (no shared/team planning) — confirmed out of scope for v1.
- **Assumption:** Notifications/reminders are out of scope for v1 (flagged as fast-follow).
- **Assumption:** Habit "frequency" beyond daily (e.g., 3x/week) is modeled but the v1 UI primarily surfaces daily check-offs; weekly-target habits still work via `target_per_period`.
- **Open:** Whether Goals need nested milestones in v1 or a simple manual progress slider is sufficient — v1 ships both (milestones optional; manual progress used when a goal has none), so the reference screen's "3/5 completed" pattern and a simpler goal both work.
