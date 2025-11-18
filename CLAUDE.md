# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter mobile application for the Activity platform using clean architecture with Riverpod state management, Dio networking, and multi-step authentication flow.

**Stack**: Flutter 3.0+, Riverpod (annotation-based), Dio, Freezed, flutter_secure_storage

## MCP Server Integration

This project is configured to work with the **Dart and Flutter MCP server**, which provides AI-assisted development capabilities:

**Available Tools**:
- Analyze and fix errors in project code
- Resolve symbols and fetch documentation
- Introspect and interact with running applications
- Search pub.dev for packages
- Manage pubspec.yaml dependencies
- Run tests and analyze results
- Format code with dart format

**Configuration**: The MCP server is already configured in `~/.config/Claude/claude_desktop_config.json` as the `dart-flutter` server.

**Requirements**: Dart SDK 3.9+ (currently using Dart 3.10.0 with Flutter 3.38.1)

**Usage**: Claude Code automatically uses these tools when working with Dart/Flutter code. You can verify the server is available by checking for `dart-flutter` in the MCP servers list.

## Critical First Steps

### 1. Code Generation is Required

This project uses code generation. You **MUST** run this after cloning or modifying models/providers:

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (recommended during development)
flutter pub run build_runner watch
```

**What gets generated**:
- `*.g.dart` - JSON serialization (from `@JsonSerializable`)
- `*.freezed.dart` - Immutable models (from `@freezed`)
- Provider files (from `@riverpod` annotations)

**You will see compile errors** if you skip this step. Files like `auth_models.g.dart` are gitignored and must be generated locally.

### 2. Update Backend URL

Edit `lib/core/constants/api_constants.dart`:

```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000';

// iOS Simulator
static const String baseUrl = 'http://localhost:8000';

// Real Device (use your machine's IP)
static const String baseUrl = 'http://192.168.1.x:8000';
```

## Common Commands

### Development Workflow

```bash
# Install dependencies
flutter pub get

# Run code generation (always after model changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run specific device
flutter devices
flutter run -d <device-id>

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run with coverage
flutter test --coverage

# Generate mocks (after adding @GenerateMocks)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Code Quality

```bash
# Analyze code (checks linting rules)
flutter analyze

# Auto-fix some issues
dart fix --apply

# Format code
dart format .
```

### Building for Release

```bash
# Android APK
flutter build apk

# Android App Bundle (for Play Store)
flutter build appbundle

# iOS (requires macOS)
flutter build ios
```

### Troubleshooting Commands

```bash
# Clean build artifacts
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Fix iOS pods issues
cd ios && pod deintegrate && pod install && cd ..

# Clear code generation cache
flutter pub run build_runner clean
```

## Architecture Overview

### Directory Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart       # API URLs, timeouts, endpoints
│   ├── errors/
│   │   └── api_exception.dart       # Custom exceptions
│   └── network/
│       ├── dio_client.dart          # Dio configuration with interceptors
│       ├── secure_storage_service.dart  # Encrypted token storage
│       ├── websocket_client.dart    # WebSocket wrapper
│       └── interceptors/
│           ├── auth_interceptor.dart    # Auto JWT injection + refresh
│           ├── error_interceptor.dart   # Global error handling
│           └── logging_interceptor.dart # Request/response logging
├── models/
│   └── auth_models.dart             # Freezed models with JSON serialization
├── providers/
│   └── auth_provider.dart           # Riverpod state providers
├── services/
│   ├── auth_service.dart            # Multi-step authentication service
│   └── gemini_service.dart          # AI/Gemini integration
├── screens/
│   ├── auth/
│   │   ├── auth_screen.dart         # Login/register UI
│   │   └── auth_screen_controller.dart
│   └── home_screen.dart
└── main.dart                        # App entry point with ProviderScope
```

### Multi-Step Authentication Flow

**Critical Pattern**: Login returns different response types based on user state.

```dart
// Step 1: Submit email/password
final response = await authService.loginStep1(email, password);

// Step 2: Handle response type
response.when(
  token: (accessToken, refreshToken, tokenType, orgId) {
    // Success - tokens received, navigate to home
  },
  codeSent: (message, email, userId, expiresIn, requiresCode) {
    // 2FA required - show code verification screen
    // User must call loginStep2() with the code
  },
  orgSelection: (message, organizations, userToken, expiresIn) {
    // Multiple orgs - show organization selector
    // User must call loginStep2() with selected org_id
  },
);
```

**Sealed Class Pattern**: `LoginResponse` uses Freezed sealed classes for type-safe response handling. Always use `.when()` or `.map()` to handle all variants.

### Interceptor Architecture

**Order matters!** Interceptors execute in the order added in `dio_client.dart:30`:

1. **LoggingInterceptor** - Logs requests/responses for debugging
2. **AuthInterceptor** - Injects JWT tokens, handles 401 refresh
3. **ErrorInterceptor** - Transforms DioException → ApiException

**Auto Token Refresh**: When a 401 error occurs, `AuthInterceptor` automatically:
1. Calls `/token/refresh` with refresh token
2. Saves new tokens to secure storage
3. Retries original request with new token
4. If refresh fails, clears tokens (user must re-login)

### State Management Pattern

**Riverpod Providers**: Access via `ref.read()` or `ref.watch()`.

```dart
// Define provider
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageServiceProvider);
  return AuthService(dio: dio, storageService: storage);
});

