import 'package:flutter_dotenv/flutter_dotenv.dart';

var pathToFirebaseAdminSdk = dotenv.env['PATH_TO_FIREBASE_ADMIN_SDK'];
var senderId = dotenv.env['SENDER_ID'];
const defaultUserPhotoUrl = 'https://toppng.com/uploads/preview/instagram-default-profile-picture-11562973083brycehrmyv.png';
const String websocketUrl = "ws://10.202.6.92:5000";