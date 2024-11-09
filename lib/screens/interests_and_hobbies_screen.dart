// // interests_and_hobbies_screen.dart
// import 'package:flutter/material.dart';
// import 'package:playpal/screens/photos_and_videos_screen.dart';
// import 'package:playpal/models/user_data.dart';

// class InterestsAndHobbiesScreen extends StatefulWidget {
//   final UserData userData;

//   const InterestsAndHobbiesScreen({Key? key, required this.userData})
//       : super(key: key);

//   @override
//   State<InterestsAndHobbiesScreen> createState() =>
//       _InterestsAndHobbiesScreenState();
// }

// class _InterestsAndHobbiesScreenState extends State<InterestsAndHobbiesScreen> {
//   final TextEditingController _musicPreferencesController =
//       TextEditingController();
//   final TextEditingController _uniqueInterestsController =
//       TextEditingController();
//   List<String> _favoriteActivities = [];

//   @override
//   void dispose() {
//     _musicPreferencesController.dispose();
//     _uniqueInterestsController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Interests and Hobbies'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _musicPreferencesController,
//               decoration: const InputDecoration(labelText: 'Music Preferences'),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _uniqueInterestsController,
//               decoration: const InputDecoration(labelText: 'Unique Interests'),
//             ),
//             const SizedBox(height: 16),
//             Wrap(
//               spacing: 8.0,
//               children: ['Hiking', 'Reading', 'Gaming', 'Traveling']
//                   .map((activity) => ChoiceChip(
//                         label: Text(activity),
//                         selected: _favoriteActivities.contains(activity),
//                         onSelected: (selected) {
//                           setState(() {
//                             if (selected) {
//                               _favoriteActivities.add(activity);
//                             } else {
//                               _favoriteActivities.remove(activity);
//                             }
//                           });
//                         },
//                       ))
//                   .toList(),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: () {
//                 final updatedUserData = widget.userData.copyWith(
//                   favoriteActivities: _favoriteActivities,
//                   musicPreferences: _musicPreferencesController.text,
//                   uniqueInterests: _uniqueInterestsController.text,
//                 );

//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         PhotosAndVideosScreen(userData: updatedUserData),
//                   ),
//                 );
//               },
//               child: const Text('Next'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
