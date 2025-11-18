import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/network/secure_storage_service.dart';

/// Gemini AI service for interacting with the FastAPI backend
class GeminiService {
  final Dio _dio;
  final SecureStorageService _storageService;

  GeminiService({
    required Dio dio,
    required SecureStorageService storageService,
  })  : _dio = dio,
        _storageService = storageService;

  /// Send a chat message (non-streaming)
  Future<Map<String, dynamic>> sendMessage(String message) async {
    final response = await _dio.post(
      ApiConstants.geminiChatEndpoint,
      data: {
        'message': message,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Connect to WebSocket for real-time streaming chat
  /// This is the recommended approach per best practices doc (not SSE)
  /// Returns a WebSocketChannel for bidirectional communication
  Future<WebSocketChannel> connectToChatWebSocket() async {
    // Get access token for authentication
    final accessToken = await _storageService.getAccessToken();

    // Build WebSocket URL with auth token as query parameter
    final wsUrl = Uri.parse(
      '${ApiConstants.wsBaseUrl}${ApiConstants.chatWebSocketEndpoint}?token=$accessToken',
    );

    // Connect to WebSocket
    final channel = WebSocketChannel.connect(wsUrl);

    return channel;
  }

  /// Example: Stream messages to WebSocket and listen to responses
  /// This demonstrates the bidirectional nature of WebSockets
  Stream<String> streamChat(String message) async* {
    final channel = await connectToChatWebSocket();

    // Send message
    channel.sink.add(message);

    // Listen to responses
    await for (final response in channel.stream) {
      if (response is String) {
        yield response;
      } else {
        // Handle other data types if needed
        yield response.toString();
      }
    }

    // Clean up
    await channel.sink.close();
  }
}

/// Provider for GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final dio = ref.read(dioProvider);
  final storageService = ref.read(secureStorageServiceProvider);

  return GeminiService(
    dio: dio,
    storageService: storageService,
  );
});
