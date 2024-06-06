import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toktar_project/core/constants/constants.dart';
import 'package:toktar_project/utils/di/injection_container.dart';
import 'package:toktar_project/utils/id_generator.dart';
import 'package:toktar_project/widgets/colored_circle.dart';
import '../../data/api/firestore_service.dart';
import 'package:toktar_project/data/services/signaling_service.dart';


class ChatListScreen extends StatelessWidget {
  final FirestoreService _firestoreService = sl<FirestoreService>();

  Widget _buildSubtitle(Map<String, dynamic> lastMessage) {
    if (lastMessage['type'] == "image") {
      return Row(
        children: [
          Icon(Icons.photo_camera),
          SizedBox(width: 3),
          Text('Photo'),
        ],
      );
    } else if (lastMessage['type'] == "text") {
      return Text(lastMessage['content'] ?? "");
    } else {
      return const Text('');
    }
  }
  @override
  Widget build(BuildContext context) {
    SignallingService.instance.init(
      websocketUrl: websocketUrl,
      selfCallerID: FirebaseAuth.instance.currentUser!.uid
    );


    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 30,
              ),
              items: <String>['User Settings'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue == 'User Settings') {
                  Navigator.pushNamed(context, '/ManageAccountScreen');
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder(
              stream: _firestoreService.getChatListStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                // Displaying chat list
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  return SizedBox(
                    width: double.infinity,
                    height: 400,
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var messageData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        String otherUserId = messageData['to_uid'] == FirebaseAuth.instance.currentUser!.uid
                            ? messageData['from_uid']
                            : messageData['to_uid'];

                        return FutureBuilder(
                          future: _firestoreService.getUserDocument(otherUserId),
                          builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const ListTile(
                                title: Text('Loading...'),
                              );
                            }

                            if (userSnapshot.hasError) {
                              return ListTile(
                                title: Text('Error: ${userSnapshot.error}'),
                              );
                            }

                            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            var name = {};
                            var data = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get().then((value) => name = value.data() as Map<String,dynamic>);

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              color: Theme.of(context).primaryColor,
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                              child: ListTile(
                                title: Text(userData['name'] ?? ""),
                                subtitle: _buildSubtitle(messageData['last_msg']),
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(userData['photoUrl'] ?? defaultUserPhotoUrl),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: (){
                                    _firestoreService.deleteUserChat(userData['id'] ?? "");
                                  },
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context,'/ChatScreen',arguments: {
                                    'chatId': IdGenerator.getChatId(FirebaseAuth.instance.currentUser!.uid, otherUserId),
                                    'receiverUid': otherUserId,
                                    'name': userData['name'] ?? "",
                                    'senderName': name['name'],
                                  });

                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                // Display a message if no chats found
                return const Center(
                  child: Text('No chats found.'),
                );
              },
            ),
            const SizedBox(height: 10,),
            Text('Groups: ',style: Theme.of(context).textTheme.titleMedium),
            StreamBuilder(
              stream: _firestoreService.getGroupChatsStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                final groupChats = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String,dynamic>;
                  final List<String> participants = List<String>.from(data['participants']);
                  return participants.contains(FirebaseAuth.instance.currentUser!.uid);
                }).toList();
                // Displaying group chat list
                if (groupChats.isNotEmpty) {
                  return SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: ListView.builder(
                      itemCount: groupChats.length,
                      itemBuilder: (context, index) {
                        var groupChatData = groupChats[index].data() as Map<String, dynamic>;
                        List<String> participants = List<String>.from(groupChatData['participants']);
                        String groupId = groupChatData['groupId'];
                        bool isAdmin = groupChatData['initiatedBy'] == FirebaseAuth.instance.currentUser!.uid;
                        Map<String,dynamic> lastMessage = groupChatData['last_msg'];

                        String groupName = groupChatData['groupName'];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),

                          color: Theme.of(context).primaryColor,
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: ListTile(
                            title: Text(groupName),
                            subtitle: _buildSubtitle(lastMessage),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: groupChatData['photoUrl'] != null
                                  ? NetworkImage(groupChatData['photoUrl']!)
                                  : const NetworkImage(defaultUserPhotoUrl),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ColoredCircle(radius: 5, color: isAdmin ? Colors.green : Colors.grey,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.exit_to_app),
                                  onPressed: (){
                                    _firestoreService.quitGroup(groupId);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pushNamed(context,'/GroupChatScreen',arguments: {
                                'groupId': groupId,
                                'groupName': groupName
                              });
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
                return const Center(
                  child: Text('No group chats found.'),
                );
              },
            ),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/ChatCreateScreen');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
