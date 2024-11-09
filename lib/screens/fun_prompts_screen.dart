// fun_prompts_screen.dart
import 'package:flutter/material.dart';
import 'package:playpal/screens/compatibility_and_interests_screen.dart';
import 'package:playpal/models/user_data.dart';

class FunPromptsScreen extends StatefulWidget {
  final UserData userData;

  const FunPromptsScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<FunPromptsScreen> createState() => _FunPromptsScreenState();
}

class _FunPromptsScreenState extends State<FunPromptsScreen> {
  String? _icebreakerAnswer;
  String _truth1 = '';
  String _truth2 = '';
  String _lie = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fun and Interactive Prompts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Answer a fun icebreaker:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _icebreakerAnswer,
              onChanged: (value) {
                setState(() {
                  _icebreakerAnswer = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Choose an answer'),
              items: const [
                DropdownMenuItem(
                    value: 'I love dogs.', child: Text('I love dogs.')),
                DropdownMenuItem(
                    value: 'I enjoy cooking.', child: Text('I enjoy cooking.')),
                DropdownMenuItem(
                    value: 'I play the guitar.',
                    child: Text('I play the guitar.')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Truth #1'),
              onChanged: (value) {
                setState(() {
                  _truth1 = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Truth #2'),
              onChanged: (value) {
                setState(() {
                  _truth2 = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Lie'),
              onChanged: (value) {
                setState(() {
                  _lie = value;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final updatedUserData = widget.userData.copyWith(
                  favoriteActivities: [_icebreakerAnswer ?? ''],
                  topFiveFavorites: [_truth1, _truth2, _lie],
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompatibilityAndInterestsScreen(
                        userData: updatedUserData),
                  ),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
