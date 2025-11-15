/// Chat model representing a conversation between two users
class ChatModel {
  final String chatId;
  final List<String> participants; // [userId1, userId2]
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount; // {userId: count}

  ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage = '',
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now(),
       unreadCount = unreadCount ?? {};

  /// Convert ChatModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
    };
  }

  /// Create ChatModel from Firestore/Realtime Database map
  factory ChatModel.fromMap(Map<dynamic, dynamic> map, String chatId) {
    return ChatModel(
      chatId: chatId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
        map['lastMessageTime'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  /// Create a copy of ChatModel with updated fields
  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
