import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, gameInvite, gameMove, gameResult }

enum GameInviteStatus { pending, accepted, declined }

class ChatMessage {
  final String id;
  final String senderId;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory ChatMessage.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      data: data,
    );
  }
}
