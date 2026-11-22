# CoWorkHub

## Coworking Space & Meeting Room Booking System

CoWorkHub is a desktop application for managing coworking resources,
members, availability, and bookings. The project uses a Flutter desktop
client connected to a Spring Boot REST API and a MySQL database.

## Technology Stack

-   **Frontend:** Flutter and Dart (desktop)
-   **Backend:** Java 21, Spring Boot, Spring Data JPA / Hibernate
-   **Database:** MySQL 8
-   **Communication:** REST API using JSON over HTTP
-   **Deployment:** Docker Compose

## Project Structure

``` text
CoWorkHub/
├── backend/                 # Spring Boot application
├── frontend/                # Flutter desktop application
├── docs/
│   └── erd/Diagrams/        # Database and ERD documentation
├── docker-compose.yml       # MySQL and backend services
├── .env.example             # Environment variable template
├── .gitignore
└── README.md
```

## Prerequisites

Install the following tools before running the project:

-   Git
-   Docker Desktop with Docker Compose
-   Flutter SDK (including the Windows desktop toolchain if running on
    Windows)
-   Java 21 (for running or testing the backend outside Docker)
-   A code editor such as Visual Studio Code

Check your installations:

``` bash
docker --version
docker compose version
flutter --version
java -version
```

## 1. Get the Project

Clone the repository:

``` bash
git clone https://github.com/Huda-Mansoori/CoWorkHub.git
cd CoWorkHub
```

## 2. Configure Environment Variables

Create a local `.env` file from the example:

**Windows PowerShell**

``` powershell
Copy-Item .env.example .env
```

**macOS / Linux**

``` bash
cp .env.example .env
```

Open `.env` and review the values. Set the database name, database
username, database password, and any backend database connection
settings required by the Compose configuration.

The `.env.example` file contains placeholders only. Use your own local
values in `.env`; do not commit `.env` or real credentials to GitHub.

## 3. Start the Backend and Database with Docker

From the project root (the folder containing `docker-compose.yml`), run:

``` bash
docker compose up --build
```

This starts the MySQL database and builds/runs the Spring Boot backend.
The database uses a persistent Docker volume so its data remains
available when containers are restarted.

Wait until the database is healthy and the backend has finished
starting.

The backend API is configured for:

``` text
http://localhost:8080/api
```

The MySQL container is exposed on host port `3307` (container port
`3306`) in the supplied Compose setup.

To view running containers:

``` bash
docker compose ps
```

To view backend logs:

``` bash
docker compose logs -f backend
```

To stop the services without deleting the database volume:

``` bash
docker compose down
```

**Do not use `docker compose down -v` unless you intentionally want to
delete the persistent database data.**

## 4. Run the Flutter Desktop Application

Keep Docker Compose running. Open a second terminal and move to the
frontend folder:

``` bash
cd frontend
```

Get the Flutter dependencies:

``` bash
flutter pub get
```

Run the desktop application on Windows:

``` bash
flutter run -d windows
```

If you are using another desktop platform, first enable that Flutter
desktop target and use its device name with `flutter run -d`.

The Flutter application connects to the backend at
`http://localhost:8080/api` by default. To use a different API address,
provide the `COWORK_API_BASE` Dart define when launching the app:

``` bash
flutter run -d windows --dart-define=COWORK_API_BASE=http://localhost:8080/api
```

## 5. Run Tests and Code Checks

### Backend tests

From the backend folder:

**Windows PowerShell**

``` powershell
cd backend
.\mvnw.cmd clean test
```

**macOS / Linux**

``` bash
cd backend
./mvnw clean test
```

If the Maven wrapper is unavailable, use an installed Maven version:

``` bash
mvn clean test
```

### Flutter analysis and widget tests

From the frontend folder:

``` bash
flutter analyze
flutter test
```

The Flutter tests use MockClient HTTP responses so they do not require a
running backend or make real network requests. Application screens always use
the configured backend services.

## 6. Main Application Features

-   View and manage coworking resources, including desks and meeting
    rooms.
-   View and manage members.
-   Check resource availability for a selected time period and attendee
    count.
-   Create and manage bookings.
-   Cancel existing bookings.
-   Validate booking details, including resource capacity and desk
    attendee limits.
-   Prevent conflicting bookings for the same resource and time.
-   Calculate booking costs using the resource hourly rate.

## 7. Backend API

The backend API base URL is:

``` text
http://localhost:8080/api
```

The main API areas include:

  Area                       Endpoint examples
  -------------------------- ----------------------------
  Resources                  `GET /resources`
  Available resources        `GET /resources/available`
  Members                    `GET /members`
  Bookings                   `GET /bookings`
  Create booking             `POST /bookings`
  Update or cancel booking   `PUT /bookings/{id}`

For availability checks, the endpoint accepts `start` and `end` query
parameters. Booking requests include the member ID, resource ID, start
and end date-time, and attendee count.

## 8. Troubleshooting

### Backend is not reachable

-   Confirm Docker Desktop is running.
-   Check the containers with `docker compose ps`.
-   Review backend logs with `docker compose logs -f backend`.
-   Confirm that port `8080` is not being used by another process.

### Database connection fails

-   Confirm the MySQL container is healthy.
-   Check the database settings in `.env` against the Compose
    configuration.
-   Check database logs with `docker compose logs -f db`.

### Flutter cannot connect to the backend

-   Make sure the backend container has finished starting.
-   Confirm the API address is `http://localhost:8080/api`.
-   If needed, launch Flutter with the `COWORK_API_BASE` define shown
    above.

### Flutter desktop target is unavailable

Run:

``` bash
flutter doctor
flutter devices
```

Follow Flutter Doctor's instructions to install the desktop build tools
for your operating system.


## Contributors

CoWorkHub was developed as a group project under INFS4102 - Desktop Application Development. 

Group members:
- Huda M.
- Amanda H.
- Asma D. A.
- Mera S.


------------------------------------------------------------------------

**Repository:** https://github.com/Huda-Mansoori/CoWorkHub
