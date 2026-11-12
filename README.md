# CoWorkHub
## Coworking Space & Meeting Room Booking System

CoWorkHub is a desktop application designed to manage coworking spaces, desks, meeting rooms, members, and bookings. It provides a centralized platform for managing resources and booking activities.

## 1. Project Overview

The system allows users to:
- View and manage coworking resources.
- Add, update, and delete desks and meeting rooms.
- Register and manage members.
- Check resource availability.
- Create, update, and cancel bookings.
- Calculate booking costs.
- Prevent overlapping confirmed bookings.

## 2. Technologies Used

| Component | Technology |
|---|---|
| Frontend | Flutter Desktop (Dart) |
| Backend | Java 21, Spring Boot |
| Database | MySQL 8.0 |
| ORM | Spring Data JPA / Hibernate |
| API | REST API (JSON) |
| Containerization | Docker and Docker Compose |
| Version Control | Git and GitHub |

## 3. Project Architecture

The application follows a layered architecture:

1. **Presentation Layer:** Flutter desktop application.
2. **API Layer:** Spring Boot REST controllers.
3. **Service Layer:** Business logic and validation.
4. **Repository Layer:** Database operations using Spring Data JPA.
5. **Database Layer:** MySQL relational database.

Flutter communicates with the Spring Boot backend through HTTP requests using JSON.

## 4. Project Structure

```text
CoWorkHub/
│
├── backend/
│   ├── src/
│   │   └── main/
│   │       ├── java/
│   │       └── resources/
│   ├── Dockerfile
│   ├── pom.xml
│   └── mvnw
│
├── frontend/
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   └── services/
│   └── pubspec.yaml
│
├── docs/
│   └── erd/
│
├── .env.example
├── docker-compose.yml
├── .gitignore
└── README.md
```

## 5. Prerequisites

Install the following before running the project:

- Git
- Docker Desktop
- Flutter SDK
- Java 21 (for local backend development)
- Visual Studio with Desktop development with C++ workload (for Windows Flutter desktop builds)

## 6. Running the Project with Docker

Docker Compose runs the Spring Boot backend and MySQL database.

### Step 1: Clone the repository

```bash
git clone https://github.com/Huda-Mansoori/CoWorkHub.git
cd CoWorkHub
```

### Step 2: Create the environment file

Copy `.env.example` and rename the copy to `.env`.

On Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Open `.env` and replace the placeholder with your own MySQL password.

**Important:** Never upload your private `.env` file to GitHub.

### Step 3: Start Docker Desktop

Make sure Docker Desktop is running.

### Step 4: Build and start the services

From the project root directory, run:

```bash
docker compose up --build -d
```

This starts:
- MySQL database on host port `3307`.
- Spring Boot backend on port `8080`.

### Step 5: Verify the containers

```bash
docker compose ps
```

The expected services are:
- `coworkhub-mysql` — Up (healthy)
- `coworkhub-backend` — Up

### Step 6: Test the backend

Open the following URL or run the command:

```bash
curl http://localhost:8080/api/resources
```

The API should return the available resources in JSON format.

### Step 7: Run the Flutter desktop application

Open a separate terminal:

```bash
cd frontend
flutter pub get
flutter run -d windows
```

The Flutter application communicates with the backend at:

```text
http://localhost:8080/api
```

### Stopping Docker services

To stop and remove the containers:

```bash
docker compose down
```

The database volume is preserved.

To remove the containers and database volume permanently:

```bash
docker compose down -v
```

**Warning:** The second command deletes the Docker database data.

## 7. Backend API

The backend exposes REST endpoints for resource and member management.

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/resources` | Retrieve all resources |
| GET | `/api/resources/{id}` | Retrieve a resource |
| POST | `/api/resources/rooms` | Create a meeting room |
| POST | `/api/resources/desks` | Create a desk |
| PUT | `/api/resources/rooms/{id}` | Update a meeting room |
| PUT | `/api/resources/desks/{id}` | Update a desk |
| DELETE | `/api/resources/{id}` | Delete a resource |
| GET | `/api/members` | Retrieve all members |
| GET | `/api/members/{id}` | Retrieve a member |
| POST | `/api/members` | Create a member |
| PUT | `/api/members/{id}` | Update a member |
| DELETE | `/api/members/{id}` | Delete a member |

Booking API endpoints will be documented once the booking backend implementation and integration are completed.

## 8. Database Design

The system uses MySQL with Spring Data JPA and Hibernate.

Main entities include:
- `BookableResource`
- `MeetingRoom`
- `Desk`
- `Member`
- `Booking`

The resource hierarchy uses the JPA `JOINED` inheritance strategy.

Bookings are associated with members and resources through many-to-one relationships.

## 9. Team Responsibilities

The project is developed by a team of four members.

| Member | Responsibilities |
|---|---|
| Member 1 – Team Leader | Backend architecture, JPA entities, database relationships, resource APIs, Docker setup and GitHub coordination |
| Member 2 | Booking and member functionality, availability validation and booking business logic |
| Member 3 | Flutter dashboard, resource management and member management screens |
| Member 4 | Availability, new booking and booking screens, Dart models and API integration |

## 10. Repository

GitHub Repository:

https://github.com/Huda-Mansoori/CoWorkHub

---

**CoWorkHub – Coworking Space & Meeting Room Booking System**