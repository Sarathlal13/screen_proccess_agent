import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:web_socket_channel/html.dart';

class AssistantWebSocket {
  late HtmlWebSocketChannel _channel;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isWaitingForResponse = false;

  void connect() {
    _channel = HtmlWebSocketChannel.connect(
        'ws://localhost:8080/ws/assistant?provider=gemini');

    _channel.stream.listen((message) {
      print('message $message');
      final data = jsonDecode(message);
      // Handle response from backend
      final reply = data['reply'];
      print("Assistant: $reply");
      _speak(reply);
      _isWaitingForResponse = false; // reset flag
    });
  }

  void sendAssistantRequest({
    required String transcript,
    required String base64Image,
  }) {
    if (_isWaitingForResponse) return; // skip if already waiting

    final data = {
      "transcript": transcript,
      "image": base64Image,
    };

    // print(data);
    _isWaitingForResponse = true;

    _channel.sink.add(jsonEncode(data));
  }

  void dispose() {
    _channel.sink.close();
    _flutterTts.stop();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(1);
    await _flutterTts.speak(text);
  }
}
