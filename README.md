# Healthy Summer - Full-Stack Wellness Application

A comprehensive wellness platform designed to help users track summer health activities, nutrition, fitness goals, and social wellness in one integrated application.

## Tech Stack

- **Backend**: Go (Gin framework)
- **Frontend**: Flutter (Dart)
- **Database**: PostgreSQL
- **Real-time**: WebSockets, gRPC
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Deployment**:
  - **Backend & Database**: Render.com
  - **Frontend**: GitHub Pages
- **Authentication**: JWT

## Features

### Activity Tracking

- Log various workout types (running, swimming, cycling, yoga, etc.)
- Automatic calorie calculation based on activity type and duration
- Step counting with daily goal tracking
- Activity history with filtering and categorization
- Weekly and monthly activity summaries with analytics
- Achievement badges for hitting fitness milestones

### Nutrition Management

- Log meals with food items, quantities, and nutritional information
- Search integrated food database
- Daily calorie tracking with customizable goals
- Water intake logging with hydration reminders
- Nutrition analytics with weekly reports and insights
- Personalized recommendations based on activity and intake

### Social & Community

- Friend connections and friend request system
- View friends' public activity feeds
- Real-time activity notifications
- Private messaging between friends
- Create and join group fitness challenges
- Live leaderboards for friendly competition
- Share achievements and milestones with community

### Analytics & Insights

- Comprehensive personal dashboard with health metrics
- Visual progress tracking (calorie burn vs. intake charts)
- Goal setting and progress monitoring
- Achievement system with badges and rewards
- Real-time notifications for goals, challenges, and friend activities
- Personalized health insights and recommendations

## Architecture

The backend is built using a modular microservice design with four core services:

- **User Service**: Authentication, profile management, friend connections, achievements
- **Activity Service**: Workout logging, step tracking, calorie calculations, activity analytics
- **Nutrition Service**: Meal planning, food database, water tracking, nutrition analytics
- **Social Service**: Real-time messaging, challenges, activity feeds, notifications

## Getting Started

### Prerequisites

- Go 1.21+
- Flutter 3.0+
- PostgreSQL 14+
- Docker (optional)

### Backend Setup

```bash
cd backend
go mod download
go run cmd/server/main.go
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

### Using Docker

```bash
docker-compose up
```

## Project Structure

```
backend/
├── cmd/          # Application entry points
├── internal/     # Core application code (handlers, services, models)
├── pkg/          # Shared packages (auth, database, gRPC)
├── migrations/   # Database migration files
└── tests/        # Integration tests

frontend/         # Flutter frontend application
├── lib/          # Main application code (screens, services, models)
├── test/         # Unit and integration tests
└── web/          # Web deployment configuration
```

## API Documentation

The backend exposes RESTful endpoints organized by service:

**User Service**: `/api/users/*` - registration, login, profiles, friends  
**Activity Service**: `/api/activities/*` - workout logging, steps, analytics  
**Nutrition Service**: `/api/meals/*`, `/api/water/*` - meal and hydration tracking  
**Social Service**: `/api/challenges/*`, `/api/messages/*`, `/api/feed/*` - social features

## Development

Use the provided Makefile for common development tasks:

```bash
make help        # View available commands
make build       # Build both frontend and backend
make test        # Run all tests
make migrate     # Run database migrations
```
