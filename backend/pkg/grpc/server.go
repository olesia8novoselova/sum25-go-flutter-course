package grpc

import (
	"context"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"github.com/google/uuid"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/models"
	"github.com/timur-harin/sum25-go-flutter-course/backend/internal/services"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/auth"
	"github.com/timur-harin/sum25-go-flutter-course/backend/pkg/grpc/proto"
)

type WellnessServer struct {
	proto.UnimplementedWellnessServiceServer
}

func (s *WellnessServer) SendMessage(ctx context.Context, req *proto.SendMessageRequest) (*proto.SendMessageResponse, error) {
	userID, err := getUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}

	msg := models.Message{
		ID:         uuid.NewString(),
		SenderID:   userID,
		ReceiverID: req.ReceiverId,
		Text:       req.Text,
		CreatedAt:  time.Now(),
	}

	if err := services.Message.SendMessage(msg); err != nil {
		log.Printf("[gRPC] Failed to send message: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to send message")
	}

	return &proto.SendMessageResponse{
		Message: &proto.Message{
			Id:         msg.ID,
			SenderId:   msg.SenderID,
			ReceiverId: msg.ReceiverID,
			Text:       msg.Text,
			CreatedAt:  msg.CreatedAt.Unix(),
		},
	}, nil
}

func (s *WellnessServer) GetMessages(ctx context.Context, req *proto.GetMessagesRequest) (*proto.GetMessagesResponse, error) {
	userID, err := getUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}

	msgs, err := services.Message.GetMessages(userID, req.FriendId)
	if err != nil {
		log.Printf("[gRPC] Failed to get messages: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to get messages")
	}

	protoMsgs := make([]*proto.Message, 0, len(msgs))
	for _, msg := range msgs {
		protoMsgs = append(protoMsgs, &proto.Message{
			Id:         msg.ID,
			SenderId:   msg.SenderID,
			ReceiverId: msg.ReceiverID,
			Text:       msg.Text,
			CreatedAt:  msg.CreatedAt.Unix(),
		})
	}

	return &proto.GetMessagesResponse{
		Messages: protoMsgs,
	}, nil
}

func (s *WellnessServer) GetChatList(ctx context.Context, req *proto.GetChatListRequest) (*proto.GetChatListResponse, error) {
	userID, err := getUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}

	ids, err := services.User.GetFriendIDs(userID)
	if err != nil {
		log.Printf("[gRPC] Failed to get friend IDs: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to get chat list")
	}

	friends := make([]*proto.Friend, 0, len(ids))
	for _, fid := range ids {
		profile, err := services.User.GetProfile(fid)
		if err != nil {
			log.Printf("[gRPC] Failed to get profile for %s: %v", fid, err)
			continue
		}
		friends = append(friends, &proto.Friend{
			Id:   fid,
			Name: profile.Name,
		})
	}

	return &proto.GetChatListResponse{
		Friends: friends,
	}, nil
}

func (s *WellnessServer) StreamMessages(req *proto.StreamMessagesRequest, stream proto.WellnessService_StreamMessagesServer) error {
	ctx := stream.Context()
	userID, err := getUserIDFromContext(ctx)
	if err != nil {
		return err
	}

	ch := make(chan models.Message, 100)
	services.ActivityHub.RegisterStream(userID, ch)
	defer services.ActivityHub.UnregisterStream(userID, ch)

	for {
		select {
		case <-ctx.Done():
			return nil
		case msg := <-ch:
			if err := stream.Send(&proto.Message{
				Id:         msg.ID,
				SenderId:   msg.SenderID,
				ReceiverId: msg.ReceiverID,
				Text:       msg.Text,
				CreatedAt:  msg.CreatedAt.Unix(),
			}); err != nil {
				log.Printf("[gRPC] Stream send error: %v", err)
				return err
			}
		}
	}
}

func getUserIDFromContext(ctx context.Context) (string, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return "", status.Errorf(codes.Unauthenticated, "missing metadata")
	}

	tokens := md.Get("authorization")
	if len(tokens) == 0 {
		return "", status.Errorf(codes.Unauthenticated, "missing authorization token")
	}

	tokenStr := tokens[0]
	if len(tokenStr) > 7 && tokenStr[:7] == "Bearer " {
		tokenStr = tokenStr[7:]
	}

	claims, err := auth.ParseToken(tokenStr)
	if err != nil {
		return "", status.Errorf(codes.Unauthenticated, "invalid token: %v", err)
	}

	return claims.UserID, nil
}

func StartServer(port string) error {
	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		return err
	}

	s := grpc.NewServer()
	proto.RegisterWellnessServiceServer(s, &WellnessServer{})

	log.Printf(" gRPC server starting on port %s", port)
	return s.Serve(lis)
}
