import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({Key? key}) : super(key: key);

  @override
  _LikedScreenState createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    checkAndCreateDocuments();
    debugPrintLikedByCollection();
    _listenForCollectionDeletions();
  }

  Future<void> checkAndCreateDocuments() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No user is currently authenticated.');
      return;
    }

    final userId = currentUser.uid;
    final swipesRef = _firestore.collection('swipes').doc(userId);
    final matchesRef = _firestore.collection('matches').doc(userId);

    Future<void> createDocumentWithRetry(
        DocumentReference docRef, String docName) async {
      const maxRetries = 3;
      for (int i = 0; i < maxRetries; i++) {
        try {
          final snapshot = await getDocumentFromServer(docRef);
          if (!snapshot.exists) {
            await docRef.set({
              'userId': userId,
              'timestamp': FieldValue.serverTimestamp(),
            });
            print('Created missing $docName document for user $userId.');
            return;
          } else {
            print('$docName document for user $userId is present.');
            return;
          }
        } catch (e) {
          print(
              'Error while checking or creating $docName document (attempt ${i + 1}): $e');
          if (i == maxRetries - 1) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
        }
      }
    }

    try {
      await createDocumentWithRetry(swipesRef, 'swipes');
      await createDocumentWithRetry(matchesRef, 'matches');
    } catch (e) {
      print('Failed to create documents after multiple attempts: $e');
    }
  }

// Helper function to get document from server
  Future<DocumentSnapshot> getDocumentFromServer(
      DocumentReference docRef) async {
    return await docRef.get(GetOptions(source: Source.server));
  }

  void _listenForCollectionDeletions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No user is currently authenticated.');
      return;
    }

    _firestore
        .collection('swipes')
        .doc(currentUser.uid)
        .snapshots()
        .listen((swipesDoc) {
      if (!swipesDoc.exists) {
        print('Swipes document for user ${currentUser.uid} does not exist.');
      } else {
        print('Swipes document for user ${currentUser.uid} is present.');
      }
    });

    _firestore
        .collection('matches')
        .doc(currentUser.uid)
        .snapshots()
        .listen((matchesDoc) {
      if (!matchesDoc.exists) {
        print('Matches document for user ${currentUser.uid} does not exist.');
      } else {
        print('Matches document for user ${currentUser.uid} is present.');
      }
    });
  }

  Stream<List<Map<String, dynamic>>> _streamLikedProfiles() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No user is currently authenticated.');
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('likedBy')
        .snapshots()
        .asyncMap((likedBySnapshot) async {
      final likedByUserIds = likedBySnapshot.docs.map((doc) => doc.id).toList();
      print('Liked By User IDs: $likedByUserIds');

      if (likedByUserIds.isEmpty) {
        print('No users have liked the current user.');
        return [];
      }

      try {
        final profilesQuerySnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: likedByUserIds)
            .get();

        final likedProfiles = profilesQuerySnapshot.docs.map((doc) {
          final data = doc.data();
          final likedByDoc =
              likedBySnapshot.docs.firstWhere((d) => d.id == doc.id);
          data['likedBack'] = likedByDoc.data()['liked'] ?? false;
          data['matched'] = likedByDoc.data()['matched'] ?? false;
          return data;
        }).toList();

        print('Fetched Liked Profiles: $likedProfiles');
        return likedProfiles;
      } catch (error) {
        print('Error fetching liked profiles: $error');
        return [];
      }
    });
  }

  void debugPrintLikedByCollection() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No user is currently authenticated.');
      return;
    }

    final likedByCollectionRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('likedBy');

    final snapshot = await likedByCollectionRef.get();
    if (snapshot.docs.isEmpty) {
      print('LikedBy collection is empty for user ${currentUser.uid}');
    } else {
      for (var doc in snapshot.docs) {
        print('Document ID: ${doc.id}, Data: ${doc.data()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked You'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamLikedProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('StreamBuilder Error: ${snapshot.error}');
            return const Center(child: Text('Error fetching liked profiles.'));
          }

          final likedProfiles = snapshot.data ?? [];

          if (likedProfiles.isEmpty) {
            return const Center(child: Text('No one has liked you yet.'));
          }

          return ListView.builder(
            itemCount: likedProfiles.length,
            itemBuilder: (context, index) {
              final profile = likedProfiles[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 18.0),
                    ),
                    if (profile['likedBack'] == true)
                      Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Text(
                          'You liked them back!',
                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                        ),
                      ),
                    if (profile['matched'] == true)
                      Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Text(
                          'Matched!',
                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
