# Dart and Flutter MCP Server Setup

This document describes the setup and configuration of the Dart and Flutter MCP server for this project.

## Installation Summary

✅ **Completed Setup**:
1. Flutter SDK 3.38.1 installed at `~/flutter`
2. Dart SDK 3.10.0 (included with Flutter)
3. PATH configured in `~/.bashrc`
4. MCP server configured in Claude Code

## Verification Commands

```bash
# Check Flutter version
flutter --version
# Expected: Flutter 3.38.1, Dart 3.10.0

# Check Dart MCP server
dart mcp-server --help
# Should show MCP server usage information

# Verify PATH
echo $PATH | grep flutter
# Should include: /home/rob/flutter/bin
```

## MCP Server Configuration

**Location**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "dart-flutter": {
      "command": "/home/rob/flutter/bin/dart",
      "args": ["mcp-server"],
      "env": {
        "FLUTTER_SDK": "/home/rob/flutter"
      },
      "description": "Dart and Flutter development tools - analyze errors, resolve symbols, introspect running apps, search pub.dev, manage dependencies, run tests, format code"
    }
  }
}
```

## What the MCP Server Provides

### For Development
- **Error Analysis**: Automatically detect and fix static/runtime errors
- **Symbol Resolution**: Get documentation and signatures for Dart/Flutter APIs
- **Package Discovery**: Search pub.dev and add dependencies automatically
- **Code Formatting**: Format code using dart format standards
- **Testing**: Run tests and analyze results

### For Running Apps
- **Widget Tree Inspection**: View live widget hierarchy
- **Runtime Error Detection**: Catch layout overflow and other runtime issues
- **Performance Analysis**: Identify bottlenecks in running apps

## Usage in Claude Code

The MCP server works automatically when:
- You're in a Flutter project (detected by `pubspec.yaml`)
- You're editing `.dart` files
- You request error analysis or fixes
- You ask about packages or dependencies

Example prompts that use the MCP server:
```
"Check for and fix any errors in the project"
"Find a package for handling charts"
"Add flutter_secure_storage as a dependency"
"Format all Dart files in the project"
"Analyze the widget tree for layout issues"
```

## Updating Flutter/Dart

To update to the latest version:

```bash
cd ~/flutter
flutter upgrade
```

This will:
- Download the latest Flutter SDK
- Update the Dart SDK
- Update all Flutter tools

## Verification Test Results

✅ **All Tests Passed** (2025-11-18)

Comprehensive verification performed:
- ✅ MCP configuration is correct
- ✅ Dart executable is available and working
- ✅ Flutter SDK is properly installed
- ✅ `dart mcp-server` command responds correctly
- ✅ `flutter analyze` successfully detects project issues (128 errors - expected, due to missing code generation)
- ✅ Environment variables configured

**Detailed Results**: See `MCP_VERIFICATION.md` for complete test output and analysis.

## Quick Test Commands

```bash
# Test MCP server command
/home/rob/flutter/bin/dart mcp-server --help

# Test Flutter analyze (should detect 128 issues before code generation)
flutter analyze

# Verify configuration
cat ~/.config/Claude/claude_desktop_config.json | python3 -m json.tool | grep -A 8 "dart-flutter"

# Check Dart version
/home/rob/flutter/bin/dart --version
```

## Troubleshooting

### MCP Server Not Found in MCP List

**Symptom**: `dart-flutter` doesn't appear when listing MCP servers

**Cause**: MCP servers load only at Claude Code startup

**Fix**:
1. Verify configuration exists (see Quick Test Commands above)
2. **Close and restart Claude Code completely**
3. MCP server will auto-load on startup
4. Test with: "List available Dart/Flutter MCP tools"

### MCP Server Not Found After Restart

If Claude Code can't find the MCP server even after restart:

1. Verify installation:
   ```bash
   /home/rob/flutter/bin/dart mcp-server --help
   # Should show usage information
   ```

2. Check configuration:
   ```bash
   cat ~/.config/Claude/claude_desktop_config.json | grep -A 8 "dart-flutter"
   ```

3. Verify JSON syntax:
   ```bash
   cat ~/.config/Claude/claude_desktop_config.json | python3 -m json.tool
   # Should output valid JSON without errors
   ```

4. Restart Claude Code to reload configuration

### Wrong Dart Version
If you see "Dart SDK 3.9+ required":

```bash
flutter upgrade
dart --version
# Should show Dart 3.9.0 or higher
```

### PATH Not Set
If `dart` command not found:

```bash
# Add to ~/.bashrc (should already be there)
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc

# Reload
source ~/.bashrc
```

## Additional Resources

- **Official Dart MCP Documentation**: https://dart.dev/tools/dart-mcp-server
- **Flutter Documentation**: https://flutter.dev
- **pub.dev Package Search**: https://pub.dev
- **MCP Protocol**: https://modelcontextprotocol.io

## Project-Specific Notes

This Flutter frontend integrates with:
- **auth-api** (port 8000) - Multi-step authentication
- **chat-api** (port 8001) - WebSocket real-time chat
- **activity-api** (port 8007) - Activity CRUD
- **image-api** (port 8009) - Image processing

The MCP server can help with:
- Debugging authentication flow issues
- Analyzing WebSocket connection code
- Finding packages for image handling
- Testing API integration code
