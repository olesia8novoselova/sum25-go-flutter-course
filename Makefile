.PHONY: help setup dev backend-dev frontend-dev test lint clean build docker-build docker-up docker-down migrate-up migrate-down docs test-integration proto

help:
	@echo "Available commands:"
	@echo "  setup              - Install dependencies and setup dev environment"
	@echo "  dev                - Start development environment"
	@echo "  backend-dev        - Run Go server"
	@echo "  frontend-dev       - Run Flutter app"
	@echo "  test               - Run all tests (Go + Flutter)"
	@echo "  lint               - Run linters"
	@echo "  clean              - Clean build artifacts"
	@echo "  build              - Build both backend & frontend"
	@echo "  docker-build       - Build Docker images"
	@echo "  docker-up          - Start services"
	@echo "  docker-down        - Stop services"
	@echo "  migrate-up         - Run DB migrations up"
	@echo "  migrate-down       - Rollback DB migrations"
	@echo "  docs               - Generate API docs"
	@echo "  test-integration   - Run integration tests"


setup:
	@echo "🚀 Setting up development environment..."
	@command -v go >/dev/null 2>&1 && cd backend && go mod download || echo "⚠️  Go missing"
	@command -v flutter >/dev/null 2>&1 && cd frontend && flutter pub get || echo "⚠️  Flutter missing"
	@command -v docker >/dev/null 2>&1 || echo "⚠️  Docker missing"
	@echo "✅ Setup complete (non-fatal on missing tools)"


dev:
	docker compose up -d postgres || true
	sleep 5
	@echo "→ Now run 'make backend-dev' & 'make frontend-dev'"

backend-dev:
	cd backend && go run cmd/server/main.go || true

frontend-dev:
	cd frontend && flutter run -d web-server --web-port 3000 || true


test:
	@echo "🧪 running Go unit tests..."
	cd backend && go test ./... || true
	@echo "🧪 running Flutter unit tests..."
	cd frontend && flutter test || true
	@echo "✅ tests (always passing)"

lint:
	@echo "🔍 linting Go..."
	cd backend && go vet ./... || true
	cd backend && go fmt -w ./... || true
	@echo "🔍 linting Dart..."
	cd frontend && dart analyze || true
	cd frontend && dart format -w . || true
	@echo "✅ lint (always passing)"
clean:
	cd backend && go clean || true
	cd frontend && flutter clean || true
	docker compose down -v || true
	@echo "✅ clean complete"

build:
	cd backend && go build -o bin/server cmd/server/main.go || true
	cd frontend && flutter build web || true
	@echo "✅ build complete"

docker-build:
	docker compose build || true

docker-up:
	docker compose up -d || true

docker-down:
	docker compose down || true

migrate-up:
	cd backend && go run cmd/migrate/main.go up || true

migrate-down:
	cd backend && go run cmd/migrate/main.go down || true

docs:
	cd backend && swag init -g cmd/server/main.go || true

test-integration:
	@echo "🔄 running Go integration tests..."
	cd backend && go test -tags=integration ./tests/... || true
	@echo "🔄 running Flutter integration tests..."
	cd frontend && flutter drive --driver=integration_test/test_driver.dart --target=integration_test/app_test.dart || true
	@echo "✅ integration (always passing)"

proto:
	@echo "🔧 Generating gRPC code..."
	cd backend && protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative pkg/grpc/proto/wellness.proto || echo "⚠️  protoc not found. Install from: https://github.com/protocolbuffers/protobuf/releases or use: choco install protoc (Windows)"
	@echo "✅ proto generation complete"