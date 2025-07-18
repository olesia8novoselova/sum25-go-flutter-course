package config

import (
	"log"
	"os"
	"strconv"
)

// Config holds all configuration values
type Config struct {
	Env         string
	Port        string
	GRPCPort    string
	DatabaseURL string
	JWTSecret   string
	CORSOrigins string
}

// Load reads configuration from environment variables
// and fails immediately if any *required* value is missing.
func Load() *Config {
	return &Config{
		Env:      getEnv("ENV", "development"),
		Port:     getEnv("PORT", "8080"),
		GRPCPort: getEnv("GRPC_PORT", "9090"),

		DatabaseURL: getEnvRequired("DATABASE_URL"),

		JWTSecret: getEnv("JWT_SECRET", "your-jwt-secret-key"),

		CORSOrigins: getEnv("CORS_ORIGINS", "http://localhost:3000"),
	}
}

// getEnv returns the value of the env var or the fallback if unset.
func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

// getEnvRequired returns the env var or fatally exits your app if it’s not set.
func getEnvRequired(key string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	log.Fatalf("❌ Required environment variable %s is not set", key)
	return "" // unreachable
}

// getEnvAsInt gets an environment variable as int with a fallback value
func getEnvAsInt(name string, fallback int) int {
	valueStr := getEnv(name, "")
	if value, err := strconv.Atoi(valueStr); err == nil {
		return value
	}
	return fallback
}

// getEnvAsBool gets an environment variable as bool with a fallback value
func getEnvAsBool(name string, fallback bool) bool {
	valueStr := getEnv(name, "")
	if value, err := strconv.ParseBool(valueStr); err == nil {
		return value
	}
	return fallback
}
