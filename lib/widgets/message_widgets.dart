import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../managers/game_manager.dart';

class TextMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const TextMessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            message.data['message'] ?? 'Message unavailable',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class GameInviteMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String chatId;
  final String currentUserId;
  final GameManager _gameManager = GameManager();

  GameInviteMessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  Future<void> _handleResponse(BuildContext context, bool accepted) async {
    if (!accepted) {
      await _handleDecline(context);
      return;
    }

    try {
      await _gameManager.handleGameAcceptance(
        context: context,
        chatId: chatId,
        messageId: message.id,
        gameType: message.data['gameType'],
        player1: message.senderId,
        player2: currentUserId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start game. Please try again.')),
      );
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    try {
      await ChatService().updateGameInviteStatus(
        chatId: chatId,
        messageId: message.id,
        status: GameInviteStatus.declined,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to decline invitation. Please try again.')),
      );
    }
  }

  Widget _buildResponseButtons(BuildContext context) {
    final status = GameInviteStatus.values.firstWhere(
      (e) => e.toString() == message.data['status'],
      orElse: () => GameInviteStatus.pending,
    );

    if (isMe || status != GameInviteStatus.pending) {
      return _buildStatusText(status);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _handleResponse(context, false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text('Decline'),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _handleResponse(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text('Accept'),
        ),
      ],
    );
  }

  String _getGameIcon(String gameType) {
    switch (gameType) {
      case 'wouldYouRather':
        return '🤔';
      case 'storyBuilder':
        return '📝';
      case 'twoTruthsOneLie':
        return '🎭';
      default:
        return '🎮';
    }
  }

  String _getGameDisplayName(String gameType) {
    switch (gameType) {
      case 'wouldYouRather':
        return 'Would You Rather';
      case 'storyBuilder':
        return 'Story Builder';
      case 'twoTruthsOneLie':
        return 'Two Truths & A Lie';
      default:
        return gameType;
    }
  }

  Widget _buildStatusText(GameInviteStatus status) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case GameInviteStatus.accepted:
        statusText = 'Game Started';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case GameInviteStatus.declined:
        statusText = 'Invitation Declined';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = 'Awaiting Response';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameType = message.data['gameType'];
    final gameIcon = _getGameIcon(gameType);
    final gameName = _getGameDisplayName(gameType);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$gameIcon Game Invitation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                _buildStatusText(
                  GameInviteStatus.values.firstWhere(
                    (e) => e.toString() == message.data['status'],
                    orElse: () => GameInviteStatus.pending,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Let\'s play $gameName together!',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            _buildResponseButtons(context),
          ],
        ),
      ),
    );
  }
}
