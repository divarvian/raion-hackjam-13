/// Supabase table names & column references
/// Helps prevent typos in raw queries
class SupabaseConstants {
  SupabaseConstants._();

  // === TABLE NAMES ===
  static const String tableProfiles = 'profiles';
  static const String tablePolicies = 'policies';
  static const String tableVotes = 'votes';
  static const String tableArticleReads = 'article_reads';
  static const String tableFlashcardCategories = 'flashcard_categories';
  static const String tableFlashcardTopics = 'flashcard_topics';
  static const String tableFlashcards = 'flashcards';
  static const String tableUserFlashcardProgress = 'user_flashcard_progress';
  static const String tableComments = 'comments';
  static const String tableCommentLikes = 'comment_likes';
  static const String tableBookmarks = 'bookmarks';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableXpTransactions = 'xp_transactions';

  // === RPC FUNCTION NAMES ===
  static const String rpcCastVote = 'cast_vote';
  static const String rpcCompleteArticleRead = 'complete_article_read';
  static const String rpcCompleteFlashcardTopic = 'complete_flashcard_topic';

  // === VOTE TYPES ===
  static const String voteSupport = 'support';
  static const String voteReject = 'reject';
}
