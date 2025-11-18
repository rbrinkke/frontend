import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/auth_models.dart';
import '../../services/auth_service.dart';

part 'auth_screen_controller.freezed.dart';

enum AuthFlow { login, register, passwordReset }
enum AuthStep { credentials, code, orgSelection, token }

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthFlow.login) AuthFlow flow,
    @Default(AuthStep.credentials) AuthStep step,
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    String? error,
    // Temporary data for multi-step flows
    String? email,
    String? password,
    String? code,
    String? verificationToken,
    String? resetToken,
    List<OrganizationOption>? organizations,
  }) = _AuthState;
}

class AuthScreenController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthScreenController(this._authService) : super(const AuthState());

  void setFlow(AuthFlow flow) {
    state = const AuthState().copyWith(flow: flow);
  }

  Future<void> submitCredentials(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, email: email, password: password);
    try {
      switch (state.flow) {
        case AuthFlow.login:
          final response = await _authService.loginStep1(email, password);
          _handleLoginResponse(response);
          break;
        case AuthFlow.register:
          await _authService.register(email, password);
          state = state.copyWith(isLoading: false, step: AuthStep.token);
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      switch (state.flow) {
        case AuthFlow.register:
          await _authService.verifyEmail(token, code);
          state = state.copyWith(isLoading: false, step: AuthStep.credentials, flow: AuthFlow.login);
          break;
        case AuthFlow.passwordReset:
          await _authService.resetPassword(token, code, newPassword!);
          state = state.copyWith(isLoading: false, step: AuthStep.credentials, flow: AuthFlow.login);
          break;
        case AuthFlow.login:
          // This case should not happen
          break;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _handleLoginResponse(LoginResponse response) {
    if (response is TokenResponse) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } else if (response is LoginCodeSentResponse) {
      state = state.copyWith(isLoading: false, step: AuthStep.code);
    } else if (response is OrganizationSelectionResponse) {
      state = state.copyWith(
        isLoading: false,
        step: AuthStep.orgSelection,
        organizations: response.organizations,
      );
    }
  }

  void back() {
    if (state.step == AuthStep.token) {
      state = state.copyWith(step: AuthStep.credentials, error: null);
    } else {
      state = state.copyWith(step: AuthStep.credentials, error: null);
    }
  }
}

final authScreenControllerProvider =
    StateNotifierProvider<AuthScreenController, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthScreenController(authService);
});
