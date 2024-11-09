import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterScreen({Key? key, required this.onApplyFilters})
      : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  double _minAge = 18;
  double _maxAge = 100;
  String _location = '';
  List<String> _selectedInterests = [];
  String _relationshipGoal = '';

  // Example interests
  final List<String> _interests = ['Hiking', 'Reading', 'Gaming', 'Cooking'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Profiles'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Age Range Slider
            RangeSlider(
              values: RangeValues(_minAge, _maxAge),
              min: 18,
              max: 100,
              divisions: 82,
              labels: RangeLabels('$_minAge', '$_maxAge'),
              onChanged: (values) {
                setState(() {
                  _minAge = values.start;
                  _maxAge = values.end;
                });
              },
            ),
            Text('Age Range: $_minAge - $_maxAge'),

            // Location Input
            TextField(
              decoration: const InputDecoration(labelText: 'Location'),
              onChanged: (value) {
                setState(() {
                  _location = value;
                });
              },
            ),

            // Interests Selection
            Wrap(
              children: _interests.map((interest) {
                return ChoiceChip(
                  label: Text(interest),
                  selected: _selectedInterests.contains(interest),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            // Relationship Goal
            DropdownButton<String>(
              hint: const Text('Select Relationship Goal'),
              value: _relationshipGoal.isEmpty ? null : _relationshipGoal,
              items: ['Friendship', 'Casual', 'Long-term']
                  .map((goal) => DropdownMenuItem(
                        value: goal,
                        child: Text(goal),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _relationshipGoal = value ?? '';
                });
              },
            ),

            // Apply Filters Button
            ElevatedButton(
              onPressed: () {
                widget.onApplyFilters({
                  'ageRange': {'min': _minAge, 'max': _maxAge},
                  'location': _location,
                  'interests': _selectedInterests,
                  'relationshipGoal': _relationshipGoal,
                });
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
