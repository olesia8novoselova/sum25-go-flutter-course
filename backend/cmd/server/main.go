package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"

	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/config"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/server"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"

	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/grpc"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on real environment")
	}

	cfg := config.Load()

	services.Schedule.StartTicker()

	router, err := server.NewRouter(cfg)
	if err != nil {
		log.Fatalf("Failed to create router: %v", err)
	}

	// Create HTTP server
	server := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: router,
	}

	// Start HTTP server in a goroutine
	go func() {
		log.Printf("HTTP server starting on port %s", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start HTTP server: %v", err)
		}
	}()

	// Start gRPC server in a goroutine
	go func() {
		if err := grpc.StartServer(cfg.GRPCPort); err != nil {
			log.Fatalf("Failed to start gRPC server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	// Give requests 10 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
