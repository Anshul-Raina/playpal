import 'package:cloud_firestore/cloud_firestore.dart';

enum GameType {
  wouldYouRather,
  twoTruthsOneLie,
  storyBuilder,
}

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get real-time game updates
  Stream<DocumentSnapshot> getGameStream(String chatId, String gameId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .doc(gameId)
        .snapshots();
  }

  // Create a new game
  Future<DocumentReference> createGame({
    required String chatId,
    required GameType gameType,
    required String creatorId,
    required List<String> players,
    Map<String, dynamic>? initialState,
  }) async {
    final gameData = {
      'type': gameType.toString(),
      'createdAt': FieldValue.serverTimestamp(),
      'creatorId': creatorId,
      'players': players,
      'currentTurn': players.isNotEmpty ? players[0] : creatorId,
      'currentUserId': creatorId,
      'status': 'active',
      'gameState': _getInitialGameState(gameType, initialState),
    };

    return await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .add(gameData);
  }

  // Make a move in the game
  Future<void> makeMove({
    required String chatId,
    required String gameId,
    required Map<String, dynamic> move,
  }) async {
    final gameRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .doc(gameId);

    return _firestore.runTransaction((transaction) async {
      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data() as Map<String, dynamic>;
      final gameType = GameType.values.firstWhere(
        (e) => e.toString() == gameData['type'],
        orElse: () => GameType.wouldYouRather,
      );

      final List<String> players = List<String>.from(gameData['players'] ?? []);
      if (players.isEmpty) return;

      final currentTurnIndex =
          players.indexOf(gameData['currentTurn'] ?? players[0]);
      final nextTurnIndex = (currentTurnIndex + 1) % players.length;

      // Update game state based on game type and move
      final updatedGameState = await _processMove(
        gameType,
        Map<String, dynamic>.from(gameData['gameState'] ?? {}),
        move,
      );

      transaction.update(gameRef, {
        'gameState': updatedGameState,
        'currentTurn': players[nextTurnIndex],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // Process move based on game type
  Future<Map<String, dynamic>> _processMove(
    GameType gameType,
    Map<String, dynamic> currentState,
    Map<String, dynamic> move,
  ) async {
    switch (gameType) {
      case GameType.wouldYouRather:
        return _processWouldYouRatherMove(currentState, move);
      case GameType.twoTruthsOneLie:
        return _processTwoTruthsOneLieMove(currentState, move);
      case GameType.storyBuilder:
        return _processStoryBuilderMove(currentState, move);
    }
  }

  // Get initial game state based on game type
  Map<String, dynamic> _getInitialGameState(
    GameType gameType,
    Map<String, dynamic>? customState,
  ) {
    if (customState != null) return customState;

    switch (gameType) {
      case GameType.wouldYouRather:
        return {
          'round': 1,
          'maxRounds': 5,
          'questions': [],
          'answers': {},
        };
      case GameType.twoTruthsOneLie:
        return {
          'statements': {},
          'guesses': {},
          'revealed': false,
          'scores': {},
        };
      case GameType.storyBuilder:
        return {
          'story': '',
          'currentPrompt': '',
          'turns': [],
        };
    }
  }

  // Process Would You Rather move
  Map<String, dynamic> _processWouldYouRatherMove(
    Map<String, dynamic> currentState,
    Map<String, dynamic> move,
  ) {
    final answers = Map<String, dynamic>.from(currentState['answers'] ?? {});
    final currentRound = currentState['round'] ?? 1;
    final maxRounds = currentState['maxRounds'] ?? 5;

    answers[currentRound.toString()] = move;

    // Check if all players have answered
    final allAnswered =
        true; // Implement logic to check if all players answered

    if (allAnswered && currentRound < maxRounds) {
      return {
        ...currentState,
        'answers': answers,
        'round': currentRound + 1,
      };
    }

    return {
      ...currentState,
      'answers': answers,
    };
  }

  // Process Two Truths One Lie move
  Map<String, dynamic> _processTwoTruthsOneLieMove(
    Map<String, dynamic> currentState,
    Map<String, dynamic> move,
  ) {
    if (move.containsKey('statements')) {
      return {
        ...currentState,
        'statements': move['statements'],
      };
    }

    if (move.containsKey('guess')) {
      final guesses = Map<String, dynamic>.from(currentState['guesses'] ?? {});
      guesses[move['guess'].toString()] = true;

      // Check if all players have guessed
      final allGuessed =
          true; // Implement logic to check if all players guessed

      if (allGuessed) {
        return {
          ...currentState,
          'guesses': guesses,
          'revealed': true,
        };
      }
    }

    return currentState;
  }

  Future<void> updateGameState(
    String chatId,
    String gameId,
    Map<String, dynamic> newState,
  ) async {
    final gameRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .doc(gameId);

    return _firestore.runTransaction((transaction) async {
      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final currentData = gameDoc.data() as Map<String, dynamic>;
      final currentGameState = Map<String, dynamic>.from(
          currentData['gameState'] as Map<String, dynamic>? ?? {});

      if (newState.containsKey('gameState')) {
        // If updating the entire gameState, merge with existing
        final updatedGameState = {
          ...currentGameState,
          ...newState['gameState'] as Map<String, dynamic>,
        };

        transaction.update(gameRef, {
          ...newState,
          'gameState': updatedGameState,
          'lastUpdateTimestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // If updating nested fields, merge with existing gameState
        final updatedGameState = {
          ...currentGameState,
          ...newState,
        };

        transaction.update(gameRef, {
          'gameState': updatedGameState,
          'lastUpdateTimestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Process Story Builder move
  Map<String, dynamic> _processStoryBuilderMove(
    Map<String, dynamic> currentState,
    Map<String, dynamic> move,
  ) {
    if (move.containsKey('addition')) {
      final currentStory = currentState['story'] as String? ?? '';
      final addition = move['addition'] as String;
      final updatedStory =
          currentStory.isEmpty ? addition : '$currentStory\n\n$addition';

      final turns = List<dynamic>.from(currentState['turns'] ?? [])
        ..add({
          'text': addition,
          'timestamp': FieldValue.serverTimestamp(),
        });

      return {
        ...currentState,
        'story': updatedStory,
        'turns': turns,
      };
    }

    return currentState;
  }

  // End game
  Future<void> endGame(String chatId, String gameId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .doc(gameId)
        .update({
      'status': 'completed',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get game history
  Stream<QuerySnapshot> getGameHistory(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get game statistics
  Future<Map<String, dynamic>> getGameStats(String chatId) async {
    final gamesQuery = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('games')
        .get();

    final Map<String, dynamic> stats = {
      'totalGames': gamesQuery.docs.length,
      'gamesByType': <String, int>{},
      'activePlayers': <String>{},
    };

    for (final doc in gamesQuery.docs) {
      final data = doc.data();
      final gameType = data['type'] as String;

      // Safe access to nested map with null checking
      final gamesByType = stats['gamesByType'] as Map<String, int>;
      gamesByType[gameType] = (gamesByType[gameType] ?? 0) + 1;

      if (data['players'] != null) {
        final players = List<String>.from(data['players'] as List);
        final activePlayers = stats['activePlayers'] as Set<String>;
        activePlayers.addAll(players);
      }
    }

    return stats;
  }
}
