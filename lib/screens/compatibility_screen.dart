import 'package:flutter/material.dart';

class CompatibilityScreen extends StatefulWidget {
  @override
  _CompatibilityScreenState createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  // Initial question responses (replace with your own logic for storing answers)
  Map<String, int> responses = {
    'extroversion': 3,
    'partner_extroversion': 3,
    'communication_style': 3,
    'partner_communication_style': 3,
    'free_time_preference': 3,
    'physical_activity_importance': 3,
    'socializing_frequency': 3,
    'partner_socializing_importance': 3,
    'shared_religious_beliefs': 3,
    'ambition': 3,
    'partner_ambition': 3,
    'financial_stability_importance': 3,
    'financial_responsibility': 3,
  };

  // Drag-and-drop categories
  List<String> categories = [
    'Personality & Preferences',
    'Lifestyle & Social Preferences',
    'Values & Deal-Breakers',
    'Career Ambitions & Financial Attitudes',
    'Interests & Hobbies'
  ];

  // Category weights, initialized in order of the categories above
  Map<String, double> categoryWeights = {
    'Personality & Preferences': 30,
    'Lifestyle & Social Preferences': 25,
    'Values & Deal-Breakers': 20,
    'Career Ambitions & Financial Attitudes': 15,
    'Interests & Hobbies': 10
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compatibility Setup'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Display questions with sliders
                buildQuestion('How extroverted are you?', 'extroversion'),
                buildQuestion(
                    'How extroverted would you like your partner to be?',
                    'partner_extroversion'),
                buildQuestion(
                    'How do you prefer to communicate in a relationship?',
                    'communication_style'),
                buildQuestion('How do you prefer your partner to communicate?',
                    'partner_communication_style'),
                buildQuestion('How do you prefer to spend your free time?',
                    'free_time_preference'),
                buildQuestion(
                    'How important is it to do physical activities together?',
                    'physical_activity_importance'),
                buildQuestion(
                    'How often do you prefer to socialize with friends?',
                    'socializing_frequency'),
                buildQuestion(
                    'How important is it that your partner enjoys socializing as much as you?',
                    'partner_socializing_importance'),
                buildQuestion(
                    'How important are shared religious/spiritual beliefs?',
                    'shared_religious_beliefs'),
                buildQuestion(
                    'How ambitious are you when it comes to your career?',
                    'ambition'),
                buildQuestion(
                    'How ambitious would you like your partner to be?',
                    'partner_ambition'),
                buildQuestion('How important is financial stability to you?',
                    'financial_stability_importance'),
                buildQuestion(
                    'Do you prefer to share financial responsibilities equally?',
                    'financial_responsibility'),

                // Drag-and-Drop Section for Priorities
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Drag and drop to prioritize what matters most to you:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  onReorder: _onReorderCategories,
                  children: [
                    for (final category in categories)
                      ListTile(
                        key: ValueKey(category),
                        title: Text(category),
                        trailing: Text('${categoryWeights[category]}%'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _saveCompatibilitySettings,
            child: Text('Save Preferences'),
          ),
        ],
      ),
    );
  }

  // Function to build sliders for the questionnaire section
  Widget buildQuestion(String question, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question),
          Slider(
            value: responses[key]?.toDouble() ?? 3.0,
            min: 1,
            max: 5,
            divisions: 4,
            label: responses[key]?.toString(),
            onChanged: (double value) {
              setState(() {
                responses[key] = value.toInt();
              });
            },
          ),
        ],
      ),
    );
  }

  // Handling drag-and-drop reordering
  void _onReorderCategories(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String movedCategory = categories.removeAt(oldIndex);
      categories.insert(newIndex, movedCategory);

      // Update weights after reordering
      _updateCategoryWeights();
    });
  }

  // Automatically update weights based on new order
  void _updateCategoryWeights() {
    final List<double> newWeights = [35, 25, 20, 15, 5];
    for (int i = 0; i < categories.length; i++) {
      categoryWeights[categories[i]] = newWeights[i];
    }
  }

  // Save button logic
  void _saveCompatibilitySettings() {
    // Save preferences and navigate to the next screen or profile setup
    print('Compatibility settings saved!');
    print('Questionnaire responses: $responses');
    print('Category priorities: $categoryWeights');
  }
}
