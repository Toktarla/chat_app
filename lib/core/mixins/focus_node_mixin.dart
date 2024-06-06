import 'package:flutter/material.dart';

mixin FocusNodeMixin on StatefulWidget {
  void fieldFocusChange(BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }
}