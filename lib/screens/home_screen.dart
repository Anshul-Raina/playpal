import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playpal/screens/chat_list_screen.dart';
import 'package:playpal/screens/liked_screen.dart';
import 'package:playpal/screens/swipe_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId =
        FirebaseAuth.instance.currentUser!.uid; // Get current user ID
  }

  var _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      Center(child: Text('Profile Page')), // Placeholder for Profile Page
      SwipeScreen(), // People (Swipe) Page
      LikedScreen(), // Placeholder for Liked You Page
      ChatsListScreen(
          currentUserId: currentUserId), // Pass non-nullable user ID
    ];

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.home),
            title: Text("Profile"),
            selectedColor: Colors.orange,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.person),
            title: Text("People"),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.favorite_border),
            title: Text("Liked You"),
            selectedColor: Colors.pink,
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.chat),
            title: Text("Chats"),
            selectedColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}
