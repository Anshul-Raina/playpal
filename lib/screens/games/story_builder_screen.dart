import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:playpal/services/game_service.dart';

class StoryBuilderGame extends StatefulWidget {
  final String chatId;
  final String gameId;

  const StoryBuilderGame({
    Key? key,
    required this.chatId,
    required this.gameId,
  }) : super(key: key);

  @override
  _StoryBuilderGameState createState() => _StoryBuilderGameState();
}

class _StoryBuilderGameState extends State<StoryBuilderGame> {
  final GameService _gameService = GameService();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story Builder'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _gameService.getGameStream(widget.chatId, widget.gameId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final gameData = snapshot.data!.data() as Map<String, dynamic>;
          final gameState = gameData['gameState'];
          final story = gameState['story'] as String;
          final currentPrompt = gameState['currentPrompt'] as String;
          final isMyTurn = gameData['currentTurn'] == gameData['currentUserId'];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Story So Far...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        story.isEmpty ? 'Start the story...' : story,
                        style: TextStyle(fontSize: 16),
                      ),
                      if (currentPrompt.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Prompt:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(currentPrompt),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isMyTurn)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add to the story...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        child: Text('Submit'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_controller.text.trim().isEmpty) return;

    await _gameService.makeMove(
      chatId: widget.chatId,
      gameId: widget.gameId,
      move: {'addition': _controller.text.trim()},
    );

    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
