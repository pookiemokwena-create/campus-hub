# NCV Companion

Offline-first Flutter app for South African TVET **NCV Level 2–4** students.

1. **ICASS & exam calculator**: task-based ICASS, DHET sub-minimums, real-time pass check.
2. **Past paper hub**: NQF → stream → subject → year filters, offline PDF downloads, reader with zoom and page jump.
3. **AI Tutor**: chat through a Supabase Edge Function. The API key stays on the server, and the daily quota is enforced in Postgres.

Stack: Flutter (Dart 3), Riverpod (`flutter_riverpod` + `riverpod_annotation`), `go_router` with auth guards, `supabase_flutter` (Auth, Postgres, Storage, Edge Functions), `hive_ce` for local storage, `connectivity_plus`, `flutter_pdfview` + `path_provider`. Dark theme by default.

## Setup

```bash
# 1. Flutter >= 3.44 (Dart >= 3.12)
flutter pub get

# 2. Generate Riverpod providers (*.g.dart files are not committed)
dart run build_runner build --delete-conflicting-outputs

# 3. Configure Supabase
cp config/env.example.json config/env.json   # fill in URL and anon key

# 4. Run
flutter run --dart-define-from-file=config/env.json

# 5. Tests
flutter test
```

### Supabase

```bash
supabase link --project-ref <ref>
supabase db push                       # schema, RLS, triggers, quota functions, bucket
supabase db reset                      # local dev only: applies migrations + supabase/seed.sql
# Remote: paste supabase/seed.sql into the SQL editor (sample subjects; replace with the official list)
supabase secrets set GEMINI_API_KEY=... AI_MODEL=gemini-2.5-flash
supabase functions deploy ai-tutor
```

Upload past papers to the **private** `past-papers` bucket, then insert matching `past_papers` rows, where `file_url` is the object path.

## Architecture

```
UI (features/*/presentation)
  └─ Riverpod providers (features/*/providers, core/providers)
       └─ Repositories (features/*/data)  ── remoteFirst(): remote, else Hive
            ├─ Supabase (Auth, Postgrest, Storage, Functions)
            └─ LocalStorage (Hive CE boxes, JSON strings, dirty flags)
SyncCoordinator: pushes dirty rows when online (sign-in, reconnect, debounced edit, pull-to-refresh)
```

Offline rules:

- Every write goes to Hive first, then syncs later.
- `connectivity_plus` says whether an interface is up. A request failure also counts as offline.
- ICASS: last-write-wins by `updated_at`, and dirty local records are never overwritten by pulls.
- Local data is keyed by user id, so sign-out does not expose another learner's marks.
- The router guard reads the persisted Supabase session, so returning students open the app offline.

## Assessment rules (ICASS)

| Subject group | ICASS weight | Exam weight | Sub-minimum (`subjects.pass_percentage`) |
|---|---|---|---|
| Fundamental: Maths / Maths Literacy | 25% | 75% | 30% |
| Fundamental: Life Orientation, First Additional Language | 25% | 75% | 40% |
| Vocational | 50% | 50% | 50% |

ICASS and the external exam must each meet the sub-minimum in the same academic year. The required exam mark is `max(pass, (pass − ICASS × w_icass) / w_exam)`, capped at 100. Rules come from DHET NC(V) ICASS guidelines. Verify against the current year's circular before relying on them.

## Project structure

```
ncv_companion/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── config/
│   └── env.example.json                 # copy to env.json (git-ignored)
├── lib/
│   ├── main.dart                        # boot: Hive → Supabase → ProviderScope
│   ├── app.dart                         # MaterialApp.router, dark theme
│   ├── core/
│   │   ├── config/                      # env.dart, app_constants.dart, vocational_streams.dart
│   │   ├── theme/app_theme.dart         # Material 3 dark theme
│   │   ├── router/                      # app_routes, app_router (auth guard), router_refresh
│   │   ├── services/                    # supabase_service, local_storage (Hive), connectivity_service
│   │   ├── sync/sync_coordinator.dart   # offline → online flush of dirty rows
│   │   ├── models/                      # profile.dart, subject.dart
│   │   ├── data/subjects_repository.dart
│   │   ├── providers/catalog_providers.dart
│   │   ├── utils/                       # errors, remote_first, format, ids
│   │   └── widgets/                     # app_shell, offline_banner, status_views, labeled_dropdown
│   └── features/
│       ├── auth/                        # email/password, signup with NQF level + stream
│       │   ├── data/auth_repository.dart
│       │   ├── providers/auth_providers.dart
│       │   └── presentation/auth_screen.dart
│       ├── dashboard/presentation/dashboard_screen.dart
│       ├── icass/
│       │   ├── models/                  # icass_task.dart, icass_record.dart
│       │   ├── domain/icass_calculator.dart   # pure rules, unit tested
│       │   ├── data/icass_repository.dart
│       │   ├── providers/icass_providers.dart
│       │   └── presentation/            # calculator screen + widgets/
│       ├── past_papers/
│       │   ├── models/                  # past_paper.dart, download_record.dart
│       │   ├── data/                    # past_papers_repository, paper_download_service
│       │   ├── providers/               # past_paper_providers, downloads_providers
│       │   └── presentation/            # library, pdf_reader_screen, widgets/
│       └── ai_tutor/
│           ├── models/chat_message.dart
│           ├── data/ai_tutor_repository.dart
│           ├── providers/ai_tutor_providers.dart
│           └── presentation/            # ai_tutor_screen + widgets/
├── supabase/
│   ├── migrations/20261020000000_ncv_companion_schema.sql
│   ├── seed.sql
│   └── functions/ai-tutor/index.ts      # quota → LLM proxy → refund on failure
└── test/
    └── icass_calculator_test.dart
```

## Data model

| Table | Key columns |
|---|---|
| `profiles` | `id` (auth user), `full_name`, `college_name`, `nqf_level` (2–4), `vocational_stream`, `daily_ai_queries`, `ai_quota_date` |
| `subjects` | `id`, `code`, `title`, `nqf_level`, `is_fundamental`, `pass_percentage` (30/40/50), `vocational_stream` |
| `student_icass` | `id`, `user_id`, `subject_id`, `task_scores` (jsonb), `icass_percentage`, `target_exam_score`, `updated_at` |
| `past_papers` | `id`, `subject_id`, `year`, `paper_number`, `file_url` (storage path), `is_memo` |

RLS: learners read their own profile and ICASS rows, and read subjects and papers. Writes to catalogue tables use the service role. The quota counter is server-owned: the client has no column grant on it.

## Known limitations

- The Dart code was written without a Flutter SDK in the build environment. Run `flutter analyze` and `dart run build_runner build` before the first build, and fix any issues it reports.
- The seed subjects are a development sample. Replace them with the official NC(V) list.
- The AI model name and quota limit are configuration values. Check the provider's current pricing and terms.
