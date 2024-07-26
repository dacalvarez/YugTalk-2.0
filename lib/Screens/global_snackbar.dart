import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';

class GlobalSnackBar {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get key => _scaffoldMessengerKey;

  static void show(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: GText(message)),
    );
  }
}