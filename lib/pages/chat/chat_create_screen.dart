import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toktar_project/core/constants/constants.dart';
import '../../data/api/firestore_service.dart';
import '../../utils/di/injection_container.dart';

final FirestoreService _firestoreService = sl<FirestoreService>();

class ChatCreateScreen extends StatelessWidget {
  const ChatCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
      ),
      body: StreamBuilder(
        stream: _firestoreService.getUsersCollectionStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          List<QueryDocumentSnapshot> users = snapshot.data?.docs ?? [];
          users.removeWhere((user) => user.id == FirebaseAuth.instance.currentUser!.uid);

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    userData['photoUrl'] ?? defaultUserPhotoUrl,
                  ),
                  onBackgroundImageError: (_, __) => Icon(Icons.error),  // Handle the error icon
                ),
                title: Text(userData['name']),
                subtitle: Text(userData['gmail']),
                onTap: () {
                  _firestoreService.createChatWithUser(userData['id']);

                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createGroupChatDialog(context);
        },
      ),
    );
  }

  Future<void> createGroupChatDialog(BuildContext context) async {
    TextEditingController groupNameController = TextEditingController();

    List<String> selectedParticipants = [];

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: const Text('Create Group Chat'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: groupNameController,
                        decoration: const InputDecoration(labelText: 'Group Name'),
                      ),
                      const SizedBox(height: 20),
                      const Text('Select Participants:'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 300,
                        width: 300,
                        child: StreamBuilder(
                          stream: _firestoreService.getUsersCollectionStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            List<QueryDocumentSnapshot> users = snapshot.data
                                ?.docs ?? [];
                            users.removeWhere((user) =>
                            user.id == FirebaseAuth.instance.currentUser!.uid);

                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                var userData = users[index].data() as Map<
                                    String,
                                    dynamic>;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      userData['photoUrl'] ?? defaultUserPhotoUrl,
                                    ),
                                    onBackgroundImageError: (_, __) => Icon(Icons.error),  // Handle the error icon
                                  ),
                                  title: Text(userData['name']),
                                  subtitle: Text(userData['gmail']),
                                  onTap: () {
                                    setState(() {
                                      // Toggle selection
                                      if (selectedParticipants.contains(
                                          userData['id'])) {
                                        selectedParticipants.remove(
                                            userData['id']);
                                      } else {
                                        selectedParticipants.add(
                                            userData['id']);
                                      }
                                    });
                                  },
                                  // Highlight selected participants
                                  tileColor: selectedParticipants.contains(
                                      userData['id']) ? Colors.blue[100] : null,
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Create'),
                    onPressed: () {
                      String groupName = groupNameController.text.trim();
                      if (groupName.isNotEmpty &&
                          selectedParticipants.isNotEmpty) {
                      _firestoreService.createGroupChat(groupName, selectedParticipants);
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(
                              'Please enter a group name and select participants')),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        }
    );
  }
}