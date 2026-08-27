import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../domain/flashcard_category_model.dart';
import '../domain/flashcard_topic_model.dart';
import '../domain/flashcard_model.dart';
import '../domain/user_flashcard_progress_model.dart';

class FlashcardRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<FlashcardCategory>> getCategories() async {
    final response = await _client
        .from('flashcard_categories')
        .select()
        .order('order_index');
    return (response as List).map((e) => FlashcardCategory.fromJson(e)).toList();
  }

  Future<List<FlashcardTopic>> getTopicsByCategory(String categoryId) async {
    final response = await _client
        .from('flashcard_topics')
        .select()
        .eq('category_id', categoryId)
        .order('order_index');
    return (response as List).map((e) => FlashcardTopic.fromJson(e)).toList();
  }

  Future<List<FlashcardTopic>> getAllTopics() async {
    final response = await _client
        .from('flashcard_topics')
        .select()
        .order('order_index');
    return (response as List).map((e) => FlashcardTopic.fromJson(e)).toList();
  }

  Future<List<Flashcard>> getFlashcardsByTopic(String topicId) async {
    final response = await _client
        .from('flashcards')
        .select()
        .eq('topic_id', topicId)
        .order('order_index');
    return (response as List).map((e) => Flashcard.fromJson(e)).toList();
  }

  Future<UserFlashcardProgress?> getUserProgress(String topicId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('user_flashcard_progress')
        .select()
        .eq('user_id', user.id)
        .eq('topic_id', topicId)
        .maybeSingle();

    if (response == null) return null;
    return UserFlashcardProgress.fromJson(response);
  }

  Future<void> saveProgress({
    required String topicId,
    required int cardsCompleted,
    required bool isCompleted,
    required int lastCardIndex,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final existingProgress = await getUserProgress(topicId);

    if (existingProgress != null) {
      // Update
      await _client.from('user_flashcard_progress').update({
        'cards_completed': cardsCompleted,
        'is_completed': existingProgress.isCompleted || isCompleted,
        'last_card_index': lastCardIndex,
        'last_accessed': DateTime.now().toIso8601String(),
        if (isCompleted && !existingProgress.isCompleted)
          'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', existingProgress.id);
    } else {
      // Insert
      await _client.from('user_flashcard_progress').insert({
        'user_id': user.id,
        'topic_id': topicId,
        'cards_completed': cardsCompleted,
        'is_completed': isCompleted,
        'last_card_index': lastCardIndex,
        'last_accessed': DateTime.now().toIso8601String(),
        if (isCompleted) 'completed_at': DateTime.now().toIso8601String(),
      });
    }
  }
  
  Future<void> awardTopicXp(String topicId, int xpReward) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    try {
      // Panggil RPC Supabase agar konsisten dengan fitur lain
      await _client.rpc('complete_flashcard_topic', params: {
        'p_topic_id': topicId,
      });
      
    } catch (e) {
      developer.log('Error awarding XP: $e', name: 'FlashcardRepository');
    }
  }
}
