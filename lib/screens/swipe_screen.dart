import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/screens/chat_screen.dart';
import 'package:playpal/screens/signin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'filter_screen.dart';

class SwipeHandler {
  final BuildContext context;
  final List<Map<String, dynamic>> profiles;
  final AppinioSwiperController controller;

  SwipeHandler(this.context, this.profiles, this.controller);
  Future<String> createChat(String user1Id, String user2Id) async {
    try {
      final chatId = user1Id.compareTo(user2Id) < 0
          ? '$user1Id-$user2Id'
          : '$user2Id-$user1Id';

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'user1': user1Id,
        'user2': user2Id,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Chat created between $user1Id and $user2Id.');
      return chatId; // Return the chatId here
    } catch (e) {
      print('Error creating chat: $e');
      return ''; // Return an empty string in case of an error
    }
  }

  Future<void> updateLikedByCollection(
      String currentUserId, String likedUserId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('likedBy')
          .doc(likedUserId)
          .set({
        'liked': true,
        'matched': true,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Updated likedBy collection for user $currentUserId');
    } catch (e) {
      print('Error updating likedBy collection: $e');
    }
  }

  void handleSwipe(int index, SwiperActivity activity) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final swipedUserId = profiles[index]['uid'];

    // Ensure the activity is a Swipe event
    if (activity is Swipe) {
      final startOffset = activity.begin;
      final endOffset = activity.end;

      // Ensure offsets are not null before accessing their properties
      if (startOffset != null && endOffset != null) {
        // Calculate the swipe direction
        final xDiff = endOffset.dx - startOffset.dx;
        final yDiff = endOffset.dy - startOffset.dy;

        // Determine swipe direction
        if (xDiff.abs() > yDiff.abs()) {
          // Horizontal swipe
          if (xDiff > 0) {
            // Right swipe
            await _onSwipeRight(swipedUserId);
          } else {
            // Left swipe
            await _onSwipeLeft(swipedUserId);
          }
        }
      }
    }
  }