// Use in widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    // ...
  }
}
```

**No BuildContext required** - Providers accessible anywhere via `ref`.

## Backend Integration

### Expected API Endpoints

This app expects the auth-api backend (port 8000) with these endpoints:

**Authentication**:
- `POST /api/auth/login` - Multi-step login (JSON body, returns sealed LoginResponse)
- `POST /api/auth/register` - User registration (returns verification token)
- `POST /api/auth/verify-code` - Email verification with code
- `POST /api/auth/request-password-reset` - Request password reset email
- `POST /api/auth/reset-password` - Reset password with token + code
- `POST /token/refresh` - Refresh access token (returns new access + refresh tokens)
- `GET /users/me` - Get current user (requires Bearer token)

**WebSocket**:
- `WS /ws/chat?token=xxx` - Real-time AI chat streaming

### Authentication Headers

All authenticated requests automatically include:
```
Authorization: Bearer <access_token>
```

This is injected by `AuthInterceptor` - you don't need to add it manually in service calls.

## Key Patterns & Best Practices

### Working with Models

**Always use Freezed for data models**:

```dart
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

**After creating/modifying models**:
1. Add `part 'my_model.freezed.dart';` and `part 'my_model.g.dart';`
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Generated files appear in same directory (gitignored)

### Working with Services

**All services should**:
1. Accept Dio via dependency injection
2. Use providers for instantiation
3. Throw exceptions (interceptors handle them)
4. Return typed models (not Map<String, dynamic>)

```dart
class MyService {
  final Dio _dio;

  MyService({required Dio dio}) : _dio = dio;

  Future<MyModel> getData() async {
    final response = await _dio.get('/api/data');
    return MyModel.fromJson(response.data);
  }
}

final myServiceProvider = Provider<MyService>((ref) {
  return MyService(dio: ref.read(dioProvider));
});
```

### Testing with Mockito

**Generate mocks**:

```dart
import 'package:mockito/annotations.dart';

@GenerateMocks([Dio, SecureStorageService])
void main() {
  late MockDio mockDio;
  late AuthService authService;

  setUp(() {
    mockDio = MockDio();
    authService = AuthService(dio: mockDio, storageService: mockStorage);
  });

  test('description', () async {
    when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
      (_) async => Response(data: {...}, statusCode: 200),
    );

    final result = await authService.someMethod();

    expect(result, isA<SomeType>());
    verify(mockDio.post(any, data: anyNamed('data'))).called(1);
  });
}
```

**Run build_runner** to generate `.mocks.dart` files.

## Common Issues & Solutions

### "Target of URI hasn't been generated"

**Cause**: Missing code generation.

**Fix**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### "No devices found"

**Fix**:
```bash
# List available devices
flutter devices

# Launch emulator
flutter emulators
flutter emulators --launch <emulator-id>

# Or use Android Studio/Xcode to start emulator
```

### Network errors during development

**Android Emulator**: Use `10.0.2.2` instead of `localhost`
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

**iOS Simulator**: Use `localhost` works fine
```dart
static const String baseUrl = 'http://localhost:8000';
```

**Real Device**: Use your computer's IP address
```bash
# Find your IP
ipconfig (Windows)
ifconfig (Mac/Linux)

# Then update api_constants.dart
static const String baseUrl = 'http://192.168.1.x:8000';
```

### Build fails after dependency update

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..  # iOS only
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Interceptor not working

**Check order** in `lib/core/network/dio_client.dart:30`. Order matters:
1. Logging (first, to see all requests)
2. Auth (adds tokens)
3. Error (transforms errors)

### Token refresh loop

If `AuthInterceptor` enters infinite refresh loop, check:
1. `/token/refresh` endpoint is excluded in `onRequest()` (line 22)
2. `_isRefreshing` flag prevents concurrent refreshes (line 12)
3. Refresh token is valid and not expired

## Linting Rules

Configured in `analysis_options.yaml`:

- Prefer `const` constructors
- Prefer single quotes for strings
- Require trailing commas for better diffs
- Use keys in widget constructors
- Prefer `final` for fields and locals
- Always declare return types

**Generated files** (`*.g.dart`, `*.freezed.dart`) are excluded from analysis.

## Integration with Backend Services

This Flutter app connects to the Activity platform microservices (see parent `/mnt/d/activity/CLAUDE.md`):

**Primary**:
- **auth-api** (port 8000) - Multi-step authentication with email verification

**Future Integration**:
- **chat-api** (port 8001) - WebSocket real-time chat (via `GeminiService`)
- **activity-api** (port 8007) - Activity CRUD operations
- **image-api** (port 8009) - Image upload/processing

All services use JWT authentication with shared secret. Tokens obtained from auth-api work across all services.

## Development Workflow

### Adding a new feature

1. **Create models** (if needed):
   ```bash
   # Add to lib/models/my_feature_models.dart with @freezed
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Create service**:
   ```bash
   # Add to lib/services/my_feature_service.dart
   # Create provider for dependency injection
   ```

3. **Create provider** (if state management needed):
   ```bash
   # Add to lib/providers/my_feature_provider.dart
   ```

4. **Create screen**:
   ```bash
   # Add to lib/screens/my_feature_screen.dart
   ```

5. **Write tests**:
   ```bash
   # Add to test/services/my_feature_service_test.dart
   # Add @GenerateMocks if needed
   flutter test
   ```

### Modifying existing models

1. Edit model in `lib/models/`
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Update affected tests
4. Run `flutter analyze` to check for errors

### Adding new dependencies

1. Add to `pubspec.yaml`
2. Run `flutter pub get`
3. Import in Dart files
4. If iOS pod: `cd ios && pod install && cd ..`
