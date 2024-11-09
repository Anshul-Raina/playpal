import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/services/game_service.dart';
import 'package:playpal/widgets/game_widgets/game_history.dart';
import 'package:playpal/widgets/game_widgets/player_list.dart';
import 'package:playpal/default_prompts.dart';

class WouldYouRatherGame extends StatefulWidget {
  final String chatId;
  final String gameId;

  const WouldYouRatherGame({
    Key? key,
    required this.chatId,
    required this.gameId,
  }) : super(key: key);

  @override
  _WouldYouRatherGameState createState() => _WouldYouRatherGameState();
}

class _WouldYouRatherGameState extends State<WouldYouRatherGame> {
  bool _isLoading = true;
  String? _errorMessage;
  final GameService _gameService = GameService();
  late Stream<DocumentSnapshot> _gameStream;
  Map<String, dynamic>? _gameData;
  Map<String, dynamic>? _gameState;
  bool _isGameEnded = false;
  final TextEditingController _customPromptAController =
      TextEditingController();
  final TextEditingController _customPromptBController =
      TextEditingController();
  String _selectedCategory = 'All';
  List<WouldYouRatherPrompt> _availablePrompts = [];

  @override
  void initState() {
    super.initState();
    _gameStream = _gameService.getGameStream(widget.chatId, widget.gameId);
    _subscribeToGameUpdates();
    _loadPrompts();
    _handlePlayerJoining(); // Renamed method
  }

