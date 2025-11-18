import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket client wrapper for managing WebSocket connections
/// Provides additional features like auto-reconnect and error handling
class WebSocketClient {
  WebSocketChannel? _channel;
  final String url;
  final Duration reconnectDelay;
  bool _isDisposed = false;

  StreamController<dynamic>? _messageController;
  StreamController<bool>? _connectionStateController;

  WebSocketClient({
    required this.url,
    this.reconnectDelay = const Duration(seconds: 3),
  }) {
    _messageController = StreamController<dynamic>.broadcast();
    _connectionStateController = StreamController<bool>.broadcast();
  }

  /// Stream of incoming messages
  Stream<dynamic> get messages => _messageController!.stream;

  /// Stream of connection state (true = connected, false = disconnected)
  Stream<bool> get connectionState => _connectionStateController!.stream;

  /// Connect to WebSocket
  Future<void> connect() async {
    if (_isDisposed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _connectionStateController?.add(true);

      // Listen to messages
      _channel!.stream.listen(
        (message) {
          _messageController?.add(message);
        },
        onError: (error) {
          _handleError(error);
        },
        onDone: () {
          _handleDisconnection();
        },
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// Send message through WebSocket
  void send(dynamic message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  /// Close WebSocket connection
  Future<void> close() async {
    _isDisposed = true;
    await _channel?.sink.close();
    await _messageController?.close();
    await _connectionStateController?.close();
  }

  /// Handle connection errors
  void _handleError(dynamic error) {
    _connectionStateController?.add(false);
    // Optionally implement auto-reconnect here
    if (!_isDisposed) {
      Timer(reconnectDelay, () {
        if (!_isDisposed) {
          connect();
        }
      });
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _connectionStateController?.add(false);
    // Optionally implement auto-reconnect here
    if (!_isDisposed) {
      Timer(reconnectDelay, () {
        if (!_isDisposed) {
          connect();
        }
      });
    }
  }
}
