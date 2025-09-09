import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prayoo/services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _sb = SupabaseService.client;
  
  AppUser? _user; // Lightweight user for UI
  bool _isLoading = false;
  String? _errorMessage;
  
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;
  
  AuthProvider() {
    _sb.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && session.user != null) {
        final u = session.user!;
        _user = AppUser(
          uid: u.id,
          displayName: u.userMetadata?['display_name']?.toString(),
          photoURL: u.userMetadata?['avatar_url']?.toString(),
          email: u.email,
        );
        _updateUserOnlineStatus(true);
      } else {
        _updateUserOnlineStatus(false);
        _user = null;
      }
      notifyListeners();
    });
  }
  
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      final res = await _sb.auth.signInWithPassword(email: email, password: password);
      final u = res.user;
      if (u != null) {
        _user = AppUser(
          uid: u.id,
          displayName: u.userMetadata?['display_name']?.toString(),
          photoURL: u.userMetadata?['avatar_url']?.toString(),
          email: u.email,
        );
        await _updateUserOnlineStatus(true);
      }
      return true;
    } catch (e) {
      print('Sign in error: $e');
      _errorMessage = _friendlyMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, {String? displayName}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      final res = await _sb.auth.signUp(
        email: email,
        password: password,
        data: {
          if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
        },
      );
      final u = res.user;
      if (u != null) {
        // Only upsert profile if we already have an authenticated session.
        // If email confirmation is enabled, there may be no session yet and RLS will block writes.
        if (_sb.auth.currentUser != null) {
          await _sb.from('profiles').upsert({
            'id': u.id,
            'email': email,
            'display_name': displayName,
            'is_online': true,
            'last_seen': DateTime.now().toIso8601String(),
          });
        }
        _user = AppUser(
          uid: u.id,
          displayName: displayName,
          photoURL: u.userMetadata?['avatar_url']?.toString(),
          email: u.email ?? email,
        );
      }
      return true;
    } catch (e) {
      print('Sign up error: $e');
      _errorMessage = _friendlyMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut() async {
    await _updateUserOnlineStatus(false);
    await _sb.auth.signOut();
  }
  
  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    if (_user == null) return;
    try {
      await _sb.from('profiles').upsert({
        'id': _user!.uid,
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<List<String>> getFollowingIds() async {
    final uid = _user?.uid;
    if (uid == null) return [];
    // Map following via table 'following'
    final res = await _sb.from('following').select('followee_id').eq('follower_id', uid);
    if (res is List) {
      return res.map((e) => e['followee_id'].toString()).toList();
    }
    return [];
  }

  String _friendlyMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) return 'Incorrect email or password';
    if (msg.contains('User already registered')) return 'Email is already in use';
    if (msg.contains('password')) return 'Password error: please check requirements';
    return 'Something went wrong. Please try again.';
  }
}

class AppUser {
  final String uid;
  final String? displayName;
  final String? photoURL;
  final String? email;

  AppUser({required this.uid, this.displayName, this.photoURL, this.email});
}