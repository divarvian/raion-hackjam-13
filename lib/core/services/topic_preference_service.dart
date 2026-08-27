import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan preferensi topik user
class TopicPreferenceService {
  static const String _keyInterestedTopics = 'interested_topics';

  static Future<List<String>> getInterestedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyInterestedTopics);
    return data ?? [];
  }

  static Future<void> setInterestedTopics(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyInterestedTopics, topics);
  }

  static Future<void> clearInterestedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInterestedTopics);
  }
}
