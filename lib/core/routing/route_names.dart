/// Route path constants
class RouteNames {
  RouteNames._();

  // Auth
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String topicSelection = '/topic-selection';
  static const String login = '/login';
  static const String register = '/register';

  // Main Tabs
  static const String home = '/home';
  static const String trending = '/trending';
  static const String education = '/education';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // Sub-routes (relative paths used inside GoRoute)
  static const String articleDetail = 'article/:id';
  static const String vote = 'vote/:id';
  static const String trendingDetail = 'detail/:id';
  static const String categoryDetail = 'category/:id';
  static const String flashcardViewer = 'flashcard/:topicId';
  static const String educationProgress = 'progress';
  static const String levelInfo = 'level-info';
  static const String userDetail = 'user/:id';
  static const String votingHistory = 'voting-history';
  static const String savedArticles = 'saved-articles';
  static const String settings = 'settings';
  static const String privacy = 'privacy';
}
