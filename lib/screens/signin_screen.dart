import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playpal/screens/basic_info_screen.dart';
import 'package:playpal/screens/home_screen.dart';
import 'package:playpal/screens/signup_screen.dart';
import 'package:playpal/screens/swipe_screen.dart'; // Import the swipe screen
import 'package:playpal/widgets/reusable_widget.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();

  // Handle sign-in logic and navigate accordingly
  Future<void> _handleSignIn(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailTextController.text,
              password: _passwordTextController.text);

      User? user = userCredential.user;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final bool onboardingComplete =
            prefs.getBool('onboardingComplete') ?? false;

        if (onboardingComplete) {
          // Go to swipe screen if onboarding is complete
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        } else {
          // Edge case, normally shouldn't happen if the user has logged in before
          // Go to onboarding screen if onboarding is not complete
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BasicInfoScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      // Handle sign-in errors, e.g., display a message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            reusableTextField("Enter Email id", Icons.person_outline, false,
                _emailTextController),
            const SizedBox(height: 20),
            reusableTextField("Enter Password", Icons.lock_outline, true,
                _passwordTextController),
            const SizedBox(height: 20),
            signInSignUpButton(context, true, () {
              _handleSignIn(context); // Call the handleSignIn method
            }),
            signUpOption()
          ],
        ),
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
          child: const Text("Sign Up",
              style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
