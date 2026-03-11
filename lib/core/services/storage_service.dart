/// Local storage service for persisting data.
/// TODO: Implement with shared_preferences or hive.
class StorageService {
  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // TODO: Add methods for storing/retrieving auth tokens, user prefs, etc.
}
