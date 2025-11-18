
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/auth_models.dart';
import '../../services/auth_service.dart';

part 'auth_screen_controller.freezed.dart';

enum AuthStep {
  credentials,
  code,
  orgSelection,
  token,
}

enum AuthFlow {
  login,
  register,
  passwordReset,
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthFlow.login) AuthFlow flow,
    @Default(AuthStep.credentials) AuthStep step,
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    String? email,
    String? password,
    String? code,
    String? token,
    List<OrganizationOption>? organizations,
    String? error,
    @Default(0) int resendCooldown,
  }) = _AuthState;
}

class AuthScreenController extends StateNotifier<AuthState> {
  final AuthService _authService;
  Timer? _resendTimer;

  AuthScreenController(this._authService) : super(const AuthState());

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void setFlow(AuthFlow flow) {
    _resendTimer?.cancel();
    state = const AuthState().copyWith(flow: flow);
  }

  Future<void> submitCredentials(String email, String? password) async {
    state = state.copyWith(isLoading: true, error: null, email: email, password: password);
    try {
      switch (state.flow) {
        case AuthFlow.login:
          final response = await _authService.loginStep1(email, password!);
          _handleLoginResponse(response);
          break;
        case AuthFlow.register:
          await _authService.register(email, password!);
          // After successful registration, send user to login
          state = state.copyWith(isLoading: false, flow: AuthFlow.login);
          break;
        case AuthFlow.passwordReset:
          await _authService.requestPasswordReset(email);
          state = state.copyWith(isLoading: false, step: AuthStep.token);
          break;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitCode(String code, {String? orgId}) async {
    state = state.copyWith(isLoading: true, error: null, code: code);
    try {
      final response = await _authService.loginStep2(state.email!, state.password!, code, orgId: orgId);
      _handleLoginResponse(response);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitTokenAndCode(String token, String code, {String? newPassword}) async {
    state = state.copyWith(isLoading: true, error: null, token: token, code: code);
    try {
      if (state.flow == AuthFlow.passwordReset) {
        await _authService.resetPassword(token, code, newPassword!);
        // After successful password reset, send user back to login
        state = state.copyWith(isLoading: false, step: AuthStep.credentials, flow: AuthFlow.login);
      } else if (state.flow == AuthFlow.register) {
        await _authService.verifyEmail(token, code);
        // After successful email verification, send user to login
        state = state.copyWith(isLoading: false, step: AuthStep.credentials, flow: AuthFlow.login);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _handleLoginResponse(LoginResponse response) {
    _resendTimer?.cancel();

    response.when(
      token: (accessToken, refreshToken, tokenType, orgId) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      },
      codeSent: (message, email, userId, expiresIn, requiresCode) {
        _startResendTimer(expiresIn);
        state = state.copyWith(isLoading: false, step: AuthStep.code);
      },
      orgSelection: (message, organizations, userToken, expiresIn) {
        state = state.copyWith(
          isLoading: false,
          step: AuthStep.orgSelection,
          organizations: organizations,
        );
      },
    );
  }

  Future<void> resendCode() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Re-submit credentials to trigger a new code
      final response = await _authService.loginStep1(state.email!, state.password!);
      _handleLoginResponse(response);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    state = state.copyWith(resendCooldown: seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.resendCooldown > 0) {
        state = state.copyWith(resendCooldown: state.resendCooldown - 1);
      } else {
        _resendTimer?.cancel();
      }
    });
  }

  void back() {
    _resendTimer?.cancel();
    state = state.copyWith(step: AuthStep.credentials, error: null, organizations: null, resendCooldown: 0);
  }
}

final authScreenControllerProvider = StateNotifierProvider.autoDispose<AuthScreenController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthScreenController(authService);
});
