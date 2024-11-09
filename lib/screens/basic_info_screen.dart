import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playpal/screens/personal_preferences_screen.dart';
import 'package:playpal/services/firestore_service.dart';
import 'package:playpal/models/user_data.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({Key? key}) : super(key: key);

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  String? _preferredPronouns;
  String? _location = "Current Location";

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Information'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age <= 0) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(
                      value: 'Non-binary', child: Text('Non-binary')),
                  DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say')),
                ],
                validator: (value) =>
                    value == null ? 'Please select your gender' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _preferredPronouns,
                onChanged: (value) {
                  setState(() {
                    _preferredPronouns = value;
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Preferred Pronouns'),
                items: const [
                  DropdownMenuItem(value: 'He/Him', child: Text('He/Him')),
                  DropdownMenuItem(value: 'She/Her', child: Text('She/Her')),
                  DropdownMenuItem(
                      value: 'They/Them', child: Text('They/Them')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                validator: (value) =>
                    value == null ? 'Please select your pronouns' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: TextEditingController(text: _location),
                decoration: const InputDecoration(labelText: 'Location'),
                readOnly: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final uid =
                        FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
                    final userData = UserData(
                      uid: uid, // Use actual UID
                      name: _nameController.text,
                      age: int.tryParse(_ageController.text) ?? 0,
                      gender: _selectedGender ?? '',
                      pronouns: _preferredPronouns ?? '',
                      location: _location ?? '',
                      relationshipGoal: '',
                      sexualOrientation: '',
                      lookingFor: [],
                      favoriteActivities: [],
                      topFiveFavorites: [],
                      musicPreferences: '',
                      uniqueInterests: '',
                      profileImageUrl: '',
                      photoUrls: [],
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PersonalPreferencesScreen(userData: userData),
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
