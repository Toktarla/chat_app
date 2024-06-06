import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocode/geocode.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:toktar_project/core/constants/constants.dart';
import 'package:toktar_project/utils/helpers/snackbar_helper.dart';

class AuthenticationProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  User? _user;

  User? get user => _user;

  AuthenticationProvider(
      this.firebaseAuth,
      this.googleSignIn,
      this.firebaseFirestore,
      );

  void signInUser(String email, String password, BuildContext context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      Navigator.pushNamedAndRemoveUntil(
          context, "/ChatListScreen", (route) => false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        SnackbarService.showErrorSnackbar(
            message: "No user found for that email");
      } else if (e.code == 'wrong-password') {
        SnackbarService.showErrorSnackbar(
            message: "Wrong password provided for that user");
      } else if (e.message != null &&
          e.message!.contains(
              'The supplied auth credential is incorrect, malformed or has expired')) {
        SnackbarService.showErrorSnackbar(
            message:
            "The supplied auth credential is incorrect, malformed or has expired");
      } else {
        SnackbarService.showErrorSnackbar(message: "Error: ${e.message}");
      }
    } catch (e) {
      SnackbarService.showErrorSnackbar(
          message: "An error occurred: ${e.toString()}");
    }
  }

  void signUpUser(String email, String password, String confirmPassword,
      String fullName, BuildContext context) async {
    try {
      if (password == confirmPassword) {
        final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        User? emailUser = credential.user;
        await emailUser?.updateDisplayName(fullName.trim());

        _user = emailUser;

        final userDoc =
        await firebaseFirestore.collection('users').doc(user!.uid).get();

        if (!userDoc.exists) {
          String? fcmToken = await FirebaseMessaging.instance.getToken();

          await firebaseFirestore.collection('users').doc(_user!.uid).set({
            'addtime': Timestamp.now(),
            'gmail': _user!.email,
            'fcmToken': fcmToken ?? '',
            'id': _user!.uid,
            'location': 'location',
            'name': fullName,
            'photoUrl': _user!.photoURL ?? defaultUserPhotoUrl,
          });
        }
      } else {
        SnackbarService.showErrorSnackbar(message: "Passwords don't match");
      }
      Navigator.pushNamedAndRemoveUntil(context, "/VerifyEmail", (route) => false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        SnackbarService.showErrorSnackbar(message: "No user found for that email");
      } else if (e.code == "email-already-in-use") {
        SnackbarService.showErrorSnackbar(message: "This email already exists. Try another.");
      }
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final UserCredential userCred = await firebaseAuth.signInWithCredential(credential);

      _user = userCred.user;

      final userDoc = await firebaseFirestore.collection('users').doc(_user!.uid).get();

      if (!userDoc.exists) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        // String location = await _getLocation();

        await firebaseFirestore.collection('users').doc(_user!.uid).set({
          'addtime': Timestamp.now(),
          'gmail': _user!.email,
          'fcmToken': fcmToken ?? '',
          'id': _user!.uid,
          'location': 'location',
          'name': _user!.displayName,
          'photoUrl': _user!.photoURL ?? defaultUserPhotoUrl,
        });
      } else {
        if (userDoc['name'] != _user!.displayName &&
            userDoc['photoUrl'] != _user!.photoURL &&
            userDoc['gmail'] != _user!.email) {
          await userDoc.reference.update({
            'name': _user!.displayName,
            'photoUrl': _user!.photoURL ?? defaultUserPhotoUrl,
            'email': _user!.email,
          });
        }
      }

      Navigator.pushNamedAndRemoveUntil(context, "/ChatListScreen", (route) => false);

      notifyListeners();
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      notifyListeners();
    } on Exception catch (_) {
      print('Exception during sign out');
    }
  }


  Future<String> _getLocation() async {
    Position position = await _determinePosition();
    final geo = GeoCode();
    final address = await geo.reverseGeocoding(latitude: position.latitude, longitude: position.longitude);

    return '${address.city ?? ''}, ${address.countryName ?? ''}';
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
