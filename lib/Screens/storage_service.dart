import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class StorageService {
  static const String _isFirstLaunchKey = 'isFirstLaunch';

  Future<bool> isFirstLaunch() async {
    if (kIsWeb) {
      return _webIsFirstLaunch();
    } else {
      return _mobileIsFirstLaunch();
    }
  }

  Future<void> setFirstLaunchComplete() async {
    if (kIsWeb) {
      _webSetFirstLaunchComplete();
    } else {
      await _mobileSetFirstLaunchComplete();
    }
  }

  bool _webIsFirstLaunch() {
    final storage = html.window.localStorage;
    return storage[_isFirstLaunchKey] == null;
  }

  void _webSetFirstLaunchComplete() {
    final storage = html.window.localStorage;
    storage[_isFirstLaunchKey] = 'false';
  }

  Future<bool> _mobileIsFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  Future<void> _mobileSetFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }
}