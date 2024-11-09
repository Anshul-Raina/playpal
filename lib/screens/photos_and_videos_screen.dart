import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playpal/screens/home_screen.dart';
import 'dart:io';
import 'package:playpal/models/user_data.dart';

class PhotosAndVideosScreen extends StatefulWidget {
  final UserData userData;
  final Map<String, dynamic> collectedData; // Accept collected data

  const PhotosAndVideosScreen({
    Key? key,
    required this.userData,
    required this.collectedData, // Use collected data parameter
  }) : super(key: key);

  @override
  State<PhotosAndVideosScreen> createState() => _PhotosAndVideosScreenState();
}

class _PhotosAndVideosScreenState extends State<PhotosAndVideosScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  List<File?> _photoSlots = List<File?>.filled(6, null);
  String? _profileImageUrl;
  List<String> _photoUrls = [];
  bool _isUploading = false; // Flag for loading state

  Future<void> _pickImageForSlot(int index) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (index == -1) {
          _profileImage = File(pickedFile.path);
        } else {
          _photoSlots[index] = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _uploadImagesToFirebase() async {
    setState(() {
      _isUploading = true; // Start uploading state
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      setState(() {
        _isUploading = false; // End uploading state
      });
      return;
    }

    final userId = user.uid;
    final storageRef = FirebaseStorage.instance.ref();

    try {
      // Upload profile image
      if (_profileImage != null) {
        final profileImageRef =
            storageRef.child('users/$userId/profile_image.jpg');
        await profileImageRef.putFile(_profileImage!);
        _profileImageUrl = await profileImageRef.getDownloadURL();
      }

      // Upload additional images
      for (int i = 0; i < _photoSlots.length; i++) {
        if (_photoSlots[i] != null) {
          final imageRef =
              storageRef.child('users/$userId/photos/photo_$i.jpg');
          await imageRef.putFile(_photoSlots[i]!);
          final downloadUrl = await imageRef.getDownloadURL();
          _photoUrls.add(downloadUrl);
        }
      }

      // Update user data with new information
      final updatedUserData = widget.userData.copyWith(
        profileImageUrl: _profileImageUrl ?? widget.userData.profileImageUrl,
        photoUrls: _photoUrls.isEmpty ? widget.userData.photoUrls : _photoUrls,
        completedOnboarding: true,
      );

      // Save all data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
            updatedUserData.toMap(),
            SetOptions(merge: true),
          );

      print("Profile data and images saved successfully!");

      // Navigate to HomeScreen after uploading
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print("Failed to upload images: $e");
    } finally {
      setState(() {
        _isUploading = false; // End uploading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos and Videos'),
      ),
      body: _isUploading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading indicator
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Picture',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickImageForSlot(-1),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Additional Photos (6 Slots)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _photoSlots.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _pickImageForSlot(index),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: _photoSlots[index] != null
                                ? Image.file(_photoSlots[index]!,
                                    fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo,
                                    color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _profileImage == null
                          ? null // Disable button if no profile image is selected
                          : _uploadImagesToFirebase,
                      child: const Text('Finish'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
