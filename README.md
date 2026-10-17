# EzyHelpers — Helper Partner Mini App

A helper signs in, sees the jobs assigned to them, opens a job, and moves it forward
through `ASSIGNED → IN_PROGRESS → COMPLETED`.

Two parts, one repository:

| Folder | Stack |
| --- | --- |
| `backend/` | Python 3.12, Django 6.1, Django REST Framework, SQLite |
| `mobile/` | Flutter 3.47 (Android), Provider, http, Firebase Analytics |

All data is mock/demo data created by a seed command. No EzyHelpers systems or real
personal information are involved.

---

## Quick start

### 1. Backend

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install django djangorestframework
.venv/bin/python manage.py migrate
.venv/bin/python manage.py seed_demo
.venv/bin/python manage.py runserver 0.0.0.0:8000
```

`0.0.0.0` matters: the Android emulator reaches the host through `10.0.2.2`, which only
works if the server is not bound to `127.0.0.1` alone.

### 2. Flutter app

```bash
cd mobile
flutter pub get
flutter run           # with an emulator or device attached
```

The login screen has a collapsible **Server address** field, pre-filled with
`http://10.0.2.2:8000`. Change it to your machine's LAN IP (for example
`http://192.168.1.5:8000`) to run the APK on a physical phone.

### Demo accounts

| Username | Password | Jobs |
| --- | --- | --- |
| `asha` | `helper1234` | 4 (one of each status) |
| `ravi` | `helper1234` | 2 |
| `admin` | `helper1234` | Django admin at `/admin/` |

Two helpers exist on purpose: signing in as `ravi` shows that `asha`'s jobs are
invisible and untouchable.

---

## API

Base URL `http://localhost:8000`. Every endpoint except login needs
`Authorization: Token <token>`.

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/auth/login/` | Exchange credentials for a token |
| `GET` | `/api/jobs/` | List jobs for the signed-in helper (`?status=ASSIGNED` filters) |
| `GET` | `/api/jobs/{id}/` | Job details |
| `PATCH` | `/api/jobs/{id}/status/` | Move a job to its next status |
| `GET` | `/api/health/` | Unauthenticated health check |

### Examples

```bash
# Login
curl -X POST http://localhost:8000/api/auth/login/ \
  -H 'Content-Type: application/json' \
  -d '{"username":"asha","password":"helper1234"}'
# {"token":"a868c09...","user":{"id":1,"username":"asha","full_name":"Asha Kumari"}}

# List my jobs (paginated)
curl http://localhost:8000/api/jobs/ -H 'Authorization: Token <token>'

# Start a job
curl -X PATCH http://localhost:8000/api/jobs/1/status/ \
  -H 'Authorization: Token <token>' -H 'Content-Type: application/json' \
  -d '{"status":"IN_PROGRESS"}'

# Illegal jump is rejected
curl -X PATCH http://localhost:8000/api/jobs/1/status/ \
  -H 'Authorization: Token <token>' -H 'Content-Type: application/json' \
  -d '{"status":"COMPLETED"}'
# HTTP 400
# {"status":["Cannot move a ASSIGNED job to COMPLETED. Allowed: IN_PROGRESS."]}
```

### Error behaviour

| Situation | Response |
| --- | --- |
| Wrong credentials | `401` with `detail` |
| Missing or bad token | `401` |
| Another helper's job (read or write) | `404` — the job is simply not in your queryset |
| Illegal transition, or a status that doesn't exist | `400` with a readable message |

A `404` rather than a `403` for another helper's job is deliberate: ownership is enforced
by filtering the queryset, so the app never learns whether that id exists.

---

## Architecture

### Backend

```
backend/
├── config/            # settings, root urls
└── jobs/
    ├── models.py      # Job + ALLOWED_TRANSITIONS map
    ├── serializers.py # read serializer + a dedicated status-change serializer
    ├── views.py       # LoginView, JobViewSet (+ /status/ action)
    └── tests.py       # 10 tests
