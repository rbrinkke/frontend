# Quick Setup Guide

## Step 1: Install Flutter

If you don't have Flutter installed:

```bash
# Check installation
flutter --version

# If not installed, visit:
# https://flutter.dev/docs/get-started/install
```

## Step 2: Install Dependencies

```bash
# Get all packages
flutter pub get
```

## Step 3: Generate Code

This project uses code generation for JSON serialization and Riverpod providers.

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch mode (auto-regenerates on changes)
flutter pub run build_runner watch
```

This will generate:
- `lib/models/auth_models.g.dart`
- `lib/providers/auth_provider.g.dart`

## Step 4: Configure Backend URL

Edit `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:8000';
static const String wsBaseUrl = 'ws://YOUR_BACKEND_URL:8000';
```

### Local Development URLs:

- **Android Emulator**: `http://10.0.2.2:8000`
- **iOS Simulator**: `http://localhost:8000`
- **Real Device**: `http://YOUR_COMPUTER_IP:8000`

## Step 5: Run the App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run (will prompt for device)
flutter run
```

## Code Generation Commands

### When to Run Code Generation:

Run these commands whenever you:
- Add/modify models with `@JsonSerializable()`
- Add/modify Riverpod providers with `@riverpod` annotations
- Clone the project for the first time

### Commands:

```bash
# Generate once
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes (recommended during development)
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

## Platform-Specific Setup

### Android

Minimum SDK version is already set to 21 in the project.

If you need to change it, edit `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21
}
```

### iOS

Run pod install (only needed once):

```bash
cd ios
pod install
cd ..
```

## Testing the App

Since you probably don't have a backend running yet, the app will show network errors on login. That's expected!

To test the UI:
1. Run the app
2. Enter any username/password
3. You'll see an error (because backend isn't running)

## Next Steps

1. **Set up FastAPI Backend**: Follow the backend setup in the best practices document
2. **Configure Backend URL**: Update `api_constants.dart` with your backend URL
3. **Test Login**: Once backend is running, test the login flow
4. **Build Features**: Add new screens, services, and models as needed

## Troubleshooting

### "Target of URI hasn't been generated"

This means you haven't run code generation yet:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### "No devices found"

```bash
# List devices
flutter devices

# Start an emulator
flutter emulators --launch <emulator-id>
```

### Network Connection Issues

- Check that backend is running
- Verify the URL in `api_constants.dart`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For real devices, use your computer's IP address (not localhost)

## Architecture Quick Reference

```
Frontend (Flutter + Riverpod + Dio)
    ↓
HTTP/WebSocket
    ↓
Backend (FastAPI)
    ↓
Gemini AI API
```

**Key Files to Edit:**

- Add new screens: `lib/screens/`
- Add new services: `lib/services/`
- Add new models: `lib/models/` (don't forget to run build_runner!)
- Add new providers: `lib/providers/`
- Configure APIs: `lib/core/constants/api_constants.dart`
