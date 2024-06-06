import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:toktar_project/utils/helpers/snackbar_helper.dart';
import 'package:toktar_project/widgets/colored_circle.dart';

import '../../data/api/firestore_service.dart';
import '../../utils/di/injection_container.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({Key? key, required this.groupId, required this.groupName}) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {

  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = sl<FirestoreService>();

  String? groupPhotoUrl;

  bool _isUpdatingMessage = false;
  late String _messageIdToUpdate;

  Future<void> _pickAndUploadImage(String senderName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;
      File pickedFile = File(file.path ?? '');

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('group_chat_images')
            .child(widget.groupId)
            .child(fileName);
        UploadTask uploadTask = ref.putFile(pickedFile);

        await uploadTask.whenComplete(() async {
          String imageUrl = await ref.getDownloadURL();

          _firestoreService.sendGroupMessage(
            imageUrl, widget.groupId,'image',senderName
          );
        });
      } catch (e) {
        print('Error uploading image: $e');
        SnackbarService.showErrorSnackbar(message: 'Error uploading image');
      }
    }
  }

  void _showMessageOptions(String messageId,Map<String, dynamic> messageData,String type) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _firestoreService.deleteGroupMessage(widget.groupId, messageId);
              },
            ),
            if (type == 'text')
              ListTile(
              title: const Text('Update Message'),
              onTap: () {
                setState(() {
                  _isUpdatingMessage = true;
                  _messageIdToUpdate = messageData['messageId'];
                  _messageController.text = messageData['content'];
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateMessage() {
    String newContent = _messageController.text.trim();
    if (newContent.isNotEmpty) {
      _firestoreService.updateGroupMessage(widget.groupId, _messageIdToUpdate, newContent);
      _messageController.clear();
      setState(() {
        _isUpdatingMessage = false;
      });
    }
  }

  Future<void> _updateGroupName() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newGroupName = '';

        return AlertDialog(
          title: const Text('Update Group Name'),
          content: TextField(
            onChanged: (value) {
              newGroupName = value;
            },
            decoration: const InputDecoration(hintText: 'Enter new group name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                bool success = await _firestoreService.updateGroupName(widget.groupId, newGroupName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Group name updated successfully' : 'Only the group initiator can update the group name'),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          DropdownButton<String>(
            icon: const Icon(Icons.more_vert_outlined),
            items: [
              const DropdownMenuItem(
                value: 'updateName',
                child: Text('Update Group Name'),
              ),
              const DropdownMenuItem(
                value: 'updatePhoto',
                child: Text('Update Group Photo'),
              ),
            ],
            onChanged: (value) {
              if (value == 'updateName') {
                _updateGroupName();
              } else if (value == 'updatePhoto') {
                 _firestoreService.updateGroupPhoto(widget.groupId);
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getGroupChatMessages(widget.groupId),
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

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                      bool isCurrentUser =
                          messageData['senderUid'] == FirebaseAuth
                              .instance.currentUser!.uid;
                      Color messageColor = isCurrentUser ? Colors.green : Colors.blue;
                      return FutureBuilder(
                        future: _firestoreService.getUserDocument(
                            messageData['senderUid']),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Loading...'),
                            );
                          }
                          if (userSnapshot.hasError) {
                            return ListTile(
                              title: Text('Error: ${userSnapshot.error}'),
                            );
                          }
                          var userData = userSnapshot.data!.data()
                          as Map<String, dynamic>;
                          return GestureDetector(
                            onLongPress: (){
                              _showMessageOptions(messageData['messageId'],messageData,messageData['type']);
                            },
                            child: Row(
                              mainAxisAlignment: isCurrentUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Flexible(

                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: messageColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userData['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5,),
                                        messageData['type'] == 'image'
                                            ? Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Image.network(messageData['content']),
                                        )
                                            : Text(
                                          messageData['content'],
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                return const Center(
                  child: Text('No messages found.'),
                );
              },
            ),
          ),


          (!_isUpdatingMessage)
            ?
            Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    _pickAndUploadImage('');
                  },
                  icon: const Icon(Icons.image),
                  color: Colors.blueAccent,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  onPressed: () {
                    String messageContent =
                    _messageController.text.trim();
                    _messageController.clear();
                    if (messageContent.isNotEmpty) {
                    _firestoreService.sendGroupMessage(messageContent,widget.groupId,'text','');
                    }
                  },
                  icon: const Icon(Icons.send),
                  color: Colors.blueAccent,

                ),
              ],
            ),
          )
            :
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Update your message',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isUpdatingMessage = false;
                        _messageController.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _updateMessage,
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}




