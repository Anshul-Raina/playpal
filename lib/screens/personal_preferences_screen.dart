import 'package:flutter/material.dart';
import 'package:playpal/screens/fun_prompts_screen.dart';
import 'package:playpal/models/user_data.dart';

class PersonalPreferencesScreen extends StatefulWidget {
  final UserData userData;

  const PersonalPreferencesScreen({Key? key, required this.userData})
      : super(key: key);

  @override
  State<PersonalPreferencesScreen> createState() =>
      _PersonalPreferencesScreenState();
}

class _PersonalPreferencesScreenState extends State<PersonalPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _relationshipGoal;
  String? _sexualOrientation;
  List<String> _lookingFor = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _relationshipGoal,
                onChanged: (value) {
                  setState(() {
                    _relationshipGoal = value;
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Relationship Goals'),
                items: const [
                  DropdownMenuItem(
                      value: 'Casual Dating', child: Text('Casual Dating')),
                  DropdownMenuItem(
                      value: 'Long-Term Relationship',
                      child: Text('Long-Term Relationship')),
                  DropdownMenuItem(
                      value: 'Just Friends', child: Text('Just Friends')),
                ],
                validator: (value) => value == null
                    ? 'Please select your relationship goal'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sexualOrientation,
                onChanged: (value) {
                  setState(() {
                    _sexualOrientation = value;
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Sexual Orientation'),
                items: const [
                  DropdownMenuItem(value: 'Straight', child: Text('Straight')),
                  DropdownMenuItem(value: 'Gay', child: Text('Gay')),
                  DropdownMenuItem(value: 'Bisexual', child: Text('Bisexual')),
                  DropdownMenuItem(
                      value: 'Pansexual', child: Text('Pansexual')),
                  DropdownMenuItem(value: 'Asexual', child: Text('Asexual')),
                ],
                validator: (value) => value == null
                    ? 'Please select your sexual orientation'
                    : null,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                children: [
                  FilterChip(
                    label: const Text('Friends'),
                    selected: _lookingFor.contains('Friends'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _lookingFor.add('Friends');
                        } else {
                          _lookingFor.remove('Friends');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Dates'),
                    selected: _lookingFor.contains('Dates'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _lookingFor.add('Dates');
                        } else {
                          _lookingFor.remove('Dates');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Activity Partners'),
                    selected: _lookingFor.contains('Activity Partners'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _lookingFor.add('Activity Partners');
                        } else {
                          _lookingFor.remove('Activity Partners');
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final updatedUserData = widget.userData.copyWith(
                      relationshipGoal: _relationshipGoal ?? '',
                      sexualOrientation: _sexualOrientation ?? '',
                      lookingFor: _lookingFor,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FunPromptsScreen(userData: updatedUserData),
                      ),
                    );
                  }
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
