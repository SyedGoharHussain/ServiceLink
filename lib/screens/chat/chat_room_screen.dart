import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';

/// Chat room screen for real-time messaging
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatRoomScreen({
    Key? key,
    required this.chatId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load messages and mark as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();

      chatProvider.loadMessages(widget.chatId);

      // Mark messages as read when opening chat
      if (authProvider.userModel != null) {
        chatProvider.markMessagesAsRead(
          widget.chatId,
          authProvider.userModel!.uid,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final authProvider = context.read<AuthProvider>();
    if (_messageController.text.trim().isEmpty ||
        authProvider.userModel == null) {
      return;
    }

    // Pass isViewingChat=true since user is in the chat screen
    final success = await context.read<ChatProvider>().sendMessage(
      chatId: widget.chatId,
      senderId: authProvider.userModel!.uid,
      senderName: authProvider.userModel!.name,
      text: _messageController.text.trim(),
      isViewingChat: true,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();

    // Auto-scroll when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatProvider.currentMessages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(title: Text(widget.otherUserName), elevation: 1),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatProvider.currentMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: chatProvider.currentMessages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.currentMessages[index];
                      final isMe =
                          message.senderId == authProvider.userModel!.uid;

                      // Check if we should show date separator
                      bool showDateSeparator = false;
                      if (index < chatProvider.currentMessages.length - 1) {
                        final nextMessage =
                            chatProvider.currentMessages[index + 1];
                        final messageDate = DateTime.fromMillisecondsSinceEpoch(
                          message.timestamp.millisecondsSinceEpoch,
                        );
                        final nextMessageDate =
                            DateTime.fromMillisecondsSinceEpoch(
                              nextMessage.timestamp.millisecondsSinceEpoch,
                            );

                        if (messageDate.day != nextMessageDate.day ||
                            messageDate.month != nextMessageDate.month ||
                            messageDate.year != nextMessageDate.year) {
                          showDateSeparator = true;
                        }
                      } else {
                        showDateSeparator = true;
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(timestamp: message.timestamp),
                          _MessageBubble(message: message, isMe: isMe),
                        ],
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppConstants.primaryColor,
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, size: 20),
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime timestamp;

  const _DateSeparator({Key? key, required this.timestamp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      dateText = DateFormat('EEEE').format(timestamp);
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(timestamp);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({Key? key, required this.message, required this.isMe})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(
        message.timestamp.millisecondsSinceEpoch,
      ),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF075E54) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe
                ? const Radius.circular(12)
                : const Radius.circular(2),
            bottomRight: isMe
                ? const Radius.circular(2)
                : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
