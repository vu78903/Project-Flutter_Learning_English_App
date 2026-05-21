import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  static bool _isEnabled = false;
  static bool get isEnabled => _isEnabled;

  static FirebaseAnalytics? _analytics;
  static FirebaseRemoteConfig? _remoteConfig;

  static FirebaseAnalytics? get analytics => _analytics;
  static FirebaseRemoteConfig? get remoteConfig => _remoteConfig;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isEnabled = true;
      _analytics = FirebaseAnalytics.instance;
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _configureRemoteConfig();
      await _configureMessaging();
    } on Object {
      _isEnabled = false;
    }
  }

  static Future<void> _configureRemoteConfig() async {
    final config = _remoteConfig;
    if (config == null) {
      return;
    }

    await config.setDefaults(const {
      'intermediate_exp': 600,
      'advanced_exp': 1500,
      'diamond_exp': 3000,
      'speaking_short_reward': 10,
      'speaking_medium_reward': 18,
      'speaking_long_reward': 25,
      'topic_word_reward': 10,
    });
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await config.fetchAndActivate();
  }

  static Future<void> _configureMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.subscribeToTopic('daily_learning');
    await messaging.subscribeToTopic('new_lessons');
  }

  static int intConfig(String key, int fallback) {
    final config = _remoteConfig;
    if (!_isEnabled || config == null) {
      return fallback;
    }
    final value = config.getInt(key);
    return value == 0 ? fallback : value;
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_isEnabled) {
      return;
    }
    await _analytics?.logEvent(name: name, parameters: parameters);
  }
}
