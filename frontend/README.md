# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Booking workflow

Run `flutter run -d chrome` or `flutter run -d windows` from this directory.
All screens now target `http://localhost:8080/api` by default.
Start the backend and database using the root README instructions.

The Members and Resources screens include Member 3's latest HTTP integration.
Booking screens load members, resources and bookings from the API, and support
availability search, create, update and cancellation. Booking and availability
controllers are still pending in the remote backend branches checked on November 14,
2026. Until those exist, the booking screens show the API error and a Retry button.

The booking HTTP contract follows the project brief:

- GET `/bookings`, `/members` and `/resources` return JSON arrays.
- GET `/resources/available` accepts `startDateTime` and `endDateTime`.
- POST `/bookings` and PUT `/bookings/{id}` accept memberId, resourceId,
  startDateTime, endDateTime and attendees. Cancellation also sends status CANCELLED.
- The server assigns status and totalCost and validates availability.

Override the booking API base with
`--dart-define=COWORK_API_BASE=http://localhost:8080/api`.
For an offline booking demo, explicitly pass `--dart-define=COWORK_API_BASE=`.
Demo data is temporary. The Members and Resources management screens use the API.

Run the offline booking tests with
`flutter test --dart-define=COWORK_API_BASE=`.
