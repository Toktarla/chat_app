import 'package:flutter/material.dart';
import 'package:toktar_project/pages/auth/login_screen.dart';
import 'package:toktar_project/pages/auth/register_screen.dart';
import 'package:toktar_project/pages/chat/chat_create_screen.dart';
import 'package:toktar_project/pages/chat/chat_screen.dart';
import 'package:toktar_project/pages/chat/group_chat_screen.dart';
import 'package:toktar_project/pages/settings/manage_account_screen.dart';

import '../../pages/auth/verify_email_screen.dart';
import '../../pages/chat/chat_list_screen.dart';
import '../../pages/settings/user_settings_screen.dart';
import '../errors/error_screen.dart';

class AppRoutes {
  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/ChatListScreen':
        return _materialRoute(ChatListScreen());

      case '/ChatCreateScreen':
        return _materialRoute(ChatCreateScreen());
      case '/LoginScreen':
        return _materialRoute(LoginPage());
      case '/ManageAccountScreen':
        return _materialRoute(ManageAccountScreen());
      case '/RegisterScreen':
        return _materialRoute(RegisterPage());
      case '/VerifyEmail':
        return _materialRoute(VerifyEmailPage());
      case '/UserSettingsScreen':
        return _materialRoute(UserSettingsScreen());
      case '/ChatScreen':
        final args = settings.arguments as Map<String, dynamic>;
        return _materialRoute(ChatScreen(
            chatId: args['chatId'],
            name: args['name'],
            receiverUid: args['receiverUid'],
            senderName: args['senderName']
        ));
      case '/GroupChatScreen':
        final args = settings.arguments as Map<String, dynamic>;
        return _materialRoute(GroupChatScreen(
            groupId: args['groupId'],
          groupName: args['groupName'],
        ));
      default:
        return _materialRoute(const ErrorPage());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(
      builder: (_) => view,
    );
  }
}