import 'package:flutter/material.dart';
import 'package:playpal/screens/photos_and_videos_screen.dart';
import 'package:playpal/models/user_data.dart';

class CompatibilityAndInterestsScreen extends StatefulWidget {
  final UserData userData;

  const CompatibilityAndInterestsScreen({Key? key, required this.userData})
      : super(key: key);

  @override
  State<CompatibilityAndInterestsScreen> createState() =>
      _CompatibilityAndInterestsScreenState();
}

class _CompatibilityAndInterestsScreenState
    extends State<CompatibilityAndInterestsScreen> {
  final TextEditingController _musicPreferencesController =
      TextEditingController();
  final TextEditingController _uniqueInterestsController =
      TextEditingController();
  List<String> _favoriteActivities = [];

  // Compatibility responses
  Map<String, int> responses = {
    'extroversion': 3,
    'partner_extroversion': 3,
    'communication_style': 3,
    'free_time': 3,
    'physical_activities': 3,
    'socializing': 3,
    'partner_socializing': 3,
    'shared_beliefs': 3,
    'want_children': 2, // For "Maybe" option
    'career_ambition': 3,
    'partner_ambition': 3,
    'financial_stability': 3,
    'shared_financial': 3,
  };

  // Drag-and-drop categories
  List<String> categories = [
    'Personality & Preferences',
    'Lifestyle & Social Preferences',
    'Values & Deal-Breakers',
    'Career Ambitions & Financial Attitudes',
    'Interests & Hobbies'
  ];

  Map<String, double> categoryWeights = {};

  // Initial default weights
  List<double> defaultWeights = [35, 25, 20, 15, 5];

  @override
  void initState() {
    super.initState();
    // Initialize weights based on the default order
    for (int i = 0; i < categories.length; i++) {
      categoryWeights[categories[i]] = defaultWeights[i];
    }
  }

  @override
  void dispose() {
    _musicPreferencesController.dispose();
    _uniqueInterestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibility & Interests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Drag and drop categories to prioritize:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            buildDraggableCategories(),
            const SizedBox(height: 32),
            const Text(
              'Compatibility Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            buildQuestion(
              'How extroverted are you?',
              'extroversion',
              [
                '1: Very introverted (prefer being alone most of the time)',
                '2: Mostly introverted (prefer small gatherings)',
                '3: Balanced between social and quiet time',
                '4: Mostly extroverted (prefer social gatherings)',
                '5: Very extroverted (love being in social situations)',
              ],
            ),
            buildQuestion(
              'How extroverted would you like your partner to be?',
              'partner_extroversion',
              [
                '1: Very introverted (prefer being alone most of the time)',
                '2: Mostly introverted (prefer small gatherings)',
                '3: Balanced between social and quiet time',
                '4: Mostly extroverted (prefer social gatherings)',
                '5: Very extroverted (love being in social situations)',
              ],
            ),
            buildQuestion(
              'How do you prefer to communicate?',
              'communication_style',
              [
                '1: Mostly texting',
                '2: Text with occasional in-person conversations',
                '3: Balanced between texting and face-to-face communication',
                '4: Prefer in-person conversations',
                '5: Deep, meaningful face-to-face conversations',
              ],
            ),
            buildQuestion(
              'How do you prefer your partner to communicate?',
              'partner_communication',
              [
                '1: Mostly texting',
                '2: Text with occasional in-person conversations',
                '3: Balanced between texting and face-to-face communication',
                '4: Prefer in-person conversations',
                '5: Deep, meaningful face-to-face conversations',
              ],
            ),
            buildQuestion(
              'How do you prefer to spend your free time?',
              'free_time',
              [
                '1: Mostly indoors (reading, gaming, relaxing)',
                '2: Indoors with some outdoor activities',
                '3: Balanced between indoors and outdoors',
                '4: Outdoors most of the time (sports, socializing)',
                '5: Very active outdoors (travel, hiking, adventures)',
              ],
            ),
            buildQuestion(
              'How important is it for you to do physical activities together with your partner?',
              'physical_activities',
              [
                '1: Not important at all',
                '2: Occasionally',
                '3: Sometimes, balanced',
                '4: Often',
                '5: Very important, I want an active partner',
              ],
            ),
            buildQuestion(
              'How often do you prefer to go out and socialize with friends?',
              'socializing',
              [
                '1: Rarely, prefer staying home',
                '2: Occasionally',
                '3: Sometimes, balanced',
                '4: Often, I enjoy socializing',
                '5: Very often, I love going out',
              ],
            ),
            buildQuestion(
              'How important is it that your partner enjoys socializing as much as you do?',
              'partner_socializing',
              [
                '1: Not important',
                '2: Slightly important',
                '3: Moderately important',
                '4: Important',
                '5: Very important',
              ],
            ),
            buildQuestion(
              'How important are shared religious/spiritual beliefs?',
              'shared_beliefs',
              [
                '1: Not important',
                '2: Slightly important',
                '3: Moderately important',
                '4: Important',
                '5: Very important',
              ],
            ),
            buildQuestion(
              'Do you want children in the future?',
              'want_children',
              [
                '1: Yes',
                '2: No',
                '3: Maybe',
              ],
            ),
            buildQuestion(
              'How ambitious are you when it comes to your career?',
              'career_ambition',
              [
                '1: Not ambitious (career is not a priority)',
                '2: Slightly ambitious (career is somewhat important)',
                '3: Moderately ambitious (I have some goals, but it’s not my top priority)',
                '4: Ambitious (I’m driven to achieve in my career)',
                '5: Extremely ambitious (I’m focused on career success)',
              ],
            ),
            buildQuestion(
              'How ambitious would you like your partner to be?',
              'partner_ambition',
              [
                '1: Not ambitious (career is not a priority)',
                '2: Slightly ambitious (career is somewhat important)',
                '3: Moderately ambitious (I have some goals, but it’s not my top priority)',
                '4: Ambitious (I’m driven to achieve in my career)',
                '5: Extremely ambitious (I’m focused on career success)',
              ],
            ),
            buildQuestion(
              'How important is financial stability to you?',
              'financial_stability',
              [
                '1: Not important (I’m not focused on finances right now)',
                '2: Slightly important',
                '3: Moderately important',
                '4: Important',
                '5: Very important (financial security is a high priority for me)',
              ],
            ),
            buildQuestion(
              'Do you prefer to share financial responsibilities equally with your partner?',
              'shared_financial',
              [
                '1: Not important',
                '2: Slightly important',
                '3: Moderately important',
                '4: Important',
                '5: Very important (I want an equal partnership in finances)',
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Hobbies and Interests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _musicPreferencesController,
              decoration: const InputDecoration(labelText: 'Music Preferences'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _uniqueInterestsController,
              decoration: const InputDecoration(labelText: 'Unique Interests'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: ['Hiking', 'Reading', 'Gaming', 'Traveling']
                  .map((activity) => ChoiceChip(
                        label: Text(activity),
                        selected: _favoriteActivities.contains(activity),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _favoriteActivities.add(activity);
                            } else {
                              _favoriteActivities.remove(activity);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAndNavigate,
              child: const Text('Save & Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQuestion(String question, String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        ...options.map((option) {
          final index = options.indexOf(option) + 1;
          return RadioListTile<int>(
            title: Text(option),
            value: index,
            groupValue: responses[key],
            onChanged: (value) {
              setState(() {
                responses[key] = value!;
              });
            },
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildDraggableCategories() {
    return Wrap(
      spacing: 8.0,
      children: categories
          .map((category) => Draggable<String>(
                data: category,
                feedback: Material(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.blue,
                    child: Text(category),
                  ),
                ),
                childWhenDragging: Container(),
                child: DragTarget<String>(
                  builder: (context, candidateData, rejectedData) {
                    return Chip(
                      label: Text(category),
                      backgroundColor: Colors.grey[200],
                    );
                  },
                  onAccept: (data) {
                    setState(() {
                      // Change the order based on the drag-and-drop action
                      int oldIndex = categories.indexOf(data);
                      int newIndex = categories.indexOf(category);

                      if (oldIndex < newIndex) {
                        categories.insert(newIndex + 1, data);
                        categories.removeAt(oldIndex);
                      } else {
                        categories.insert(newIndex, data);
                        categories.removeAt(oldIndex + 1);
                      }
                    });
                  },
                ),
              ))
          .toList(),
    );
  }

  void _saveAndNavigate() {
    // Collect all the data you want to save or pass to the next screen
    final Map<String, dynamic> collectedData = {
      'compatibilityResponses': responses,
      'musicPreferences': _musicPreferencesController.text,
      'uniqueInterests': _uniqueInterestsController.text,
      'favoriteActivities': _favoriteActivities,
      'categoryWeights': categoryWeights,
    };

    // Print or debug the collected data if needed
    debugPrint(collectedData.toString());

    // Navigate to the next screen and pass the collected data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotosAndVideosScreen(
          userData: widget.userData, // Pass userData if needed
          collectedData: collectedData, // Pass the collected data
        ),
      ),
    );
  }
}
