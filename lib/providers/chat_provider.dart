import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../services/fcm_notification_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

/// Provider for managing chat functionality
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  final FCMNotificationService _fcmService = FCMNotificationService();

  List<ChatModel> _chats = [];
  List<MessageModel> _currentMessages = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ChatModel>>? _chatsSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// Load user's chats
  void loadUserChats(String userId) {
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatService
        .getUserChats(userId)
        .listen(
          (chats) {
            // Sort chats: unread messages first, then by last message time
            _chats = chats;
            _sortChats(userId);
            notifyListeners();
          },
          onError: (error) {
            print('Error loading chats: $error');
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  /// Sort chats by unread count and last message time
  void _sortChats(String userId) {
    _chats.sort((a, b) {
      final aUnread = a.unreadCount[userId] ?? 0;
      final bUnread = b.unreadCount[userId] ?? 0;

      // If one has unread and other doesn't, unread comes first
      if (aUnread > 0 && bUnread == 0) return -1;
      if (aUnread == 0 && bUnread > 0) return 1;

      // Both have unread or both don't have unread, sort by time
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });
  }

  /// Load messages for a specific chat
  void loadMessages(String chatId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .getMessages(chatId)
        .listen(
          (messages) {
            _currentMessages = messages;
            notifyListeners();
          },
          onError: (error) {
            print('Error loading messages: $error');
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  /// Send a message
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    bool isViewingChat = false,
  }) async {
    try {
      if (text.trim().isEmpty) return false;

      await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text.trim(),
        isViewingChat: false, // Always send notification - let service decide
      );

      // Get recipient ID from chatId
      final chatParticipants = chatId.split('_');
      final recipientId = chatParticipants.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );

      // Always send FCM notification - recipient will get it if not viewing
      if (recipientId.isNotEmpty) {
        await _fcmService.sendChatNotification(
          recipientId: recipientId,
          senderName: senderName,
          message: text.trim(),
          chatId: chatId,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark messages as read for a specific chat
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatId: chatId, userId: userId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get total unread message count for user
  int getTotalUnreadCount(String userId) {
    int total = 0;
    for (var chat in _chats) {
      total += chat.unreadCount[userId] ?? 0;
    }
    return total;
  }

  /// Create or get chat with another user
  Future<String> createOrGetChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      print(
        'ChatProvider: Creating chat between $currentUserId and $otherUserId',
      );

      await _chatService.createChat(
        userId1: currentUserId,
        userId2: otherUserId,
      );

      final chatId = _chatService.getChatId(currentUserId, otherUserId);
      print('ChatProvider: Chat created with ID: $chatId');

      return chatId;
    } catch (e) {
      print('ChatProvider ERROR: $e');
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatId: chatId, userId: userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get other user's info from chat
  Future<UserModel?> getOtherUserFromChat(
    String chatId,
    String currentUserId,
  ) async {
    try {
      final chat = _chats.firstWhere((c) => c.chatId == chatId);
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUserId,
      );
      return await _firestoreService.getUser(otherUserId);
    } catch (e) {
      return null;
    }
  }

  /// Clear current messages
  void clearCurrentMessages() {
    _currentMessages = [];
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