  Future<void> _handlePlayerJoining() async {
    try {
      // Get a reference to the game document
      final gameRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('games')
          .doc(widget.gameId);

      // Use a transaction to ensure atomic updates
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game document does not exist');
        }

        final gameData = gameDoc.data() as Map<String, dynamic>;
        final List<String> currentPlayers =
            List<String>.from(gameData['players'] ?? []);
        final String? player1 = gameData['player1'];
        final String? player2 = gameData['player2'];

        Map<String, dynamic> updateData = {};

        // If this is a new player
        if (!currentPlayers.contains(widget.chatId)) {
          currentPlayers.add(widget.chatId);
          updateData['players'] = currentPlayers;

          // Assign player roles if needed
          if (player1 == null) {
            updateData['player1'] = widget.chatId;
          } else if (player2 == null && player1 != widget.chatId) {
            updateData['player2'] = widget.chatId;
          }

          // Initialize game state if this is the second player
          if (currentPlayers.length == 2 && gameData['gameState'] == null) {
            updateData['gameState'] = {
              'round': 1,
              'maxRounds': 5,
              'currentQuestion': null,
              'answers': {},
              'status': 'waiting'
            };
          }

          // Only update if we have changes
          if (updateData.isNotEmpty) {
            transaction.update(gameRef, updateData);
          }
        }
      });

      print("Successfully handled player joining");
    } catch (e) {
      print("Error handling player joining: $e");
      setState(() {
        _errorMessage = 'Error joining game: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeFirstQuestion() async {
    if (_gameState == null || _gameData == null) return;

    // Check if we have both players before starting
    final String? player1 = _gameData!['player1'];
    final String? player2 = _gameData!['player2'];

    if (player1 == null || player2 == null) {
      setState(() {
        _errorMessage = 'Waiting for another player to join...';
      });
      return;
    }

    try {
      // Get a random prompt
      WouldYouRatherPrompt newQuestion = DefaultPrompts.getRandomPrompt();

      // Create the question object
      final questionObj = {
        'optionA': newQuestion.optionA,
        'optionB': newQuestion.optionB,
        'category': newQuestion.category,
      };

      // Update the game state with the initial question
      await _gameService.updateGameState(
        widget.chatId,
        widget.gameId,
        {
          'currentTurn': player1,
          'gameType': 'wouldYouRather',
          'gameState': {
            'round': 1,
            'maxRounds': 5,
            'currentQuestion': questionObj, // Add the current question
            'questions': [questionObj], // Initialize questions array
            'answers': {},
            'status': 'active',
          },
          'status': 'active',
          'startedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      print("Error initializing first question: $e");
      setState(() {
        _errorMessage = 'Error initializing game: $e';
        _isLoading = false;
      });
    }
  }

// Add this helper method to check if it's the player's turn
  bool _isPlayersTurn() {
    if (_gameData == null) return false;
    return _gameData!['currentTurn'] == widget.chatId;
  }

// Update the _buildOptionCard method to disable selection when it's not the player's turn
  Widget _buildOptionCard(String option, VoidCallback onTap, bool isSelected) {
    final bool canSelect = _isPlayersTurn() &&
        !_hasSelected(_gameState?['round']?.toString() ?? '1');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? Colors.blue.shade100 : null,
        child: InkWell(
          onTap: canSelect ? onTap : null,
          child: Opacity(
            opacity: canSelect ? 1.0 : 0.5,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    option,
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(Icons.check_circle, color: Colors.green),
                    ),
                  if (!canSelect && !isSelected)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Waiting for your turn...",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Update the handleChoice method to switch turns after a choice is made
  Future<void> _handleChoice(String choice) async {
    if (_gameState == null || !_isPlayersTurn()) return;

    try {
      final currentRound = _gameState!['round'].toString();
      Map<String, dynamic> answers =
          Map<String, dynamic>.from(_gameState!['answers'] ?? {});

      if (answers[currentRound]?['selected'] == null) {
        answers[currentRound] = {
          'selected': choice,
          'timestamp': FieldValue.serverTimestamp(),
          'playerId': widget.chatId,
        };

        // Update game state and switch turns
        final nextPlayer = _gameData!['currentTurn'] == _gameData!['player1']
            ? _gameData!['player2']
            : _gameData!['player1'];

        await _gameService.updateGameState(
          widget.chatId,
          widget.gameId,
          {
            'gameState': {
              ..._gameState!,
              'answers': answers,
            },
            'currentTurn': nextPlayer,
          },
        );

        await _checkRoundCompletion();
      }
    } catch (e) {
      print('Error in _handleChoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting choice. Please try again.')),
      );
    }
  }

  void _loadPrompts() {
    setState(() {
      _availablePrompts = DefaultPrompts.prompts;
      print("Loaded ${_availablePrompts.length} prompts");
      print(
          "First prompt: ${_availablePrompts[0].optionA} vs ${_availablePrompts[0].optionB}");
    });
  }

  @override
  void dispose() {
    _customPromptAController.dispose();
    _customPromptBController.dispose();
    super.dispose();
  }

  void _subscribeToGameUpdates() {
    print("Subscribing to game updates");
    _gameStream.listen(
      (snapshot) {
        print("Received snapshot: ${snapshot.data()}");
        if (!snapshot.exists) {
          setState(() {
            _errorMessage = 'Game not found';
            _isLoading = false;
          });
          return;
        }

        try {
          final rawData = snapshot.data() as Map<String, dynamic>?;
          if (rawData == null) {
            setState(() {
              _errorMessage = 'Invalid game data format';
              _isLoading = false;
            });
            return;
          }

          print("Processing game data: $rawData");
          setState(() {
            _gameData = Map<String, dynamic>.from(rawData);
            // Extract the nested gameState
            _gameState = (rawData['gameState'] as Map<String, dynamic>?) ?? {};
            _isGameEnded = rawData['status'] == 'completed';
            _isLoading = false;
            _errorMessage = null;
          });
          print("State updated - Loading: $_isLoading");
        } catch (e) {
          print("Error processing game data: $e");
          setState(() {
            _errorMessage = 'Error processing game data: $e';
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        print("Stream error: $error");
        setState(() {
          _errorMessage = 'Error loading game data: $error';
          _isLoading = false;
        });
      },
    );
  }

// Update the _nextQuestion method to match the new structure
  Future<void> _nextQuestion() async {
    if (_gameState == null) return;

    WouldYouRatherPrompt newQuestion;
    if (_selectedCategory == 'All') {
      newQuestion = DefaultPrompts.getRandomPrompt();
    } else {
      final categoryPrompts =
          DefaultPrompts.getPromptsByCategory(_selectedCategory);
      if (categoryPrompts.isNotEmpty) {
        final randomIndex =
            DateTime.now().millisecondsSinceEpoch % categoryPrompts.length;
        newQuestion = categoryPrompts[randomIndex];
      } else {
        newQuestion = DefaultPrompts.getRandomPrompt();
      }
    }

    final currentRound = (_gameState!['round'] ?? 0) + 1;

    final newGameState = {
      'currentQuestion': {
        'optionA': newQuestion.optionA,
        'optionB': newQuestion.optionB,
        'category': newQuestion.category,
        'isCustom': false,
      },
      'round': currentRound,
      'maxRounds': _gameState!['maxRounds'],
      'answers': _gameState!['answers'] ?? {},
      'status': 'active'
    };

    await _gameService.updateGameState(
        widget.chatId, widget.gameId, newGameState);
  }

  Future<void> _checkRoundCompletion() async {
    print('_checkRoundCompletion called');
    if (_gameState == null || _gameData == null) {
      print('Early return: game state or data is null');
      return;
    }

    final currentRound = _gameState!['round'];
    final maxRounds = _gameState!['maxRounds'];
    final answers = Map<String, dynamic>.from(_gameState!['answers'] ?? {});

    // Get active players
    List<String> players = [];
    if (_gameData!['player1'] != null) {
      players.add(_gameData!['player1']);
    }
    if (_gameData!['player2'] != null) {
      players.add(_gameData!['player2']);
    }

    print('Active players: $players');
    print('Current answers: $answers');

    // Count answers for current round
    final currentRoundAnswers = answers.entries
        .where((entry) =>
            entry.value is Map &&
            entry.value['selected'] != null &&
            entry.value['playerId'] != null)
        .length;

    print('Number of answers for current round: $currentRoundAnswers');
    print('Total number of players: ${players.length}');

    if (currentRoundAnswers == players.length) {
      print('All players have answered for round $currentRound');
      if (currentRound < maxRounds) {
        await _moveToNextRound();
      } else {
        await _endGame();
      }
    } else {
      print('Waiting for other players to answer');
    }
  }

  Future<void> _moveToNextRound() async {
    print('Moving to next round');
    WouldYouRatherPrompt newQuestion;
    if (_selectedCategory == 'All') {
      newQuestion = DefaultPrompts.getRandomPrompt();
    } else {
      final categoryPrompts =
          DefaultPrompts.getPromptsByCategory(_selectedCategory);
      if (categoryPrompts.isNotEmpty) {
        final randomIndex =
            DateTime.now().millisecondsSinceEpoch % categoryPrompts.length;
        newQuestion = categoryPrompts[randomIndex];
      } else {
        newQuestion = DefaultPrompts.getRandomPrompt();
      }
    }

    // Preserve existing answers when updating game state
    final updatedGameState = {
      ..._gameState!,
      'round': (_gameState!['round'] ?? 0) + 1,
      'currentQuestion': {
        'optionA': newQuestion.optionA,
        'optionB': newQuestion.optionB,
        'category': newQuestion.category,
        'isCustom': false,
      },
    };

    await _gameService.updateGameState(
      widget.chatId,
      widget.gameId,
      {
        'gameState': updatedGameState,
      },
    );
  }

  Future<void> _endGame() async {
    print('Game completed, updating status');
    await _gameService.updateGameState(
      widget.chatId,
      widget.gameId,
      {
        'gameState': _gameState,
        'status': 'completed',
      },
    );
    print('Game status updated to completed');
  }

  void _showCustomPromptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Custom Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customPromptAController,
              decoration: InputDecoration(labelText: 'Option A'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _customPromptBController,
              decoration: InputDecoration(labelText: 'Option B'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_customPromptAController.text.isNotEmpty &&
                  _customPromptBController.text.isNotEmpty) {
                _submitCustomPrompt();
                Navigator.pop(context);
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCustomPrompt() async {
    await _gameService.updateGameState(
      widget.chatId,
      widget.gameId,
      {
        'currentQuestion': {
          'optionA': _customPromptAController.text,
          'optionB': _customPromptBController.text,
          'category': 'Custom',
          'isCustom': true,
        }
      },
    );
    _customPromptAController.clear();
    _customPromptBController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Would You Rather'),
        actions: [
          if (_gameData != null)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text(
                  'Round ${_gameState?['round'] ?? 1}/${_gameState?['maxRounds'] ?? 10}',
                ),
              ),
            ),
          _buildCategoryDropdown(),
          IconButton(
            icon: Icon(Icons.leaderboard),
            onPressed: () => _showGameHistory(),
          ),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () => _showPlayerList(),
          ),
        ],
      ),
      body: _buildGameBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCustomPromptDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Custom Prompt',
      ),
    );
  }

  Widget _buildGameBody() {
    print(
        "Building game body - Loading: $_isLoading, Error: $_errorMessage, GameState: $_gameState");

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading game...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeFirstQuestion,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isGameEnded) {
      return _buildGameSummary();
    }

    // Check if we need to initialize the game
    if (_gameState == null || _gameState!['currentQuestion'] == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Waiting for game to start...'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeFirstQuestion,
              child: Text('Start Game'),
            ),
          ],
        ),
      );
    }

    return _buildGamePlay();
  }

  Widget _buildGamePlay() {
    final currentQuestion = _gameState?['currentQuestion'];
    if (currentQuestion == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentQuestion['isCustom'] == true)
          Padding(
            padding: EdgeInsets.all(8),
            child: Chip(label: Text('Custom Prompt')),
          ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Would you rather...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        _buildOptionCard(
          currentQuestion['optionA'],
          () => _handleChoice('A'),
          _hasSelected('A'),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'OR',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildOptionCard(
          currentQuestion['optionB'],
          () => _handleChoice('B'),
          _hasSelected('B'),
        ),
      ],
    );
  }

  bool _hasSelected(String option) {
    final currentRound = _gameState?['round']?.toString();
    final answers = _gameState?['answers'] as Map<String, dynamic>?;
    return answers?[currentRound]?['selected'] == option;
  }

  Widget _buildCategoryDropdown() {
    return DropdownButton<String>(
      value: _selectedCategory,
      items: ['All', ...DefaultPrompts.categories].map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCategory = newValue;
          });
          _nextQuestion();
        }
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCustomPromptDialog,
      child: Icon(Icons.add),
      tooltip: 'Add Custom Prompt',
    );
  }

  Widget _buildReactions() {
    final reactions = ['👍', '👎', '😆', '😮', '🤔', '❤️'];
    return Wrap(
      spacing: 8,
      children: reactions.map((emoji) {
        return InkWell(
          onTap: () => _handleReaction(emoji),
          child: Chip(label: Text(emoji)),
        );
      }).toList(),
    );
  }

  Future<void> _handleReaction(String reaction) async {
    await _gameService.makeMove(
      chatId: widget.chatId,
      gameId: widget.gameId,
      move: {'reaction': reaction},
    );
  }

  void _showGameHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameHistory(
          chatId: widget.chatId,
          gameType: GameType.wouldYouRather,
        ),
      ),
    );
  }

  void _showPlayerList() {
    showDialog(
      context: context,
      builder: (context) => PlayerList(
        players: List<String>.from(_gameData?['players'] ?? []),
      ),
    );
  }

  Widget _buildGameSummary() {
    final answers = _gameState?['answers'] as Map<String, dynamic>;
    final scores = <String, int>{};

    // Calculate scores
    for (final entry in answers.entries) {
      final playerId = entry.key;
      final choice = entry.value['selected'];
      scores[playerId] = (scores[playerId] ?? 0) + (choice == 'A' ? 1 : 0);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Game Over!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final playerId = scores.keys.elementAt(index);
              final score = scores[playerId]!;
              return ListTile(
                leading: Icon(Icons.person),
                title: Text('Player $playerId'),
                trailing: Text('Score: $score'),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Back to Chat'),
          ),
        ),
      ],
    );
  }
}
