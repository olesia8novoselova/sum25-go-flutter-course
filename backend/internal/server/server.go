package server

import (
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/config"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/activity"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/nutrition"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/user"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/handlers/wellness"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/middleware"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/db"
)

func NewRouter(cfg *config.Config) (*gin.Engine, error) {
	_ = godotenv.Load()

	if err := db.Init(cfg); err != nil {
		return nil, err
	}

	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery(), middleware.CORS())

	router.GET("/health", handlers.HealthCheck)

	api := router.Group("/api")
	{
		api.GET("/ping", handlers.Ping)

		users := api.Group("/users")
		{
			users.POST("/register", user.Register)
			users.POST("/login", user.Login)
			users.Use(middleware.Auth())
			users.GET("/profile", user.GetProfile)
			users.PUT("/profile", user.UpdateProfile)
			users.POST("/friends/request", user.RequestFriend)
			users.GET("/friends/requests", user.ListFriendRequests)
			users.GET("/friends", user.ListFriends)
			users.GET("/achievements", user.ListAllAchievements)
			users.GET("/users/achievements", user.ListUserAchievements)
			users.POST("/friends/requests/:id/accept", user.AcceptFriendRequest)
			users.POST("/friends/requests/:id/decline", user.DeclineFriendRequest)
		}

		acts := api.Group("/activities")
		acts.Use(middleware.Auth())
		{
			acts.POST("", activity.AddActivity)
			acts.GET("", activity.ListActivities)
			acts.POST("/steps", activity.AddSteps)
			acts.GET("/stats", activity.GetStepStats)
			acts.GET("/analytics", activity.GetStepAnalytics)
			acts.POST("/steps/goal", activity.SetStepGoal)
			acts.GET("/steps/goal", activity.GetStepGoal)
			acts.POST("/goal", activity.SetActivityGoal)
			acts.GET("/goal", activity.GetActivityGoal)
			acts.GET("/today-calories", activity.GetTodayActivityCalories)
			acts.GET("/activity/weekly", activity.GetWeeklyActivityStats)
			acts.POST("/schedule/workouts", wellness.AddWorkout)
			acts.GET("/schedule/workouts", wellness.ListWorkouts)
			acts.DELETE("/schedule/workouts/:id", wellness.DeleteWorkout)
		}

		nut := api.Group("/nutrition")
		nut.Use(middleware.Auth())
		{
			nut.GET("/foods/search", handlers.SearchUSDAFoods)
			nut.POST("/meals", nutrition.AddMeal)
			nut.GET("/meals", nutrition.ListMeals)
			nut.GET("/stats", nutrition.GetNutritionStats)
			nut.GET("/stats/weekly", nutrition.GetWeeklyNutritionStats)
			nut.POST("/water", nutrition.AddWaterLog)
			nut.GET("/water/today", nutrition.GetTodayWaterStats)
			nut.GET("/water/weekly", nutrition.GetWeeklyWaterStats)
			nut.POST("/water/goal", nutrition.SetWaterGoal)
			nut.GET("/water/goal", nutrition.GetWaterGoal)
			nut.POST("/calories/goal", nutrition.SetCalorieGoal)
			nut.GET("/calories/goal", nutrition.GetCalorieGoal)
		}

		well := api.Group("/wellness")
		{
			well.GET("/ws", wellness.WebSocketHandler)
			well.Use(middleware.Auth())
			well.POST("/activities", wellness.PostActivity)
			well.GET("/activities", wellness.GetFriendsActivities)
			well.GET("/ws/activity", wellness.ActivitySocket)
			well.GET("/messages/:friendId", wellness.GetMessages)
			well.GET("/friends", wellness.GetChatList)
			well.POST("/messages", wellness.PostMessage)
			well.POST("/challenges", wellness.CreateChallenge)
			well.GET("/challenges", wellness.ListChallenges)
			well.POST("/challenges/:id/join", wellness.JoinChallenge)
			well.GET("/challenges/:id/leaderboard", wellness.GetLeaderboard)
		}
	}

	return router, nil
}
