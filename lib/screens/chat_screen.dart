import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/message_widgets.dart';
import '../widgets/game_selector.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final ChatService _chatService = ChatService();

  ChatScreen({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  Widget _buildMessageWidget(ChatMessage message) {
    final isMe = message.senderId == currentUserId;

    switch (message.type) {
      case MessageType.gameInvite:
        return GameInviteMessageWidget(
          message: message,
          isMe: isMe,
          chatId: chatId,
          currentUserId: currentUserId,
        );
      case MessageType.text:
        return TextMessageWidget(message: message, isMe: isMe);
      default:
        return ListTile(
          title: Text(
            'Unsupported message type',
            style: TextStyle(color: Colors.red),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs.map((doc) {
                  try {
                    return ChatMessage.fromSnapshot(doc);
                  } catch (e) {
                    print('Error parsing message: $e');
                    // Return a default message in case of parsing error
                    return ChatMessage(
                      id: doc.id,
                      senderId: '',
                      type: MessageType.text,
                      timestamp: DateTime.now(),
                      data: {},
                    );
                  }
                }).toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageWidget(messages[index]),
                );
              },
            ),
          ),
          _MessageInput(chatId: chatId, currentUserId: currentUserId),
        ],
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const _MessageInput({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      message: _controller.text.trim(),
    );

    _controller.clear();
  }

  void _showGameSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => GameSelectorSheet(
        onGameSelected: (gameType) => _sendGameInvite(gameType),
      ),
    );
  }

  void _sendGameInvite(String gameType) async {
    await _chatService.sendGameInvite(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      gameType: gameType,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.games),
            onPressed: _showGameSelector,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
