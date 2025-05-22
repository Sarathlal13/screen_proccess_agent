import 'package:flutter/material.dart';
import 'package:screen_proccess_agent/login.dart';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:screen_proccess_agent/websocket_chanel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<Map<String, String>> messages = [];
  AssistantWebSocket assistantSocket = AssistantWebSocket();
  String? latestTranscript;
  String? lastSentTranscript;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void startScreenSharing({int intervalSeconds = 3}) {
    js.context.callMethod('startScreenCapture', [intervalSeconds]);
  }

  void stopScreenSharing() {
    js.context.callMethod('stopScreenCapture');
  }

  void startSpeechRecognition() {
    // Bind Dart callback to global JS function
    js.context['onTranscriptReceived'] = js.allowInterop((String transcript) {
      print("🗣️ Transcript received: $transcript");
      latestTranscript = transcript;
    });

    // Start listening via JS
    js.context.callMethod('startListening');
  }

  void stopSpeechRecognition() {
    js.context.callMethod('stopListening');
  }

  // void setupScreenSnapshotListener() {
  //   html.window.addEventListener('onScreenSnapshot', (event) {
  //     final customEvent = event as html.CustomEvent;
  //     final base64Image = customEvent.detail as String;

  //     if (latestTranscript != null && latestTranscript!.isNotEmpty) {
  //       assistantSocket.sendAssistantRequest(
  //         transcript: latestTranscript!,
  //         base64Image: base64Image,
  //       );

  //       print(
  //           "📤 Sent to assistant: $latestTranscript ${base64Image.substring(0, 5)}");
  //       latestTranscript = null; // Reset after sending
  //     } else {
  //       print("⚠️ No transcript yet, skipping send.");
  //     }
  //   });
  // }

  void setupScreenSnapshotListener() {
    html.window.addEventListener('onScreenSnapshot', (event) {
      final customEvent = event as html.CustomEvent;
      final base64Image = customEvent.detail as String;

      if (latestTranscript != null &&
          latestTranscript!.isNotEmpty &&
          latestTranscript != lastSentTranscript) {
        assistantSocket.sendAssistantRequest(
          transcript: latestTranscript!,
          base64Image: base64Image,
        );

        print(
            "📤 Sent to assistant: $latestTranscript ${base64Image.substring(0, 5)}");

        lastSentTranscript = latestTranscript; // Save to avoid repeat
        latestTranscript = null; // Reset after sending
      } else {
        if (latestTranscript == lastSentTranscript) {
          print("Duplicate transcript, skipping send.");
        } else {
          print("No transcript yet, skipping send.");
        }
      }
    });
  }

  bool isAssistantOpen = false;

  void toggleAssistant() {
    setState(() {
      isAssistantOpen = !isAssistantOpen;
    });

    if (isAssistantOpen) {
      // Start voice and screen sharing
      startSpeechRecognition();
      startScreenSharing(intervalSeconds: 3);

      setupScreenSnapshotListener();

      // Set up speech result handler (if using JS interop handlers)
    } else {
      // Stop everything
      stopSpeechRecognition();
      stopScreenSharing();
    }
  }

  @override
  void initState() {
    super.initState();
    assistantSocket.connect();
    // // Listen for voice input result from JS
    // html.window
    //     .addEventListener("flutterInAppWebViewPlatformReady", (_) {
    //       js.context['flutter_inappwebview'].callMethod('addJavaScriptHandler', [
    //         'onVoiceInput',
    //         (text) {
    //           setState(() {
    //             _textController.text = text;
    //           });
    //           return null;
    //         }
    //       ]);
    //     });

    startSpeechRecognition();
    startScreenSharing(intervalSeconds: 5);

    setupScreenSnapshotListener();
  }

  @override
  void dispose() {
    stopSpeechRecognition();
    stopScreenSharing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromARGB(239, 9, 218, 33))),
                onPressed: () {
                  Navigator.push(
                      context,
                      (MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      )));
                },
                child: Text('Login'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleAssistant,
        tooltip: 'Increment',
        child: const Icon(Icons.chat),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class AssistantDialog extends StatefulWidget {
  final Function(String message) onSendMessage;

  const AssistantDialog({super.key, required this.onSendMessage});

  @override
  State<AssistantDialog> createState() => _AssistantDialogState();
}

class _AssistantDialogState extends State<AssistantDialog> {
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _textController = TextEditingController();

  void _startVoiceInput() {
    js.context.callMethod('startVoiceRecognition');
  }

  void _speakText(String text) {
    js.context.callMethod('speakText', [text]);
  }

  void _captureScreen() {
    js.context.callMethod('captureScreen');
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _chatHistory.add({'role': 'user', 'text': text});
      });
      widget.onSendMessage(text);
      _textController.clear();

      // Simulate assistant response
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _chatHistory.add({'role': 'assistant', 'text': "Got it: $text"});
        });
        _speakText("Got it: $text");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Onscreen Assistant",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final msg = _chatHistory[index];
                  return Align(
                    alignment: msg['role'] == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: msg['role'] == 'user'
                            ? Colors.blue[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(msg['text'] ?? ""),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: _startVoiceInput,
                  tooltip: 'Start Voice Input',
                ),
                IconButton(
                  icon: const Icon(Icons.screen_share),
                  onPressed: _captureScreen,
                  tooltip: 'Share Screen',
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration:
                        const InputDecoration(hintText: 'Type your message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
