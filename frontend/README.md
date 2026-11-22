# CoWorkHub Flutter frontend

The client uses the Lab 8/9 structure: models map JSON, services perform HTTP,
StatefulWidget pages own mutable state, and small StatelessWidgets display data
and invoke callbacks. The backend and REST contract are unchanged.

## Run and verify

From the repository root, start the backend and database:

```bash
docker compose up --build
```

In another terminal:

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Windows requires the native Windows Flutter toolchain. On this Mac the web build
and live browser/API workflows were verified; native Windows packaging must be
checked on Windows. For a local browser run, use `flutter run -d chrome`.

The base URL is defined only in `lib/services/api_config.dart` and defaults to
`http://localhost:8080/api`. Override it using
`--dart-define=COWORK_API_BASE=http://localhost:8080/api`.
There is no application demo mode. Tests use MockClient from the existing http
package and need no backend. No pubspec dependency, font or asset change is required.

## Folder responsibilities

- `models/resource.dart`: base Resource, MeetingRoom and Desk. Subtypes are detected
  from deskType or projector/videoConference, with no invented type discriminator.
  Some nested booking resources arrive with common fields only. Those remain a
  base Resource; the resource list supplies the full subtype for editing.
- `models/member.dart`: fullName and email response/request mapping.
- `models/booking.dart`: nested member/resource response mapping and request IDs.
  toJson excludes ID, totalCost and status. The cancellation service adds CANCELLED.
- `services/`: explicit fetchAll/create/update/delete and booking operations.
  An optional http.Client supports mock tests. Services close clients they own.
- `screens/`: load methods and action handlers, using initState, await, mounted,
  setState, validators, loading/error/empty/list feedback and refresh after mutations.
- `widgets/`: cards, booking form, time controls, booking list and shared presentation.
- `theme/app_theme.dart`: unchanged visual theme, with a responsibility comment.
- `main.dart`: runApp, MaterialApp and Dashboard.

The Dashboard passes resource/time details to New Booking, and a Booking to edit.
IndexedStack retains the three booking pages while switching between them.
The activated Bookings page reloads so saved/cancelled data is current.
Resources search remains local filtering of the loaded list. Availability sends
start/end to the backend, then filters the returned resources by attendee capacity.

## Files removed and moved

- Deleted `lib/services/demo_catalog.dart` and every demo branch.
- Replaced `lib/screens/booking_workspace.dart` with `availability.dart`,
  `new_booking.dart` and `bookings.dart`.
- Moved Resource and Member out of `models/booking.dart` into their own files.
  Reservation is removed; Booking.toJson supplies the request body.
- Moved DashboardHome to `screens/dashboard_home.dart`.
- Moved ResourceEditor and MemberEditor into separate dialog files.
- Added presentation widgets for booking fields, time buttons, resource summary,
  availability results and wide/compact booking lists.
- API class names remain BookingApi, ResourceApi and MemberApi. Method names now
  follow fetchAll/create/update/delete, plus fetchAvailable/fetchByMember/cancel.

## Verification results

44 automated tests passed, Flutter analysis reported no issues, and the release
web build passed. Tests cover typed JSON, subtype detection, request bodies,
expected status codes, empty 204 handling, 409 messages, history states/retry,
booking rendering/cancellation/update/create, validation, management search,
pending-save guards, keyboard submission and compact large-text scrolling.

Live Dart services were exercised against Docker/MySQL for room/desk CRUD,
member CRUD, availability, booking create/update/conflict/cancellation, nested
booking lists and member-specific history. The refactored member-history dialog
also loaded real history successfully in the browser.
