import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:playpal/screens/home_screen.dart';
import 'package:playpal/screens/signin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/screens/basic_info_screen.dart';
import 'package:playpal/models/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the UserData class

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  final User? user = FirebaseAuth.instance.currentUser;

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  bool? onboardingComplete = prefs.getBool('onboardingComplete');

  if (user != null) {
    if (onboardingComplete == null) {
      // No local data, check Firestore for onboarding status
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = UserData.fromMap(userDoc.data()!);
        onboardingComplete = userData.completedOnboarding;

        // Store onboarding status in local storage
        prefs.setBool('onboardingComplete', onboardingComplete);
      }
    }

    // Redirect based on onboarding status
    if (onboardingComplete == true) {
      runApp(PlayPalApp(initialScreen: HomeScreen()));
    } else {
      runApp(PlayPalApp(initialScreen: BasicInfoScreen()));
    }
  } else {
    runApp(PlayPalApp(initialScreen: SigninScreen()));
  }
}

class PlayPalApp extends StatelessWidget {
  final Widget initialScreen;
  final String? currentUserId; // Pass currentUserId

  const PlayPalApp({Key? key, required this.initialScreen, this.currentUserId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayPal',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: initialScreen,
    );
  }
}
