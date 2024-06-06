import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktar_project/core/constants/constants.dart';
import 'package:toktar_project/providers/theme_provider.dart';

class ManageAccountScreen extends StatelessWidget {
  const ManageAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account Page'),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/ChatListScreen", (route) => false);
                },
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String?>(
                      future: getUserProfilePictureLink(userId),
                      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          String? imagePath = snapshot.data;
                          return CircleAvatar(
                            backgroundImage: NetworkImage(
                              imagePath ?? defaultUserPhotoUrl,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          user?.displayName ?? "No Display Name",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.keyboard_arrow_up),
                      ],
                    ),
                    Text(
                      user?.email ?? "No Email",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: SizedBox(
                  width: 30,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, "/ChatListScreen", (route) => false);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const Divider(
                thickness: 1,
                height: 10,
              ),
              ListTile(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamed(context, "/LoginScreen");
                },
                leading: const Icon(
                  Icons.keyboard_double_arrow_left_outlined,
                  color: Colors.red,
                ),
                title: const Text('SIGN OUT'),
              ),
              ListTile(
                onTap: () {
                  Navigator.pushNamed(context, "/UserSettingsScreen");
                },
                leading: const Icon(Icons.settings),
                title: const Text('Change credentials of user'),
              ),
              ListTile(
                onTap: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
                leading: context.read<ThemeProvider>().currentTheme.brightness == Brightness.light
                    ? Icon(
                      Icons.light_mode_rounded,
                      color: Theme.of(context).iconTheme.color,
                    )
                    : Icon(
                  Icons.dark_mode_rounded,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: const Text('Change theme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
