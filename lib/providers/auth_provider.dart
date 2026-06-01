import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/admin_config.dart';

enum AppRole { user, admin }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;

  String? _errorMessage;
  String? _authLinkErrorMessage;

  AppRole? _requestedLoginRole;
  AppRole? _userRole;
  bool _isRoleLoading = false;
  String? _roleLoadError;
  String _roleSource = AdminConfig.roleSource;

  bool _isPasswordRecovery = false;
  bool _isSigningOutRecoverySession = false;
  int _roleLoadRequestId = 0;
  Future<AppRole?>? _roleLoadFuture;
  String? _roleLoadUserId;
  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider() {
    _init();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get authLinkErrorMessage => _authLinkErrorMessage;
  AppRole? get activeRole => _requestedLoginRole;
  AppRole? get userRole => _userRole;
  bool get isRoleLoading => _isRoleLoading;
  String? get roleLoadError => _roleLoadError;
  String get roleSource => _roleSource;
  bool get isPasswordRecovery => _isPasswordRecovery;

  bool get isAuthenticated => _supabase.auth.currentSession != null;

  User? get currentUser => _supabase.auth.currentUser;

  String? get userEmail => _supabase.auth.currentUser?.email;

  bool get isAdminUser => _userRole == AppRole.admin;

  bool get isAdminSession => isAuthenticated && isAdminUser;

  bool get isAdminConfigured => true;

  void _init() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) {
        final hasEventSession = data.session != null;
        final hasCurrentSession = _supabase.auth.currentSession != null;
        final hasCurrentUser = _supabase.auth.currentUser != null;
        debugPrint(
          '[AuthProvider] auth event=${data.event.name}, '
          'eventSession=$hasEventSession, '
          'currentSession=$hasCurrentSession, '
          'currentUser=$hasCurrentUser, '
          'passwordRecovery=$_isPasswordRecovery',
        );

        if (data.event == AuthChangeEvent.passwordRecovery) {
          _authLinkErrorMessage = null;
          _isPasswordRecovery = true;
          debugPrint('[AuthProvider] Password recovery session received.');
        } else if (data.event == AuthChangeEvent.signedOut) {
          if (!_isSigningOutRecoverySession) {
            _isPasswordRecovery = false;
          }
          _clearRoleState();
        } else if (_supabase.auth.currentSession == null) {
          _clearRoleState();
        } else {
          unawaited(
            _loadRoleForCurrentUser(reason: 'auth event ${data.event.name}'),
          );
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _handleAuthStateError(error, stackTrace);
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _clearRoleState() {
    _roleLoadRequestId++;
    _roleLoadFuture = null;
    _roleLoadUserId = null;
    _requestedLoginRole = null;
    _userRole = null;
    _isRoleLoading = false;
    _roleLoadError = null;
  }

  void _handleAuthStateError(Object error, StackTrace stackTrace) {
    final hasRecoverySession = _isPasswordRecovery &&
        _supabase.auth.currentSession != null &&
        _supabase.auth.currentUser != null;

    if (hasRecoverySession) {
      debugPrint(
        '[AuthProvider] Ignoring auth stream error because a recovery '
        'session is already active. error=$error',
      );
      return;
    }

    var message = 'The password reset link could not be opened.';

    if (error is AuthException) {
      final isExpiredLink =
          error.code == 'access_denied' || error.statusCode == 'otp_expired';
      message = isExpiredLink
          ? 'This password reset link is invalid or expired. Request a new reset email and open the latest link.'
          : error.message;

      debugPrint(
        '[AuthProvider] Auth stream error handled: ${error.message} '
        'status=${error.statusCode ?? 'none'} code=${error.code ?? 'none'}',
      );
    } else {
      debugPrint('[AuthProvider] Auth stream error handled: $error');
    }

    _authLinkErrorMessage = message;
    _errorMessage = message;
    _isPasswordRecovery = false;
    _isLoading = false;
    if (_supabase.auth.currentSession == null) {
      _clearRoleState();
    } else {
      unawaited(
        _loadRoleForCurrentUser(reason: 'auth stream error preserved session'),
      );
    }
    notifyListeners();
  }

  Future<AppRole?> _loadRoleForCurrentUser({required String reason}) async {
    final user = _supabase.auth.currentUser;
    final session = _supabase.auth.currentSession;

    if (session == null || user == null) {
      debugPrint(
        '[AuthProvider] Role load skipped: session/user missing. '
        'reason=$reason source=${AdminConfig.roleSource}',
      );
      _clearRoleState();
      notifyListeners();
      return null;
    }

    if (_roleLoadFuture != null && _roleLoadUserId == user.id) {
      debugPrint(
        '[AuthProvider] Reusing in-flight role load. reason=$reason '
        'source=${AdminConfig.roleSource} userId=${user.id} email=${user.email}',
      );
      return _roleLoadFuture;
    }

    _roleLoadUserId = user.id;
    final future = _fetchRoleForUser(user: user, reason: reason);
    _roleLoadFuture = future;
    return future;
  }

  Future<AppRole?> _fetchRoleForUser({
    required User user,
    required String reason,
  }) async {
    final requestId = ++_roleLoadRequestId;
    _isRoleLoading = true;
    _roleLoadError = null;
    _roleSource = AdminConfig.roleSource;
    debugPrint(
      '[AuthProvider] Loading role. reason=$reason '
      'source=$_roleSource userId=${user.id} email=${user.email}',
    );
    notifyListeners();

    try {
      final response = await _supabase
          .from(AdminConfig.adminTable)
          .select('user_id,email')
          .eq('user_id', user.id)
          .limit(1);

      if (requestId != _roleLoadRequestId) {
        debugPrint(
          '[AuthProvider] Ignoring stale role load result. '
          'source=$_roleSource userId=${user.id} email=${user.email}',
        );
        return _userRole;
      }

      final rows = (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final isAdmin = rows.isNotEmpty;
      _userRole = isAdmin ? AppRole.admin : AppRole.user;
      _isRoleLoading = false;
      _roleLoadError = null;

      debugPrint(
        '[AuthProvider] Role fetched. source=$_roleSource '
        'userId=${user.id} email=${user.email} '
        'isAdmin=$isAdmin role=${_userRole!.name} rows=${rows.length}',
      );
      notifyListeners();
      return _userRole;
    } catch (e) {
      if (requestId != _roleLoadRequestId) {
        debugPrint(
          '[AuthProvider] Ignoring stale role load error. '
          'source=$_roleSource userId=${user.id} email=${user.email} error=$e',
        );
        return _userRole;
      }

      _userRole = null;
      _isRoleLoading = false;
      _roleLoadError =
          'Could not load account role from ${AdminConfig.roleSource}.';
      debugPrint(
        '[AuthProvider] Role load failed. source=$_roleSource '
        'userId=${user.id} email=${user.email} error=$e',
      );
      notifyListeners();
      return null;
    } finally {
      if (requestId == _roleLoadRequestId) {
        _roleLoadFuture = null;
        _roleLoadUserId = null;
      }
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (response.user == null) {
        _errorMessage = 'Sign up failed. Please try again.';
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Check your connection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool asAdmin = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _requestedLoginRole = asAdmin ? AppRole.admin : AppRole.user;
    _userRole = null;
    _roleLoadError = null;
    _roleLoadFuture = null;
    _roleLoadUserId = null;
    _roleLoadRequestId++;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint(
        '[AuthProvider] Supabase sign-in succeeded. '
        'requestedPanel=${_requestedLoginRole?.name} '
        'userId=${response.user?.id ?? _supabase.auth.currentUser?.id ?? 'none'} '
        'email=${response.user?.email ?? _supabase.auth.currentUser?.email ?? email}',
      );

      final role = await _loadRoleForCurrentUser(
        reason: 'signIn requestedPanel=${_requestedLoginRole?.name}',
      );

      if (role == null) {
        final roleError =
            _roleLoadError ?? 'Could not load account role. Please try again.';
        await _supabase.auth.signOut();
        _clearRoleState();
        _isLoading = false;
        _errorMessage = roleError;
        debugPrint(
          '[AuthProvider] Sign-in stopped because role could not be loaded.',
        );
        notifyListeners();
        return false;
      }

      if (asAdmin && role != AppRole.admin) {
        await _supabase.auth.signOut();
        _clearRoleState();
        _isLoading = false;
        _errorMessage =
            'This account is not listed as an admin in ${AdminConfig.roleSource}.';
        debugPrint(
          '[AuthProvider] Admin sign-in denied. source=${AdminConfig.roleSource} '
          'email=$email fetchedRole=${role.name}',
        );
        notifyListeners();
        return false;
      }

      _isLoading = false;
      debugPrint(
        '[AuthProvider] Final navigation decision: '
        '${role == AppRole.admin ? 'admin panel' : 'user panel'} '
        'source=${AdminConfig.roleSource} '
        'userId=${_supabase.auth.currentUser?.id ?? 'none'} '
        'email=${_supabase.auth.currentUser?.email ?? email} role=${role.name}',
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _clearRoleState();
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _clearRoleState();
      _errorMessage = 'An unexpected error occurred. Check your connection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(
        '[AuthProvider] Sending password reset email with redirect '
        'personalutilityapp://auth/reset-password',
      );
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'personalutilityapp://auth/reset-password',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not send reset email. Check your connection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePasswordForRecovery({required String newPassword}) async {
    _errorMessage = null;

    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;
    debugPrint(
      '[AuthProvider] Password update requested. '
      'recovery=$_isPasswordRecovery, '
      'sessionExists=${session != null}, '
      'userExists=${user != null}, '
      'userId=${user?.id ?? 'none'}',
    );

    if (!_isPasswordRecovery) {
      _errorMessage =
          'Open the password reset link from your email before updating.';
      debugPrint('[AuthProvider] Password update blocked: not in recovery.');
      notifyListeners();
      return false;
    }

    if (session == null || user == null) {
      _errorMessage =
          'Password reset session is missing or expired. Open the latest reset email link again.';
      debugPrint(
        '[AuthProvider] Password update blocked: recovery session/user missing.',
      );
      notifyListeners();
      return false;
    }

    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint(
        '[AuthProvider] Password update succeeded for userId=${response.user?.id ?? user.id}.',
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      debugPrint(
        '[AuthProvider] Password update failed: ${e.message} '
        'status=${e.statusCode ?? 'none'} code=${e.code ?? 'none'}',
      );
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not update password. Please try again.';
      debugPrint('[AuthProvider] Password update failed unexpectedly: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      _errorMessage = 'Could not sign out. Try again.';
    } finally {
      _clearRoleState();
      _isPasswordRecovery = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _authLinkErrorMessage = null;
    notifyListeners();
  }

  void clearAuthLinkError() {
    _authLinkErrorMessage = null;
    if (_errorMessage?.contains('reset link') ?? false) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> signOutRecoverySession() async {
    debugPrint('[AuthProvider] Signing out temporary recovery session.');
    _isSigningOutRecoverySession = true;

    try {
      await _supabase.auth.signOut();
      debugPrint('[AuthProvider] Temporary recovery session signed out.');
    } catch (e) {
      _errorMessage =
          'Password updated, but the temporary session could not be signed out.';
      debugPrint('[AuthProvider] Recovery session sign-out failed: $e');
    } finally {
      _isSigningOutRecoverySession = false;
      _clearRoleState();
      notifyListeners();
    }
  }

  void clearPasswordRecoveryState() {
    debugPrint('[AuthProvider] Clearing password recovery state.');
    _isPasswordRecovery = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
