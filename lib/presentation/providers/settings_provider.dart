import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _apiKeyStorageKey = 'openrouter_api_key';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiKeyProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.read(key: _apiKeyStorageKey);
});

class SettingsNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final storage = ref.watch(secureStorageProvider);
    return storage.read(key: _apiKeyStorageKey);
  }

  Future<void> saveApiKey(String key) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _apiKeyStorageKey, value: key);
    state = AsyncData(key);
  }

  Future<void> clearApiKey() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _apiKeyStorageKey);
    state = const AsyncData(null);
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, String?>(SettingsNotifier.new);
