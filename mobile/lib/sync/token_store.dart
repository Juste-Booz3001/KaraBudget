import 'package:shared_preferences/shared_preferences.dart';

/// Stockage des tokens pour le dev sur Linux desktop (NON chiffré).
class TokenStore {
  const TokenStore();

  Future<String?> read({required String key}) async =>
      (await SharedPreferences.getInstance()).getString('tok_$key');

  Future<void> write({required String key, required String value}) async {
    await (await SharedPreferences.getInstance()).setString('tok_$key', value);
  }

  Future<void> delete({required String key}) async {
    await (await SharedPreferences.getInstance()).remove('tok_$key');
  }
}
