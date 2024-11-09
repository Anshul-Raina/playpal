import 'package:flutter/material.dart';

class GameSelectorSheet extends StatelessWidget {
  final Function(String) onGameSelected;

  const GameSelectorSheet({
    Key? key,
    required this.onGameSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start a Game',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.psychology),
            title: Text('Would You Rather'),
            subtitle: Text('Discover each other\'s preferences and values'),
            onTap: () => onGameSelected('wouldYouRather'),
          ),
          ListTile(
            leading: Icon(Icons.edit_note),
            title: Text('Story Builder'),
            subtitle: Text('Create stories together about future adventures'),
            onTap: () => onGameSelected('storyBuilder'),
          ),
          ListTile(
            leading: Icon(Icons.face),
            title: Text('Two Truths One Lie'),
            subtitle: Text('Share interesting facts about yourself'),
            onTap: () => onGameSelected('twoTruthsOneLie'),
          ),
        ],
      ),
    );
  }
}
