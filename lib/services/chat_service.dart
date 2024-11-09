import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': MessageType.text.toString(),
    });
  }

  Future<void> sendGameInvite({
    required String chatId,
    required String senderId,
    required String gameType,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'type': MessageType.gameInvite.toString(),
      'gameType': gameType,
      'status': GameInviteStatus.pending.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGameInviteStatus({
    required String chatId,
    required String messageId,
    required GameInviteStatus status,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'status': status.toString(),
    });
  }

  Future<String> createGame({
    required String chatId,
    required String gameType,
    required String player1,
    required String player2,
  }) async {
    DocumentReference gameRef = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .add({
      'gameType': gameType,
      'player1': player1,
      'player2': player2,
      'status': 'active',
      'currentTurn': player1,
      'startedAt': FieldValue.serverTimestamp(),
      'gameState': _getInitialGameState(gameType),
    });

    return gameRef.id;
  }

  Map<String, dynamic> _getInitialGameState(String gameType) {
    switch (gameType) {
      case 'wouldYouRather':
        return {
          'round': 1,
          'maxRounds': 5,
          'questions': [],
          'answers': {},
        };
      case 'storyBuilder':
        return {
          'story': '',
          'currentPrompt': '',
          'turns': [],
        };
      case 'twoTruthsOneLie':
        return {
          'statements': {},
          'guesses': {},
          'revealed': false,
        };
      default:
        return {};
    }
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
