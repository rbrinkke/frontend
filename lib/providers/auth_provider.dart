import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';

/// Auth state to track authentication status
class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Auth state notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    // Check if user is already logged in on initialization
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        state = AuthState(user: user, isLoading: false);
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = const AuthState(
        isLoading: false,
        errorMessage: 'Failed to check auth status',
      );
    }
  }

  /// Login with credentials
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.login(
        LoginCredentials(username: username, password: password),
      );

      // Fetch user info after successful login
      final user = await _authService.getCurrentUser();
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

/// Simple provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});
