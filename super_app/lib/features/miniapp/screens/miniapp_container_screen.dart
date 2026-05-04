import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MiniAppContainerScreen extends StatefulWidget {
  final String url;

  const MiniAppContainerScreen({super.key, required this.url});

  @override
  State<MiniAppContainerScreen> createState() => _MiniAppContainerScreenState();
}

class _MiniAppContainerScreenState extends State<MiniAppContainerScreen> {
  late final WebViewController _controller;
  int _loadingPercentage = 0;
  bool _isPageFinished = false; // Add a flag to track if the page is ready.

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingPercentage = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _loadingPercentage = 0;
              _isPageFinished = false; // Page is not ready when it starts loading.
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loadingPercentage = 100;
              _isPageFinished = true; // Page is ready for JS communication.
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  url: ${error.url}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
        ),
      )
      ..addJavaScriptChannel(
        'SuperAppBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini App')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Guard against calling JS before the page is fully loaded.
          if (!_isPageFinished) {
            debugPrint('Page not finished loading. Cannot send message to JS.');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mini App is still loading...')),
            );
            return;
          }

          // Example of Flutter initiating communication
          final message = 
              'Hello from Flutter! The time is ${DateTime.now().toIso8601String()}';
          // Encode to Base64 to safely pass data without worrying about escaping special characters.
          final base64Message = base64Encode(utf8.encode(message));
          try {
            _controller.runJavaScript("window.showFlutterMessageFromBase64('$base64Message')").catchError((e) => debugPrint('Error sending message to JS: $e'));
          } catch (e) {
            debugPrint('Caught synchronous error sending message to JS: $e');
          }
        },
        tooltip: 'Send Message to JS',
        child: const Icon(Icons.send),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loadingPercentage < 100)
            LinearProgressIndicator(
              value: _loadingPercentage / 100.0,
            ),
        ],
      ),
    );
  }

  void _handleJavaScriptMessage(String jsonString) async {
    // Guard against handling messages if the page isn't ready to receive a response.
    if (!_isPageFinished) {
      debugPrint('Page not finished loading. Ignoring message from JS.');
      return;
    }

    try {
      final message = jsonDecode(jsonString);
      final String method = message['method'];
      final int id = message['id'];

      debugPrint('Received method: $method with id: $id');

      switch (method) {
        case 'user.getUserInfo':
          // Simulate fetching user data from a service
          final user = {
            'name': 'Sokha Pen (from Flutter)',
            'id': '12345',
            'email': 'sokhapen@superapp.com',
          };

          // Create a success response payload
          final responsePayload = {
            'jsonrpc': '2.0',
            'result': user,
            'id': id,
          };

          // Encode the response to a JSON string, then to Base64 to safely pass it to JavaScript.
          final responseString = jsonEncode(responsePayload);
          final base64Response = base64Encode(utf8.encode(responseString));
          final script = "window.handleSuperAppResponseFromBase64('$base64Response')";
          try {
            await _controller.runJavaScript(script);
          } catch (e) {
            debugPrint('Error sending response to JS: $e');
          }
          break;
        case 'device.getBatteryLevel':
          final battery = Battery();
          final batteryLevel = await battery.batteryLevel;

          final responsePayload = {
            'jsonrpc': '2.0',
            'result': batteryLevel,
            'id': id,
          };

          final responseString = jsonEncode(responsePayload);
          final base64Response = base64Encode(utf8.encode(responseString));
          final script = "window.handleSuperAppResponseFromBase64('$base64Response')";
          try {
            await _controller.runJavaScript(script);
          } catch (e) {
            debugPrint('Error sending response to JS: $e');
          }
          break;
        default:
          debugPrint('Unknown method received from JS: $method');
      }
    } catch (e) {
      debugPrint('Error parsing JavaScript message: $e');
    }
  }
}