  Future<void> _onSwipeRight(String swipedUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final swipeRef = FirebaseFirestore.instance
        .collection('swipes')
        .doc(currentUserId)
        .collection('swipedUsers')
        .doc(swipedUserId);
    final otherSwipeRef = FirebaseFirestore.instance
        .collection('swipes')
        .doc(swipedUserId)
        .collection('swipedUsers')
        .doc(currentUserId);
    final likedByRef = FirebaseFirestore.instance
        .collection('users')
        .doc(swipedUserId)
        .collection('likedBy')
        .doc(currentUserId);

    try {
      await swipeRef.set({
        'liked': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await likedByRef.set({
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Swipe right action saved for $currentUserId on $swipedUserId');

      final swipeDoc = await swipeRef.get();
      final otherSwipeDoc = await otherSwipeRef.get();

      // Add logging to see the exact values of swipeDoc.data() and otherSwipeDoc.data()
      print('swipeDoc.data(): ${swipeDoc.data()}');
      print('otherSwipeDoc.data(): ${otherSwipeDoc.data()}');

      if (swipeDoc.data()?['liked'] == true &&
          otherSwipeDoc.exists &&
          otherSwipeDoc.data()?['liked'] == true) {
        print('Both users have swiped right');
        await FirebaseFirestore.instance.collection('matches').add({
          'user1': currentUserId,
          'user2': swipedUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Create a chat after matching
        final chatId =
            await createChat(currentUserId, swipedUserId); // Store chatId

        print('Match created between $currentUserId and $swipedUserId');

        await updateLikedByCollection(currentUserId, swipedUserId);
        await updateLikedByCollection(swipedUserId, currentUserId);
        await _sendMatchNotification(
            swipedUserId, chatId); // Pass the chatId to the notification
      } else {
        print(
            'Condition not met: swipeDoc.data()[\'liked\'] = ${swipeDoc.data()?['liked']}, otherSwipeDoc.exists = ${otherSwipeDoc.exists}, otherSwipeDoc.data()[\'liked\'] = ${otherSwipeDoc.data()?['liked']}');
      }
    } catch (e) {
      print("Error handling swipe right: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLikedProfiles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      final likedBySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('likedBy')
          .get();

      final likedByUserIds = likedBySnapshot.docs.map((doc) => doc.id).toList();

      final profilesQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: likedByUserIds)
          .get();

      return profilesQuerySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching liked profiles: $e");
      return [];
    }
  }

  Future<void> _onSwipeLeft(String swipedUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final swipeRef = FirebaseFirestore.instance
        .collection('swipes')
        .doc(currentUserId)
        .collection('swipedUsers')
        .doc(swipedUserId);

    try {
      // Save the swipe action
      await swipeRef.set({
        'liked': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Swipe left action saved for $currentUserId on $swipedUserId');
    } catch (e) {
      print("Error handling swipe left: $e");
    }
  }

  Future<void> _sendMatchNotification(
      String swipedUserId, String chatId) async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(swipedUserId)
        .get();

    final swipedUserName = userSnapshot.data()?['name'] ?? 'User';
    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid; // Get current user ID

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('It\'s a Match!'),
          content: Text('You and $swipedUserName have liked each other!'),
          actions: [
            TextButton(
              child: const Text('Start Chat'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chatId, // Pass the chatId to ChatScreen
                      currentUserId:
                          currentUserId, // Pass the currentUserId to ChatScreen
                    ),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text('Keep Swiping'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({Key? key}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final List<Map<String, dynamic>> _profiles = [];
  late AppinioSwiperController _swiperController;
  late SwipeHandler _swipeHandler;

  @override
  void initState() {
    super.initState();
    _swiperController = AppinioSwiperController();
    _swipeHandler = SwipeHandler(context, _profiles, _swiperController);

    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Get swiped users
      final swipedUserIdsSnapshot = await FirebaseFirestore.instance
          .collection('swipes')
          .doc(currentUser.uid)
          .collection('swipedUsers')
          .get();

      final swipedUserIds = swipedUserIdsSnapshot.docs
          .where((doc) => doc.data()['liked'] != null)
          .map((doc) => doc.id)
          .toSet();

      // Fetch profiles excluding the current user's profile
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid);

      final querySnapshot = await query.get();
      final profiles = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Filter out swiped users on the client side
      final filteredProfiles = profiles.where((profile) {
        final uid = profile['uid'] as String?;
        return uid != null && !swipedUserIds.contains(uid);
      }).toList();

      if (mounted) {
        setState(() {
          _profiles.clear();
          _profiles.addAll(filteredProfiles);
        });
      }
    } catch (e) {
      print("Error fetching profiles: $e");
    }
  }

  List<Map<String, dynamic>> _sortProfiles(
    List<Map<String, dynamic>> profiles,
    Map<String, dynamic>? filters,
  ) {
    String location = filters?['location'] ?? '';
    List<String> interests = filters?['interests'] ?? [];
    String relationshipGoal = filters?['relationshipGoal'] ?? '';

    profiles.sort((a, b) {
      double distanceA = _calculateDistance(location, a['location'] ?? '');
      double distanceB = _calculateDistance(location, b['location'] ?? '');

      int distanceComparison = distanceA.compareTo(distanceB);
      if (distanceComparison != 0) return distanceComparison;

      int matchingInterestsA = (a['interests'] as List<dynamic>?)
              ?.where((interest) => interests.contains(interest))
              .length ??
          0;
      int matchingInterestsB = (b['interests'] as List<dynamic>?)
              ?.where((interest) => interests.contains(interest))
              .length ??
          0;

      int interestsComparison =
          matchingInterestsB.compareTo(matchingInterestsA);
      if (interestsComparison != 0) return interestsComparison;

      bool matchesGoalA = a['relationshipGoal'] == relationshipGoal;
      bool matchesGoalB = b['relationshipGoal'] == relationshipGoal;

      if (matchesGoalA && !matchesGoalB) return -1; // A should come first
      if (!matchesGoalA && matchesGoalB) return 1; // B should come first
      return 0; // No preference
    });

    return profiles;
  }

  double _calculateDistance(String location1, String location2) {
    // Dummy implementation for distance calculation; replace with a geolocation library.
    if (location1 == location2) return 0.0;
    return 50.0; // Arbitrary distance value
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Swipe Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _navigateToFilterScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              await deleteAccount(context);
            },
          ),
          IconButton(
            onPressed: () async {
              _logout(context);
            },
            icon: const Icon(Icons.logout_outlined),
          )
        ],
      ),
      body: _profiles.isEmpty
          ? const Center(
              child: Text("No more profiles left to swipe"),
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height,
              child: AppinioSwiper(
                cardBuilder: (context, index) {
                  return _buildCard(_profiles[index]);
                },
                controller: _swiperController,
                cardCount: _profiles.length,
                backgroundCardScale: 0.8,
                onSwipeEnd: (index, totalIndex, activity) {
                  _swipeHandler.handleSwipe(index, activity);
                },
                onEnd: () {
                  print('No more profiles to swipe!');
                },
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> profile) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(_safeCastToListString(profile['photoUrls'])),
              const SizedBox(height: 16),

              // Basic Information Section
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'] ?? 'No Name',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile['age'] ?? 'N/A'} years old',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      profile['location'] ?? 'Unknown Location',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Personal Preferences Section
              _buildSectionCard(
                'Personal Preferences',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        'Relationship Goal', profile['relationshipGoal']),
                    _buildInfoRow(
                        'Sexual Orientation', profile['sexualOrientation']),
                    _buildInfoRow('Looking For',
                        _formatList(profile['lookingFor'] as List<dynamic>?)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Interests and Hobbies Section
              _buildSectionCard(
                'Interests & Hobbies',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        'Music Preferences', profile['musicPreferences']),
                    _buildInfoRow(
                        'Activities',
                        _formatList(
                            profile['favoriteActivities'] as List<dynamic>?)),
                    _buildInfoRow(
                        'Unique Interests', profile['uniqueInterests']),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fun Prompts Section
              _buildSectionCard(
                'Fun Facts',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Icebreaker', profile['icebreakerAnswer']),
                    const SizedBox(height: 8),
                    const Text(
                      'Two Truths and a Lie:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (profile['topFiveFavorites'] != null &&
                        (profile['topFiveFavorites'] as List).length >= 3)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${profile['topFiveFavorites'][0]}'),
                          Text('• ${profile['topFiveFavorites'][1]}'),
                          Text('• ${profile['topFiveFavorites'][2]}'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not specified',
              style: const TextStyle(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _safeCastToListString(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  String _formatInterests(List<String> interests) {
    if (interests.isEmpty) return 'No interests listed';
    return interests.join(', ');
  }

  Widget _buildImageCarousel(List<String> photoUrls) {
    return SizedBox(
      height: 200,
      child: photoUrls.isNotEmpty
          ? ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      photoUrls[index],
                      fit: BoxFit.cover,
                      width: 150,
                    ),
                  ),
                );
              },
            )
          : Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.photo, size: 100, color: Colors.grey),
              ),
            ),
    );
  }

  String _formatList(List<dynamic>? list) {
    if (list == null || list.isEmpty) {
      return 'None';
    }
    return list.join(', ');
  }

  void _navigateToFilterScreen() async {
    final filters = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => FilterScreen(
                onApplyFilters: (filters) {
                  Navigator.pop(context, filters);
                },
              )),
    );

    if (filters != null) {
      final sortedProfiles = _sortProfiles(_profiles, filters);
      setState(() {
        _profiles.clear();
        _profiles.addAll(sortedProfiles);
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

  Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.delete();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SigninScreen()),
        );
      } catch (e) {
        print("Error deleting account: $e");
      }
    }
  }
}
