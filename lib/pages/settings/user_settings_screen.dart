import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:toktar_project/core/constants/constants.dart';
import 'package:toktar_project/utils/di/injection_container.dart';

import '../../data/api/firestore_service.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _firestoreService = sl<FirestoreService>();
    User? user = FirebaseAuth.instance.currentUser;
    final fullNameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? userId = user?.uid;

    Future<String?> getUserProfilePictureLink(String? userId) async {
      String? profilePicLink;
      try {
        DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userProfileSnapshot.exists) {
          profilePicLink = userProfileSnapshot.get('photoUrl');
        }
      } catch (e) {
        print('Error fetching user profile picture link: $e');
      }
      return profilePicLink;
    }

    Future<void> uploadProfilePicture() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        File pickedFile = File(file.path ?? '');

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child(user?.uid ?? 'default')
            .child('profile_pic.jpg');

        UploadTask uploadTask = ref.putFile(pickedFile);

        try {
          await uploadTask.whenComplete(() async {
            String imageURL = await ref.getDownloadURL();

            if (userId != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'photoUrl': imageURL});
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Profile picture updated successfully'),
              ),
            );
          });
        } catch (error) {
          print(error);
        }
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Modify user credentials"),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const SizedBox(
                height: 30,
              ),
              Center(
                child: FutureBuilder<String?>(
                  future: getUserProfilePictureLink(userId),
                  builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      String? imagePath = snapshot.data;
                      return CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                            imagePath ?? defaultUserPhotoUrl
                        )
                      );
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).appBarTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: uploadProfilePicture,
                    child: const Text("Upload File"),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                height: 10,
              ),
              // Display Name
              const Text(
                'Change user display name',
                style: TextStyle(color: Colors.black54, fontSize: 18),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: TextFormField(
                    onFieldSubmitted: (newDisplayName) async {
                      if (newDisplayName != user?.displayName) {
                        try {
                          await user?.updateDisplayName(newDisplayName);
                          _firestoreService.updateDisplayName(newDisplayName,userId ?? "");
                          fullNameController.clear();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text('Display name updated successfully'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Failed to update display name'),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('It is the same display name'),
                          ),
                        );
                      }
                    },
                    keyboardType: TextInputType.name,
                    controller: fullNameController,
                    decoration: InputDecoration(
                      hintText: 'Current : ${user?.displayName ?? "No display name"}',
                      border: InputBorder.none,
                    ),
                    validator: (fullName) {
                      final namePattern = RegExp(r'^[A-Z][a-z]+\s[A-Z][a-z]+$');
                      if (fullName == null || fullName.isEmpty) {
                        return 'Please enter your full name';
                      } else if (!namePattern.hasMatch(fullName.trim())) {
                        return 'Please enter a valid full name like "Toktar Sultan"';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // Password
              const Text(
                'Change user password',
                style: TextStyle(color: Colors.black54, fontSize: 18),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: TextFormField(
                    onFieldSubmitted: (newPassword) async {
                      if (newPassword.length >= 8) {
                        try {
                          await user?.updatePassword(newPassword);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text('Password updated successfully'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Failed to update password'),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('Password must be at least 8 characters'),
                          ),
                        );
                      }
                    },
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: 'New Password',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value != null && value.length < 8) {
                        return "Password must be 8 chars";
                      } else {
                        return null;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
