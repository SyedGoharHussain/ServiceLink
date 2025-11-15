import 'package:firebase_database/firebase_database.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Chat service for handling real-time chat with Firebase Realtime Database
class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get chat ID between two users (deterministic)
  String getChatId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  /// Create or get existing chat
  Future<void> createChat({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final chatId = getChatId(userId1, userId2);
      print('ChatService: Chat ID will be: $chatId');

      final chatRef = _database.ref('chats/$chatId');
      print('ChatService: Checking if chat exists...');

      // Check if chat exists with timeout
      final snapshot = await chatRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print(
            'ChatService: Timeout checking chat, will try to create anyway',
          );
          throw Exception(
            'Timeout: Please check Firebase Realtime Database rules are deployed',
          );
        },
      );
      print('ChatService: Chat exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        print('ChatService: Creating new chat...');
        // Create new chat
        final chat = ChatModel(
          chatId: chatId,
          participants: [userId1, userId2],
        );

        await chatRef
            .set(chat.toMap())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('ChatService: Timeout creating chat');
                throw Exception(
                  'Timeout: Please check Firebase Realtime Database rules',
                );
              },
            );
        print('ChatService: Chat created successfully');
      } else {
        print('ChatService: Using existing chat');
      }
    } catch (e) {
      print('ChatService ERROR: $e');
      throw Exception('Failed to create chat: $e');
    }
  }

  /// Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    try {
      final messageRef = _database.ref('chats/$chatId/messages').push();

      final message = MessageModel(
        messageId: messageRef.key!,
        senderId: senderId,
        text: text,
      );

      await messageRef.set(message.toMap());

      // Update last message in chat
      await _database.ref('chats/$chatId').update({
        'lastMessage': text,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages stream for a chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    try {
      return _database
          .ref('chats/$chatId/messages')
          .orderByChild('timestamp')
          .onValue
          .map((event) {
            final messages = <MessageModel>[];

            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;

              data.forEach((key, value) {
                messages.add(MessageModel.fromMap(value, key));
              });

              // Sort by timestamp descending (newest first)
              messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            }

            return messages;
          });
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _database.ref('chats').orderByChild('lastMessageTime').onValue.map(
        (event) {
          final chats = <ChatModel>[];

          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;

            data.forEach((key, value) {
              final chat = ChatModel.fromMap(value, key);

              // Only include chats where user is a participant
              if (chat.participants.contains(userId)) {
                chats.add(chat);
              }
            });

            // Sort by last message time descending
            chats.sort(
              (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
            );
          }

          return chats;
        },
      );
    } catch (e) {
      throw Exception('Failed to get user chats: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final messagesRef = _database.ref('chats/$chatId/messages');
      final snapshot = await messagesRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) async {
          final message = MessageModel.fromMap(value, key);

          // Mark as read if not sent by current user
          if (message.senderId != userId && !message.isRead) {
            await messagesRef.child(key).update({'isRead': true});
          }
        });
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Get unread message count for a chat
  Future<int> getUnreadCount({
    required String chatId,
    required String userId,
  }) async {
    try {
      final messagesRef = _database.ref('chats/$chatId/messages');
      final snapshot = await messagesRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        int count = 0;

        data.forEach((key, value) {
          final message = MessageModel.fromMap(value, key);

          // Count unread messages not sent by current user
          if (message.senderId != userId && !message.isRead) {
            count++;
          }
        });

        return count;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }
}
