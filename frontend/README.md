# CoWorkHub Flutter UI

The six desktop screens share an indigo and white theme, Inter typography,
a responsive sidebar, bordered cards, forms and status badges.

## Run

Start the backend and database using the root README, then run from this folder:

```bash
flutter pub get
flutter run -d windows
```

For the browser preview, use `flutter run -d chrome`.
The default API base is `http://localhost:8080/api`. Override it with
`--dart-define=COWORK_API_BASE=http://localhost:8080/api`.
An explicitly empty value (`--dart-define=COWORK_API_BASE=`) enables the shared,
in-memory demo catalog across all screens. Demo changes last only for the session.
Normal runs use the backend and database.

## Screens and interaction

- Dashboard links to management, availability and booking workflows.
- Resources supports search, type/capacity/location/rate filters, and validated
  add/edit/delete actions. Desk capacity is fixed at one attendee.
- Members supports search, add/edit/delete actions and a booking history dialog
  backed by `GET /bookings/member/{id}`.
- Availability checks a date/time range and attendee count. Wide layouts show
  resource cards beside a booking form. Compact layouts open New Booking.
- New Booking supports creation and editing. The member stays fixed when editing.
- Bookings shows member filtering, status, date/time, cost, editing and cancellation.
  Cancellation preserves history and refreshes the list.

Lists include loading, empty, error/retry and loaded states. Forms keep entered
values after server errors, show field validation, and prevent duplicate saves.
Destructive actions require confirmation, with the safe action focused first.
Cancel appears before Save. Status is communicated through text and color.
Content scrolls in short windows and switches to compact cards/forms when needed.

Keyboard support includes Tab navigation, Ctrl/Cmd+F for management search,
Ctrl/Cmd+S or Enter to submit an editor, and Escape to close or discard an editor.
The room and desk photographs are bundled illustrative assets, not uploaded
resource photos. The bundled Inter font includes its OFL license.

## API contract

- GET `/bookings`, `/members` and `/resources` return JSON arrays.
- GET `/resources/available` accepts `start` and `end`.
- GET `/bookings/member/{id}` returns a member's booking history.
- POST `/bookings` and PUT `/bookings/{id}` send `memberId`, `resourceId`,
  `startDateTime`, `endDateTime` and `attendees`.
- Cancellation sends `status: CANCELLED` through the booking update endpoint.
- The server validates availability and calculates the final cost.

## Verification

```bash
flutter analyze
flutter test
flutter build web --no-pub --no-web-resources-cdn
```

The 18 automated tests cover HTTP contracts, history, booking creation/update/
cancellation, validation, filters, retry, pending saves, keyboard interaction,
all six compact screens, and larger text in a short window. They use demo data
or mock HTTP clients and do not require a running backend.

The redesign was also checked against the local Docker backend and MySQL.
Live browser checks covered member/resource creation, member history, availability,
booking creation, editing and cancellation, plus compact layouts. Native Windows
packaging still needs verification on a Windows machine.
