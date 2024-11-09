import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:playpal/screens/chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  final String currentUserId;

  ChatsListScreen({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('user1', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, user1Snapshot) {
          if (!user1Snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('user2', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, user2Snapshot) {
              if (!user2Snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final List<DocumentSnapshot> allChats = [
                ...user1Snapshot.data!.docs,
                ...user2Snapshot.data!.docs,
              ];

              return ListView.builder(
                itemCount: allChats.length,
                itemBuilder: (context, index) {
                  final chat = allChats[index];
                  final chatId = chat.id;
                  final chatPartnerId = chat['user1'] == currentUserId
                      ? chat['user2']
                      : chat['user1'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(chatPartnerId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return ListTile(title: Text('Loading...'));
                      }

                      final user = userSnapshot.data!;
                      final userName = user['name'];

                      return ListTile(
                        title: Text(userName),
                        subtitle: Text('Tap to open chat'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chatId,
                                currentUserId: currentUserId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
