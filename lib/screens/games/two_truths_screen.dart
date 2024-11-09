import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:playpal/services/game_service.dart';

class TwoTruthsOneLieGame extends StatefulWidget {
  final String chatId;
  final String gameId;

  const TwoTruthsOneLieGame({
    Key? key,
    required this.chatId,
    required this.gameId,
  }) : super(key: key);

  @override
  _TwoTruthsOneLieGameState createState() => _TwoTruthsOneLieGameState();
}

class _TwoTruthsOneLieGameState extends State<TwoTruthsOneLieGame> {
  final GameService _gameService = GameService();
  final List<TextEditingController> _controllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int? _selectedLie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two Truths & A Lie'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _gameService.getGameStream(widget.chatId, widget.gameId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final gameData = snapshot.data!.data() as Map<String, dynamic>;
          final gameState = gameData['gameState'];
          final statements = gameState['statements'] as Map;
          final guesses = gameState['guesses'] as Map;
          final revealed = gameState['revealed'] as bool;
          final isMyTurn = gameData['currentTurn'] == gameData['currentUserId'];

          if (statements.isEmpty && isMyTurn) {
            return _buildInputPhase();
          }

          return _buildGuessPhase(statements, guesses, revealed);
        },
      ),
    );
  }

  Widget _buildInputPhase() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter two truths and one lie:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...List.generate(3, (index) => _buildStatementInput(index)),
          SizedBox(height: 16),
          if (_selectedLie != null)
            ElevatedButton(
              onPressed: _handleSubmitStatements,
              child: Text('Submit Statements'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatementInput(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _controllers[index],
            decoration: InputDecoration(
              hintText: 'Statement ${index + 1}',
              border: OutlineInputBorder(),
            ),
          ),
          RadioListTile<int>(
            title: Text('This is the lie'),
            value: index,
            groupValue: _selectedLie,
            onChanged: (value) => setState(() => _selectedLie = value),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessPhase(
    Map statements,
    Map guesses,
    bool revealed,
  ) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            revealed ? 'Results' : 'Guess which one is the lie:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...statements.entries.map((entry) {
            final index = int.parse(entry.key);
            final statement = entry.value as String;
            final isLie = revealed && entry.value['isLie'] == true;
            final isGuessed = guesses[index.toString()] == true;

            return Card(
              color: revealed
                  ? (isLie ? Colors.red.shade100 : Colors.green.shade100)
                  : (isGuessed ? Colors.blue.shade100 : null),
              child: ListTile(
                title: Text(statement),
                trailing: revealed
                    ? Icon(
                        isLie ? Icons.close : Icons.check,
                        color: isLie ? Colors.red : Colors.green,
                      )
                    : IconButton(
                        icon: Icon(
                          isGuessed
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        onPressed: () => _handleGuess(index),
                      ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _handleSubmitStatements() async {
    if (_selectedLie == null) return;

    final statements = {};
    for (int i = 0; i < 3; i++) {
      statements[i.toString()] = {
        'text': _controllers[i].text.trim(),
        'isLie': i == _selectedLie,
      };
    }

    await _gameService.makeMove(
      chatId: widget.chatId,
      gameId: widget.gameId,
      move: {'statements': statements},
    );
  }

  Future<void> _handleGuess(int index) async {
    await _gameService.makeMove(
      chatId: widget.chatId,
      gameId: widget.gameId,
      move: {'guess': index},
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
