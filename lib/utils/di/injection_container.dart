import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:toktar_project/data/api/firebase_messaging_service.dart';
import 'package:toktar_project/data/api/firestore_service.dart';
import 'package:toktar_project/data/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

void initializeDependencies() async {

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Dependencies

  sl.registerLazySingleton<GoogleSignIn>(()=>GoogleSignIn());
  sl.registerLazySingleton<FirebaseFirestore>(()=>FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(()=>FirebaseAuth.instance);


  // Services, API

  sl.registerLazySingleton<FirebaseMessagingService>(() => FirebaseMessagingService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());

  sl.registerSingleton<LocalNotificationService>(LocalNotificationService());
}
