import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/screens/games/story_builder_screen.dart';
import 'package:playpal/screens/games/two_truths_screen.dart';
import 'package:playpal/screens/games/would_you_rather_screen.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class GameManager {
  final ChatService _chatService = ChatService();

  Future<void> handleGameAcceptance({
    required BuildContext context,
    required String chatId,
    required String messageId,
    required String gameType,
    required String player1,
    required String player2,
  }) async {
    // First update the invite status
    await _chatService.updateGameInviteStatus(
      chatId: chatId,
      messageId: messageId,
      status: GameInviteStatus.accepted,
    );

    // Create the game instance
    final gameId = await _chatService.createGame(
      chatId: chatId,
      gameType: gameType,
      player1: player1,
      player2: player2,
    );

    // Navigate to the appropriate game screen
    _navigateToGame(context, gameType, chatId, gameId);
  }

  void _navigateToGame(
      BuildContext context, String gameType, String chatId, String gameId) {
    Widget gameScreen;

    switch (gameType) {
      case 'wouldYouRather':
        gameScreen = WouldYouRatherGame(chatId: chatId, gameId: gameId);
        break;
      case 'storyBuilder':
        gameScreen = StoryBuilderGame(chatId: chatId, gameId: gameId);
        break;
      case 'twoTruthsOneLie':
        gameScreen = TwoTruthsOneLieGame(chatId: chatId, gameId: gameId);
        break;
      default:
        throw Exception('Unknown game type: $gameType');
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }
}
