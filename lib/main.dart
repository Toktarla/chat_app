import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktar_project/core/routes/routes.dart';
import 'package:toktar_project/pages/auth/register_screen.dart';
import 'package:toktar_project/providers/providers.dart';
import 'package:toktar_project/utils/di/injection_container.dart';
import 'data/api/firebase_messaging_service.dart';
import 'config/firebase/firebase_options.dart';
import 'data/services/local_notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/helpers/snackbar_helper.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initializeDependencies();

  LocalNotificationService.initialize();
  FirebaseMessagingService.initialize();


  await dotenv.load(fileName: ".env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    FirebaseMessagingService.messageListener();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(sl())),
        ChangeNotifierProvider<CallProvider>(
            create: (_) => CallProvider()),
        ChangeNotifierProvider<AuthenticationProvider>(
            create: (_) => AuthenticationProvider(sl(), sl(), sl())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider,child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateRoute: AppRoutes.onGenerateRoutes,
            title: 'Google Sign In',
            home: const RegisterPage(),
            scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,
            theme: themeProvider.currentTheme
          );
        },
      ),
    );
  }
}




