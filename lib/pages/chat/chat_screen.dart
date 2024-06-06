import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktar_project/data/services/signaling_service.dart';
import 'package:toktar_project/providers/call_provider.dart';

import '../../data/api/firestore_service.dart';
import '../../utils/di/injection_container.dart';
import '../call/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverUid;
  final String name;
  final String senderName;

  const ChatScreen({Key? key, required this.chatId, required this.receiverUid, required this.name, required this.senderName}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = sl<FirestoreService>();
  bool _isUpdatingMessage = false;
  late String _messageIdToUpdate;

  @override
  void initState() {
    SignallingService.instance.socket!.on("newCall", (data) {
      if (mounted) {
        setState(() => Provider.of<CallProvider>(context, listen: false).incomingSDPOffer = data);
      }
    });
    super.initState();
  }

  Future<void> _pickAndUploadImage() async {
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
            .child('chat_images')
            .child(widget.chatId)
            .child(fileName);
        UploadTask uploadTask = ref.putFile(pickedFile);

        await uploadTask.whenComplete(() async {
          String imageUrl = await ref.getDownloadURL();

          _firestoreService.sendMessage(
            imageUrl, widget.receiverUid, widget.chatId, widget.senderName,'image',
          );
        });
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error uploading image'),
          ),
        );
      }
    }
  }

  _joinCall({required String callerId, required String calleeId, dynamic offer,}) {
    if (Provider.of<CallProvider>(context, listen: false).incomingSDPOffer != null) {
      _storeCallInformation(
        callerId: callerId,
        receiverId: calleeId,
        startTime: DateTime.now(),
      );
      Provider.of<CallProvider>(context, listen: false).resetIncomingSDPOffer();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
        ),
      ),
    );
  }

  void _storeCallInformation({
    required String callerId,
    required String receiverId,
    required DateTime startTime,
  }) {
    DocumentReference callInfoRef = FirebaseFirestore.instance.collection('call_information').doc();

    callInfoRef.set({
      'callerId': callerId,
      'receiverId': receiverId,
      'startTime': startTime,
    }).then((value) {
      print('Call information stored successfully');
    }).catchError((error) {
      print('Failed to store call information: $error');
    });
  }

  void _showMessageOptions(Map<String, dynamic> messageData,String type) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _firestoreService.deleteMessage(widget.chatId, messageData['messageId']);
              },
            ),
            if (type == 'text')
            ListTile(
              title: Text('Update Message'),
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
      _firestoreService.updateMessage(widget.chatId, _messageIdToUpdate, newContent);
      _messageController.clear();
      setState(() {
        _isUpdatingMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            onPressed: () {
              _joinCall(
                callerId: FirebaseAuth.instance.currentUser!.uid,
                calleeId: widget.receiverUid,
              );
            },
            icon: Icon(Icons.video_call),
          ),
        ],
      ),
      body: Column(
        children: [
          if (Provider.of<CallProvider>(context, listen: false).incomingSDPOffer != null)
            ListTile(
              title: Text(
                "Incoming Call from ${Provider.of<CallProvider>(context, listen: false).incomingSDPOffer["callerId"]}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    color: Colors.redAccent,
                    onPressed: () {
                      setState(() => Provider.of<CallProvider>(context, listen: false).incomingSDPOffer = null);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    color: Colors.greenAccent,
                    onPressed: () {
                      _joinCall(
                        callerId: Provider.of<CallProvider>(context, listen: false).incomingSDPOffer["callerId"]!,
                        calleeId: FirebaseAuth.instance.currentUser!.uid,
                        offer: Provider.of<CallProvider>(context, listen: false).incomingSDPOffer["sdpOffer"],
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getChatMessagesStream(widget.chatId),
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
                      var messageData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      bool isCurrentUser = messageData['senderUid'] == FirebaseAuth.instance.currentUser!.uid;
                      return GestureDetector(
                        onLongPress: () {
                          _showMessageOptions(messageData,messageData['type']);
                        },
                        child: Row(
                          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isCurrentUser ? Colors.green : Colors.blueAccent,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isCurrentUser ? 20 : 0),
                                    bottomRight: Radius.circular(isCurrentUser ? 0 : 20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                }
                return const Center(
                  child: Text('No messages found.'),
                );
              },
            ),
          ),
          if (!_isUpdatingMessage)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pickAndUploadImage,
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
                      String messageContent = _messageController.text.trim();
                      _messageController.clear();
                      if (messageContent.isNotEmpty) {
                        _firestoreService.sendMessage(messageContent, widget.receiverUid, widget.chatId, widget.senderName,'text');
                      }
                    },
                    icon: const Icon(Icons.send),
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
          if (_isUpdatingMessage)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Update your message',
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
                    onPressed: _updateMessage,
                    icon: const Icon(Icons.check),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