```

Two rules carry the safety requirements:

1. **Ownership** — `JobViewSet.get_queryset()` returns only `Job.objects.filter(helper=request.user)`.
   Every read and write goes through it, so there is no second place to forget the check.
2. **Transitions** — `Job.ALLOWED_TRANSITIONS` is the single source of truth, validated in
   `JobStatusUpdateSerializer`. The same map is serialised to the app as `next_statuses`,
   so the button the helper sees and the rule the server enforces cannot drift apart.

### Flutter

```
mobile/lib/
├── core/        # ApiClient, SessionStore, AnalyticsService
├── models/      # Job, JobStatus, Helper
├── state/       # AuthController, JobsController (ChangeNotifier)
├── screens/     # login, jobs list, job details
└── widgets/     # StatusChip, MessageView
```

Screens read state and never talk to HTTP directly. `JobsController` exposes an explicit
`JobsViewState` (`loading` / `ready` / `error`) plus an `isEmpty` flag, which is what drives
the four UI states. The error and empty views stay scrollable so pull-to-refresh works from
them too.

---

## Tests

```bash
cd backend && .venv/bin/python manage.py test
```

10 tests, all passing:

- login returns a token; a wrong password returns 401; an anonymous list request returns 401
- a helper's list contains only their own jobs
- reading another helper's job returns 404
- patching another helper's job returns 404 **and leaves the row unchanged**
- `ASSIGNED → IN_PROGRESS` succeeds and reports the new `next_statuses`
- `ASSIGNED → COMPLETED` (skipping a step) returns 400
- `COMPLETED → IN_PROGRESS` (reopening) returns 400
- an unknown status value returns 400

---

## Firebase Analytics

Three events are logged from `lib/core/analytics_service.dart`:

| Event | Fired when | Parameters |
| --- | --- | --- |
| `login_success` | a token is received | `username` |
| `job_viewed` | the detail screen loads a job | `job_id`, `status` |
| `job_status_updated` | a status change succeeds | `job_id`, `from_status`, `to_status` |

`AnalyticsService` is deliberately fail-soft: if Firebase is not configured on the device it
logs the event to the console and the app keeps working. Every event is also printed as
`[analytics] <name> {params}`, so the flow is verifiable with `adb logcat -s flutter`
even without the console.

### Verifying in DebugView

```bash
# 1. point the device at DebugView
adb shell setprop debug.firebase.analytics.app com.ezyhelpers.helper_partner

# 2. run the app, sign in, open a job, change its status

# 3. Firebase console -> Analytics -> DebugView
```

Turn it off again with
`adb shell setprop debug.firebase.analytics.app .none.`

---

## Known limitations and trade-offs

- **SQLite, not PostgreSQL.** The assignment allows either; SQLite keeps the reviewer's setup
  to one command. The ORM code is database-agnostic.
- **Token auth with non-expiring tokens.** DRF's built-in `TokenAuthentication` is the right
  size for a 48-hour exercise; production would want JWT with refresh and rotation.
- **The APK needs a reachable backend.** There is no hosted environment, so the login screen
  exposes the server address instead of hard-coding one. A deployment was deliberately
  skipped in favour of finishing tests and documentation.
- **The debug APK is large (~150 MB)** because a debug build ships every ABI unstripped.
- **No offline cache.** Losing connectivity shows an error state with a retry, not stale data.
- **Status changes are not optimistic.** The button shows a spinner until the server answers,
  which is slower but never shows a state the backend disagreed with.

## Completed vs deferred

**Completed:** backend with ownership and transition validation, all four endpoints, 10 tests,
three Flutter screens on real APIs, loading/empty/error states, pull-to-refresh, session
persistence, analytics events with console fallback, debug APK, feature branch and PR.

**Deferred (stretch goals, not attempted):** FCM push notifications, Crashlytics, offline
caching, CI workflow, Docker Compose. Pagination and status filtering are implemented on the
backend; the app consumes the first page only.
