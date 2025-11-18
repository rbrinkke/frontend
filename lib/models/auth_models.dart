import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

/// Token response model
/// Matches the FastAPI OAuth2PasswordBearer response
@JsonSerializable()
class TokenResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'token_type')
  final String tokenType;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
}

/// User model
@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? name;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

/// Login request credentials
class LoginCredentials {
  final String username;
  final String password;

  LoginCredentials({
    required this.username,
    required this.password,
  });
}
