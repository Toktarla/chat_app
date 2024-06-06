import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:toktar_project/data/api/firebase_messaging_service.dart';
import 'package:toktar_project/data/api/firestore_service.dart';

import 'package:mockito/annotations.dart';
import 'main.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  FirebaseMessagingService,
  User,
  DocumentReference,
  CollectionReference,
  QuerySnapshot,
  DocumentSnapshot,
  Query,
])
void main() {
  late FirestoreService firestoreService;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseMessagingService mockMessagingService;
  late MockUser mockUser;
  late MockDocumentReference mockDocRef;
  late MockCollectionReference mockCollectionRef;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockQuery mockQuery;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockMessagingService = MockFirebaseMessagingService();
    mockUser = MockUser();
    mockDocRef = MockDocumentReference();
    mockCollectionRef = MockCollectionReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockQuery = MockQuery();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('testUid');
    when(mockFirestore.collection(any)).thenReturn(mockCollectionRef as CollectionReference<Map<String, dynamic>>);
    when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
    when(mockDocRef.snapshots()).thenAnswer((_) => Stream.value(mockDocumentSnapshot));

    firestoreService = FirestoreService();
  });

  group('FirestoreService', () {
    test('getUserDocumentStream returns user document stream', () {
      when(mockDocRef.snapshots()).thenAnswer((_) => Stream.value(mockDocumentSnapshot));

      final stream = firestoreService.getUserDocumentStream('testUserId');

      expect(stream, isA<Stream<DocumentSnapshot>>());
    });

    test('getChatListStream returns chat list stream', () {
      when(mockCollectionRef.where(any, arrayContains: anyNamed('arrayContains'))).thenReturn(mockQuery);
      when(mockQuery.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final stream = firestoreService.getChatListStream();

      expect(stream, isA<Stream<QuerySnapshot>>());
    });

    test('getUsersCollectionStream returns users collection stream', () {
      when(mockCollectionRef.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final stream = firestoreService.getUsersCollectionStream();

      expect(stream, isA<Stream<QuerySnapshot>>());
    });

    test('getChatMessagesStream returns chat messages stream', () {
      when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.collection(any)).thenReturn(mockCollectionRef as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionRef.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final stream = firestoreService.getChatMessagesStream('testChatId');

      expect(stream, isA<Stream<QuerySnapshot>>());
    });

    test('getGroupChatMessages returns group chat messages stream', () {
      when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.collection(any)).thenReturn(mockCollectionRef as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionRef.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final stream = firestoreService.getGroupChatMessages('testGroupId');

      expect(stream, isA<Stream<QuerySnapshot>>());
    });

    test('getGroupChatsStream returns group chats stream', () {
      when(mockCollectionRef.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final stream = firestoreService.getGroupChatsStream();

      expect(stream, isA<Stream<QuerySnapshot>>());
    });

    test('getUserDocument returns user document', () async {
      when(mockDocRef.get()).thenAnswer((_) async => mockDocumentSnapshot);

      final doc = await firestoreService.getUserDocument('testUserId');

      expect(doc, isA<DocumentSnapshot>());
    });

    test('deleteUserChat deletes a user chat', () async {
      final chatId = 'chatId';
      when(mockFirestore.collection('messages').doc(chatId).delete())
          .thenAnswer((_) async => Future.value());

      await firestoreService.deleteUserChat('testUserId');

      verify(mockFirestore.collection('messages').doc(chatId).delete()).called(1);
    });

  });
}