import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playpal/screens/basic_info_screen.dart';
import 'package:playpal/screens/signin_screen.dart';
import 'package:playpal/widgets/reusable_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController _userNameTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            title: const Text("Sign Up",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        body: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  reusableTextField("Enter UserName", Icons.person_outline,
                      false, _userNameTextController),
                  const SizedBox(
                    height: 20,
                  ),
                  reusableTextField("Enter Email Id", Icons.person_outline,
                      false, _emailTextController),
                  const SizedBox(
                    height: 20,
                  ),
                  reusableTextField("Enter Password", Icons.lock_outline, true,
                      _passwordTextController),
                  const SizedBox(
                    height: 20,
                  ),
                  signInSignUpButton(context, false, () {
                    FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                            email: _emailTextController.text,
                            password: _passwordTextController.text)
                        .then((value) async {
                      print("Created new account");
                      String uid = value.user!.uid;

                      // Add UID and other details to Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                        'username': _userNameTextController.text,
                        'email': _emailTextController.text,
                        // Add any other user details here
                      }).then((_) {
                        print("User added to Firestore");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BasicInfoScreen(),
                          ),
                        );
                      }).catchError((error) {
                        print("Error adding user to Firestore: $error");
                      });
                    }).onError((error, StackTrace) {
                      print("Error: ${error.toString()}");
                    });
                  }),
                  logInOption(),
                ],
              ),
            )));
  }

  Row logInOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SigninScreen(),
                ),
              );
            },
            child: const Text("Login",
                style: TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }
}
