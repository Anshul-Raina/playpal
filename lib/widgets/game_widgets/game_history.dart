import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/services/game_service.dart';

class GameHistory extends StatefulWidget {
  final String chatId;
  final GameType gameType;

  const GameHistory({
    Key? key,
    required this.chatId,
    required this.gameType,
  }) : super(key: key);

  @override
  _GameHistoryState createState() => _GameHistoryState();
}

class _GameHistoryState extends State<GameHistory> {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _gameService.getGameHistory(widget.chatId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final games = snapshot.data!.docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['type'] ==
                  widget.gameType.toString())
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return ListTile(
                title: Text('Game ID: ${game['id']}'),
                subtitle: Text(
                    'Created: ${(game['createdAt'] as Timestamp).toDate().toString()}'),
                trailing: Text('Status: ${game['status']}'),
                onTap: () {
                  // Navigate to game details screen
                },
              );
            },
          );
        },
      ),
    );
  }
}
