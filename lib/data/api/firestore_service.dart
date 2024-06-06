import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toktar_project/utils/helpers/snackbar_helper.dart';
import 'package:toktar_project/utils/id_generator.dart';
import '../../utils/di/injection_container.dart';
import 'firebase_messaging_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = sl<FirebaseFirestore>();
  final FirebaseAuth _firebaseAuth = sl<FirebaseAuth>();
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();

  late final String _currentUserUid;

  FirestoreService() {
    _currentUserUid = _firebaseAuth.currentUser!.uid;
  }

  Stream<DocumentSnapshot> getUserDocumentStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Stream<QuerySnapshot> getChatListStream() {
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: _currentUserUid)
        .orderBy('last_time', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUsersCollectionStream() {
    return _firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot> getChatMessagesStream(String chatId) {
    return _getMessageStream('messages', chatId);
  }

  Stream<QuerySnapshot> getGroupChatMessages(String chatId) {
    return _getMessageStream('group-conversations', chatId);
  }

  Stream<QuerySnapshot> _getMessageStream(String collection, String chatId) {
    return _firestore
        .collection(collection)
        .doc(chatId)
        .collection('msg_list')
        .orderBy('addtime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getGroupChatsStream() {
    return _firestore.collection('group-conversations').snapshots();
  }

  Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<void> _createChatDocument(String chatId, Map<String, dynamic> chatData) async {
    await _firestore.collection('messages').doc(chatId).set(chatData);
  }

  Future<void> _sendMessage(String chatId, Map<String, dynamic> messageData, String collection,String messageId) async {
    await _firestore
        .collection(collection)
        .doc(chatId)
        .collection('msg_list')
        .doc(messageId)
        .set(messageData);
  }

  Future<String?> getReceiverToken(String receiverUid) async {
    final receiverDoc = await getUserDocument(receiverUid);
    return receiverDoc['fcmToken'] as String?;
  }

  Future<void> _updateLastMessage(String chatId, Map<String, dynamic> lastMessage, String collection) async {
    await _firestore.collection(collection).doc(chatId).update({
      "last_msg": lastMessage,
    });
  }

  Future<void> _createGroupChatDocument(Map<String, dynamic> groupChatData, String groupId) async {
    await _firestore.collection('group-conversations').doc(groupId).set(groupChatData);
  }

  Future<void> updateToken(String? fcmToken) async {
    final user = _firebaseAuth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': fcmToken,
        });
        print('FCM Token updated successfully for user: ${user.uid}');
      } catch (error) {
        print('Error updating FCM Token: $error');
      }
    }
  }

  Future<DocumentSnapshot> _getChatDocument(String chatId) async {
    return await _firestore.collection('messages').doc(chatId).get();
  }

  Future<void> createChatWithUser(String userId) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = IdGenerator.getChatId(currentUserUid, userId);

    try {
      final chatDocSnapshot = await _getChatDocument(chatId);
      if (chatDocSnapshot.exists) {
        print('Chat already exists!');
        SnackbarService.showErrorSnackbar(message: 'Chat already exists!');
        return;
      }

      final chatData = {
        'from_uid': currentUserUid,
        'to_uid': userId,
        'last_msg': {},
        'last_time': DateTime.now(),
        'participants': [currentUserUid, userId],
      };

      await _createChatDocument(chatId, chatData);
      SnackbarService.showSuccessSnackbar(message: 'Chat created successfully!');
    } catch (e) {
      print('Failed to create chat: $e');
      SnackbarService.showErrorSnackbar(message: 'Failed to create chat.');
    }
  }

  Future<void> createGroupChat(String groupName, List<String> participants) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final groupId = IdGenerator.generateGroupId();

    participants.add(currentUserUid);

    final groupChatData = {
      'groupId': groupId,
      'groupName': groupName,
      'participants': participants,
      'createdAt': Timestamp.now(),
      'initiatedBy': currentUserUid,
      'updatedAt': "",
      "last_msg": {}
    };

    try {
      await _createGroupChatDocument(groupChatData, groupId);
      SnackbarService.showSuccessSnackbar(message: 'Group chat created successfully!');
    } catch (error) {
      print('Error creating group chat: $error');
      SnackbarService.showErrorSnackbar(message: 'Failed to create group chat.');
    }
  }

  Future<void> deleteUserChat(String otherUserId) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = IdGenerator.getChatId(currentUserUid, otherUserId);

    try {
      await _firestore.collection('messages').doc(chatId).delete();
      SnackbarService.showSuccessSnackbar(message: 'Chat deleted successfully!');
    } catch (error) {
      print('Error deleting chat: $error');
      SnackbarService.showErrorSnackbar(message: 'Failed to delete chat.');
    }
  }

  Future<void> quitGroup(String groupId) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final groupChatDoc = await _firestore.collection('group-conversations').doc(groupId).get();

      if (groupChatDoc.exists) {
        List<String> participants = List<String>.from(groupChatDoc['participants']);

        participants.remove(currentUserUid);

        await _firestore.collection('group-conversations').doc(groupId).update({
          'participants': participants,
        });

        SnackbarService.showSuccessSnackbar(message: 'Successfully quit the group!');
      } else {
        print('Group chat document does not exist');
        SnackbarService.showErrorSnackbar(message: 'Group chat document does not exist.');
      }
    } catch (error) {
      print('Error quitting group: $error');
      SnackbarService.showErrorSnackbar(message: 'Failed to quit the group.');
    }
  }

  Future<DocumentSnapshot> getGroupChatDoc(String groupId) async {
    return await _firestore.collection('group-conversations').doc(groupId).get();
  }

  Future<bool> updateGroupName(String groupId, String newName) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final groupChatDoc = await _firestore.collection('group-conversations').doc(groupId).get();

      if (groupChatDoc.exists) {
        final Map<String, dynamic> groupChatData = groupChatDoc.data() as Map<String, dynamic>;
        final String initiatedBy = groupChatData['initiatedBy'];

        if (currentUserUid == initiatedBy) {
          await _firestore.collection('group-conversations').doc(groupId).update({
            'groupName': newName,
          });

          SnackbarService.showSuccessSnackbar(message: 'Group name updated successfully!');
          return true;
        } else {
          SnackbarService.showErrorSnackbar(message: 'You are not authorized to change the group name.');
        }
      } else {
        SnackbarService.showErrorSnackbar(message: 'Group chat document does not exist.');
      }
    } catch (error) {
      print('Error updating group name: $error');
      SnackbarService.showErrorSnackbar(message: 'Failed to update group name.');
    }

    return false;
  }

  Future<void> updateGroupPhoto(String groupId) async {
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
            .child('group_chat_photos')
            .child(groupId)
            .child(fileName);
        UploadTask uploadTask = ref.putFile(pickedFile);

        await uploadTask.whenComplete(() async {
          String imageUrl = await ref.getDownloadURL();

          await _firestore.collection('group-conversations').doc(groupId).update({
            'photoUrl': imageUrl,
          });
          SnackbarService.clearSnackbars();
          SnackbarService.showSnackbar(message: 'Group photo updated successfully');
        });
      } catch (e) {
        print('Error uploading image: $e');
        SnackbarService.showErrorSnackbar(message: 'Error uploading image');
      }
    }
  }

  Future<bool> deleteGroupMessage(String groupId, String messageId) async {
    try {
      await _firestore.collection('group-conversations').doc(groupId).collection('msg_list').doc(messageId).delete();
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('group-conversations')
          .doc(groupId)
          .collection('msg_list')
          .orderBy('addtime', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _updateLastMessage(groupId, snapshot.docs.first.data(), "group-conversations");
      }
      else {
        _updateLastMessage(groupId, {}, "group-conversations");
      }

      return true;
    } catch (e) {
      print('Error deleting group message: $e');
      return false;
    }
  }

  Future<bool> updateGroupMessage(String groupId, String messageId, String newMessageContent) async {
    try {
      await _firestore
          .collection('group-conversations')
          .doc(groupId)
          .collection('msg_list')
          .doc(messageId)
          .update(
          {
            'content': newMessageContent,
            'updatedAt' : DateTime.now()
           });
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('group-conversations')
          .doc(groupId)
          .collection('msg_list')
          .orderBy('addtime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && snapshot.docs.first.id == messageId) {
        print(snapshot.docs.first.data());

        _updateLastMessage(groupId, snapshot.docs.first.data(), "group-conversations");
      }
      return true;
    } catch (e) {
      print('Error updating group message: $e');
      return false;
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore.collection('messages').doc(chatId).collection('msg_list').doc(messageId).delete();
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('msg_list')
        .orderBy('addtime', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      print(snapshot.docs.first.data());

      _updateLastMessage(chatId, snapshot.docs.first.data(), "messages");
    }
    else {
      _updateLastMessage(chatId, {}, "messages");
    }




  }

  Future<void> updateMessage(String chatId, String messageId, String newContent) async {
    _firestore.collection('messages').doc(chatId).collection('msg_list').doc(messageId).update({
      'content': newContent,
      'updatedAt' : DateTime.now()
    });
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('msg_list')
        .orderBy('addtime', descending: true)
        .limit(1)
        .get();
    print(snapshot.docs.first.id);
    if (snapshot.docs.isNotEmpty && snapshot.docs.first.id == messageId) {
      print(snapshot.docs.first.data());
      _updateLastMessage(chatId, snapshot.docs.first.data(), "messages");
    }
  }

  Future<void> updateDisplayName(String newDisplayName,String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(
          {
            'name': newDisplayName
          });
    } catch (e) {
      print('Error updating group message: $e');
    }
  }

  void sendMessage(String content,String receiverUid,String chatId,String senderName,String type) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    String messageId = IdGenerator.generateRandomMessageId();
    final messageData = {
      'messageId': messageId,
      'senderUid': currentUserUid,
      'content': content,
      'receiverUid': receiverUid,
      'type': type,
      'addtime': DateTime.now(),
    };

    _sendMessage(chatId, messageData,"messages",messageId);
    _updateLastMessage(chatId, messageData,"messages");
    final receiverToken = await getReceiverToken(receiverUid);

    if (receiverToken != null) {
      print(receiverToken);
      await _firebaseMessagingService.sendPushNotification(receiverToken, content, senderName);
    }
  }

  void sendGroupMessage(String messageContent,String groupId,String type,String senderName) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    String messageId = IdGenerator.generateRandomMessageId();
    final messageData = {
      'messageId': messageId,
      'senderUid': currentUserUid,
      'content': messageContent,
      'groupId': groupId,
      'type': type,
      'addtime': DateTime.now(),
    };

    await _sendMessage(groupId, messageData, "group-conversations",messageId);
    await _updateLastMessage(groupId, messageData, "group-conversations");
    final groupChatDoc = await _firestore.collection('group-conversations').doc(groupId).get();

    List<String> participants = groupChatDoc['participants'];

    participants.removeWhere((element) => element == currentUserUid);

    for (int i = 0; i < participants.length; i++) {
      final receiverToken = await getReceiverToken(participants[i]);
      if (receiverToken != null) {
        print(receiverToken);
        _firebaseMessagingService.sendPushNotification(receiverToken, messageContent, senderName);
      }
    }

  }


}
