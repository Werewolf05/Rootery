import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class AuthService {
  static final _supabase = SupabaseService();
  static final _client = Supabase.instance.client;
  static const String _localLoginKey = 'local_login_active';
  static const String _displayNameKey = 'display_name';

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Auth state changes stream
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // SIGN IN
  static Future<AuthResponse> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _supabase.signInWithEmail(
      email: email.trim(),
      password: password,
    );
  }

  // SIGN UP
  static Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String role, {
    String? name,
    String? phone,
    String? farm,
  }) async {
    final response = await _supabase.signUp(
      email: email.trim(),
      password: password,
      userData: {'name': name, 'phone': phone, 'farm': farm},
    );

    if (response.user != null) {
      // Create user profile in users table
      await _client.from('users').insert({
        'id': response.user!.id,
        'email': email.trim(),
        'role': role,
        'name': name,
        'phone': phone,
        'farm': farm,
      });
    }

    return response;
  }

  // SIGN OUT
  static Future<void> signOut() async {
    try {
      await _supabase.signOut();
    } catch (_) {
      // Local logout should still proceed even if remote signout fails.
    } finally {
      await clearLocalLogin();
    }
  }

  // Keep local login state for demo/offline flows.
  static Future<void> persistLocalLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localLoginKey, true);
  }

  static Future<void> clearLocalLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localLoginKey, false);
  }

  static Future<void> saveDisplayName(String name) async {
    final trimmed = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, trimmed);

    if (currentUser != null && trimmed.isNotEmpty) {
      try {
        await updateUserProfile({'name': trimmed});
      } catch (_) {
        // Keep the local cache even if the remote update fails.
      }
    }
  }

  static Future<String> getDisplayName({String fallback = 'Farmer'}) async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_displayNameKey)?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final profile = await getUserProfile();
    final profileName = profile?['name']?.toString().trim();
    if (profileName != null && profileName.isNotEmpty) {
      await prefs.setString(_displayNameKey, profileName);
      return profileName;
    }

    final metadataName = currentUser?.userMetadata?['name']?.toString().trim();
    if (metadataName != null && metadataName.isNotEmpty) {
      await prefs.setString(_displayNameKey, metadataName);
      return metadataName;
    }

    return fallback;
  }

  static Future<String> getCachedDisplayName({
    String fallback = 'Farmer',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_displayNameKey)?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return fallback;
  }

  static Future<bool> hasSavedDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_displayNameKey)?.trim();
    return cached != null && cached.isNotEmpty;
  }

  static Future<bool> shouldAutoLogin() async {
    if (isLoggedIn) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_localLoginKey) ?? false;
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    return await _supabase.getUserProfile(currentUser!.id);
  }

  // Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) throw Exception('No user logged in');
    await _supabase.updateUserProfile(
      userId: currentUser!.id,
      updates: updates,
    );
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  // Wrapper method for signup (non-static for backward compatibility)
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
    String? role,
  }) async {
    try {
      final response = await signUpWithEmail(
        email,
        password,
        role ?? 'Farmer',
        name: name,
        phone: phone,
      );
      return response.user != null;
    } catch (e) {
      return false;
    }
  }
}
