# Flutter FastAPI Gemini App

Production-ready Flutter frontend application built following best practices for integration with FastAPI backend and Google Gemini AI.

## Architecture Overview

This project implements a clean, scalable architecture based on industry best practices:

- **State Management**: Riverpod (modern, annotation-based with superior dependency injection)
- **Networking**: Dio (production-ready HTTP client with interceptors)
- **Security**: flutter_secure_storage for encrypted JWT token storage
- **Real-time Communication**: WebSockets for bidirectional AI streaming

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart          # API endpoints and configuration
│   ├── errors/
│   │   └── api_exception.dart          # Custom exception classes
│   └── network/
│       ├── dio_client.dart             # Main Dio configuration
│       ├── secure_storage_service.dart # Encrypted token storage
│       ├── websocket_client.dart       # WebSocket wrapper
│       └── interceptors/
│           ├── auth_interceptor.dart   # JWT auto-injection & refresh
│           ├── error_interceptor.dart  # Global error handling
│           └── logging_interceptor.dart # Request/response logging
├── models/
│   └── auth_models.dart                # Data models (with JSON serialization)
├── providers/
│   └── auth_provider.dart              # Riverpod state providers
├── services/
│   ├── auth_service.dart               # Authentication service
│   └── gemini_service.dart             # AI/Gemini integration
├── screens/
│   ├── login_screen.dart               # Login UI
│   └── home_screen.dart                # Main app screen
└── main.dart                           # App entry point

test/                                   # Unit and widget tests
```

## Key Features & Best Practices Implemented

### 1. Production-Ready Networking (Dio)

- **Automatic JWT injection**: Auth interceptor adds tokens to all requests
- **Token auto-refresh**: Seamlessly refreshes expired tokens on 401 errors
- **Global error handling**: Transforms network errors into user-friendly messages
- **Request logging**: Debugging with structured logs
- **Type-safe configuration**: BaseOptions for consistent headers, timeouts

### 2. Secure Authentication (JWT/OAuth2)

- **FormData login**: Uses `FormData.fromMap()` for OAuth2 compatibility (NOT JSON!)
  - This is critical! FastAPI's `OAuth2PasswordRequestForm` requires form data
- **Encrypted storage**: Tokens stored with `flutter_secure_storage` (not SharedPreferences)
- **Auto token refresh**: Interceptor handles 401 errors transparently

### 3. Modern State Management (Riverpod)

- **BuildContext-independent**: Access state anywhere without context
- **Dependency injection**: First-class DI system
- **Testable**: Easy to mock providers in tests
- **Type-safe**: Compile-time safety with providers

### 4. Real-time AI Streaming (WebSockets)

- **Bidirectional communication**: Send and receive messages in real-time
- **Not SSE**: Using WebSockets (recommended over Server-Sent Events)
- **Auto-reconnect**: WebSocketClient handles disconnections gracefully

### 5. Error Handling Strategy

Three-layer error handling:

1. **Backend**: Custom exceptions from FastAPI (401, 422, 500, etc.)
2. **Interceptor**: Transforms DioException into ApiException
3. **UI**: User-friendly error messages in screens

## Setup Instructions

### Prerequisites

1. **Install Flutter**:
   ```bash
   # Check if Flutter is installed
   flutter --version

   # If not installed, follow: https://flutter.dev/docs/get-started/install
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Generation** (for JSON serialization):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Configuration

1. **Update API Base URL** in `lib/core/constants/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://your-backend-url:8000';
   static const String wsBaseUrl = 'ws://your-backend-url:8000';
   ```

2. **Platform-Specific Setup**:

   **Android** (`android/app/build.gradle`):
   ```gradle
   android {
       compileSdkVersion 34

       defaultConfig {
           minSdkVersion 21  // Required for flutter_secure_storage
       }
   }
   ```

   **iOS** (run once):
   ```bash
   cd ios && pod install
   ```

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Build for release
flutter build apk  # Android
flutter build ios  # iOS (requires macOS)
```

## Critical Lessons Learned (from Best Practices Doc)

### 1. The OAuth2 FormData Pitfall ⚠️

**Problem**: Calling `/token` endpoint with JSON body returns 422 error.

**Solution**: FastAPI's `OAuth2PasswordRequestForm` requires FormData:
```dart
// ❌ WRONG - This will fail!
await dio.post('/token', data: {'username': 'user', 'password': 'pass'});

// ✅ CORRECT - Use FormData
final formData = FormData.fromMap({
  'username': username,
  'password': password,
});
await dio.post('/token', data: formData);
```

**Location**: `lib/services/auth_service.dart:32`

### 2. Use dio, Not http Package

The `http` package is insufficient for production:
- ❌ No automatic JSON decoding
- ❌ No interceptors (manual auth, logging, retry)
- ❌ No global configuration
- ✅ dio solves all these problems

### 3. WebSockets Over SSE

For AI chat streaming, use WebSockets (not Server-Sent Events):
- ✅ Bidirectional (user can send "stop" command)
- ✅ Better browser/mobile support
- ✅ Can handle complex chat flows

### 4. Secure Storage for Tokens

Never use SharedPreferences for tokens:
- ❌ SharedPreferences is NOT encrypted
- ✅ flutter_secure_storage encrypts data

### 5. Riverpod Over Provider

Provider is in maintenance mode. Use Riverpod:
- ✅ Better dependency injection
- ✅ BuildContext-independent
- ✅ More testable

## Development Workflow

### 1. Making Changes to Models

When you modify models in `lib/models/`:

```bash
flutter pub run build_runner watch
# This watches for changes and auto-generates .g.dart files
```

### 2. Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/services/auth_service_test.dart

# Run with coverage
flutter test --coverage
```

### 3. Linting

```bash
# Analyze code
flutter analyze

# Auto-fix some issues
dart fix --apply
```

## Backend Integration

This app expects a FastAPI backend with:

### Required Endpoints:

1. **POST /token** - Login (OAuth2 FormData)
   ```json
   Response: {
     "access_token": "eyJ...",
     "token_type": "bearer",
     "refresh_token": "eyJ..." (optional)
   }
   ```

2. **POST /token/refresh** - Refresh token
   ```json
   Request: {"refresh_token": "eyJ..."}
   Response: {"access_token": "eyJ...", "refresh_token": "eyJ..."}
   ```

3. **GET /users/me** - Current user (requires auth)
   ```json
   Response: {
     "id": "123",
     "email": "user@example.com",
     "name": "John Doe"
   }
   ```

4. **WS /ws/chat?token=xxx** - WebSocket for AI streaming

## Troubleshooting

### 1. Build Runner Fails

```bash
# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. iOS Build Fails

```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### 3. Android Build Fails

Check `minSdkVersion >= 21` in `android/app/build.gradle`

### 4. Network Errors in Development

- **Android Emulator**: Use `http://10.0.2.2:8000` for localhost
- **iOS Simulator**: Use `http://localhost:8000`
- **Real Device**: Use your computer's IP address

## Next Steps

To extend this app:

1. **Add More Services**: Create services in `lib/services/` for different API endpoints
2. **Add Screens**: Create new screens in `lib/screens/`
3. **Add Models**: Define data models in `lib/models/` with JSON serialization
4. **Add Providers**: Create Riverpod providers in `lib/providers/` for state management
5. **Implement Chat UI**: Use `GeminiService` with WebSockets for real-time AI chat

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Best Practices Document](./Flutter,%20FastAPI,%20Gemini%20Integration%20Best%20Practices.txt)

## License

This project structure is provided as a template following industry best practices.
