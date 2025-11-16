import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

/// Provider for managing chat functionality
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();

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
            _chats = chats;
            notifyListeners();
          },
          onError: (error) {
            print('Error loading chats: $error');
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
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
  }) async {
    try {
      if (text.trim().isEmpty) return false;

      await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text.trim(),
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
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
