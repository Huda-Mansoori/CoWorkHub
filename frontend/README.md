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

From this directory run `flutter run -d chrome` or, on Windows, `flutter run -d windows`.
The default demo shares members and resources with the management screens. Start in
Availability, choose the time and group size, check availability, and select Book.
Bookings shows confirmed and cancelled reservations and lets you edit or cancel them.
Demo changes last until you restart or reload the app.

To use the booking backend, run
`flutter run -d chrome --dart-define=COWORK_API_BASE=http://localhost:8080/api`.
The booking screens load members, resources and bookings from that base URL.
The management screens still use session data. The booking and availability
controllers are pending on the team's backend branch. The proposed contract is:

- GET `/bookings`, `/members` and `/resources` return JSON arrays.
- GET `/resources/available` accepts `startDateTime` and `endDateTime`.
- POST `/bookings` and PUT `/bookings/{id}` accept memberId, resourceId,
  startDateTime, endDateTime and attendees. Cancellation also sends status CANCELLED.
- The server assigns status and totalCost and validates availability. The client
  displays server errors and reloads the lists after successful changes.
