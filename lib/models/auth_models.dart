import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

// ~~~~~~~~~~~~~~~~~ REQUEST MODELS ~~~~~~~~~~~~~~~~~

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
    String? code,
    @JsonKey(name: 'org_id') String? orgId,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class UserCreate with _$UserCreate {
  const factory UserCreate({
    required String email,
    required String password,
  }) = _UserCreate;

  factory UserCreate.fromJson(Map<String, dynamic> json) =>
      _$UserCreateFromJson(json);
}

@freezed
class VerifyEmailRequest with _$VerifyEmailRequest {
  const factory VerifyEmailRequest({
    @JsonKey(name: 'verification_token') required String verificationToken,
    required String code,
  }) = _VerifyEmailRequest;

  factory VerifyEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyEmailRequestFromJson(json);
}

@freezed
class RequestPasswordResetRequest with _$RequestPasswordResetRequest {
  const factory RequestPasswordResetRequest({
    required String email,
  }) = _RequestPasswordResetRequest;

  factory RequestPasswordResetRequest.fromJson(Map<String, dynamic> json) =>
      _$RequestPasswordResetRequestFromJson(json);
}

@freezed
class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    @JsonKey(name: 'reset_token') required String resetToken,
    required String code,
    @JsonKey(name: 'new_password') required String newPassword,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}


// ~~~~~~~~~~~~~~~~~ RESPONSE MODELS ~~~~~~~~~~~~~~~~~

/// Sealed class to handle the polymorphic response from the /login endpoint
@JsonSerializable(explicitToJson: true)
@JsonConverter(typeof(LoginResponseConverter))]
sealed class LoginResponse {
  const LoginResponse();

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('access_token')) {
      return TokenResponse.fromJson(json);
    } else if (json.containsKey('user_id')) {
      return LoginCodeSentResponse.fromJson(json);
    } else if (json.containsKey('organizations')) {
      return OrganizationSelectionResponse.fromJson(json);
    }
    throw ArgumentError('Invalid LoginResponse JSON');
  }

  Map<String, dynamic> toJson();
}

@freezed
class TokenResponse extends LoginResponse with _$TokenResponse {
  @JsonSerializable(explicitToJson: true)
  const factory TokenResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @Default('bearer') @JsonKey(name: 'token_type') String tokenType,
    @JsonKey(name: 'org_id') String? orgId,
  }) = _TokenResponse;

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);
}


@freezed
class LoginCodeSentResponse extends LoginResponse with _$LoginCodeSentResponse {
  @JsonSerializable(explicitToJson: true)
  const factory LoginCodeSentResponse({
    required String message,
    required String email,
    @JsonKey(name: 'user_id') required String userId,
    @Default(600) @JsonKey(name: 'expires_in') int expiresIn,
    @Default(true) @JsonKey(name: 'requires_code') bool requiresCode,
  }) = _LoginCodeSentResponse;

  factory LoginCodeSentResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginCodeSentResponseFromJson(json);
}

@freezed
class OrganizationSelectionResponse extends LoginResponse with _$OrganizationSelectionResponse {
    @JsonSerializable(explicitToJson: true)
  const factory OrganizationSelectionResponse({
    required String message,
    required List<OrganizationOption> organizations,
    @JsonKey(name: 'user_token') required String userToken,
    @Default(900) @JsonKey(name: 'expires_in') int expiresIn,
  }) = _OrganizationSelectionResponse;

  factory OrganizationSelectionResponse.fromJson(Map<String, dynamic> json) =>
      _$OrganizationSelectionResponseFromJson(json);
}

@freezed
class OrganizationOption with _$OrganizationOption {
  const factory OrganizationOption({
    required String id,
    required String name,
    required String slug,
    required String role,
    @JsonKey(name: 'member_count') required int memberCount,
  }) = _OrganizationOption;

  factory OrganizationOption.fromJson(Map<String, dynamic> json) =>
      _$OrganizationOptionFromJson(json);
}


// ~~~~~~~~~~~~~~~~~ EXISTING MODELS ~~~~~~~~~~~~~~~~~

/// User model
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? name,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Custom converter to handle the sealed class
class LoginResponseConverter implements JsonConverter<LoginResponse, Map<String, dynamic>> {
  const LoginResponseConverter();

  @override
  LoginResponse fromJson(Map<String, dynamic> json) {
    return LoginResponse.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LoginResponse object) {
    return object.toJson();
  }
}
