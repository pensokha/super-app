import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:super_app/features/miniapp/services/webview_pool_service.dart';
import 'package:super_app/features/miniapp/models/miniapp_manifest.dart';

class MiniAppContainerScreen extends StatefulWidget {
  final String url;
  final MiniAppManifest manifest;

  const MiniAppContainerScreen({super.key, required this.url, required this.manifest});

  @override
  State<MiniAppContainerScreen> createState() => _MiniAppContainerScreenState();
}

class _MiniAppContainerScreenState extends State<MiniAppContainerScreen> {
  late WebViewController _controller; // Changed to non-final as it's acquired from pool
  int _loadingPercentage = 0;
  bool _isPageFinished = false; // Add a flag to track if the page is ready.
  bool _isLoggedIn = false; // Mock authentication state
  bool _isWebViewInitialized = false; // New flag to track WebView initialization
  late final Set<String> _allowedPermissions;
  final WebViewPoolService _webViewPoolService = WebViewPoolService();

  @override
  void initState() {
    super.initState();

    _allowedPermissions = widget.manifest.permissions.toSet();

    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = await _webViewPoolService.acquireController();
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Set these properties here
      ..setBackgroundColor(const Color(0x00000000)) // as they are part of the controller setup
      // and not specific to navigation.
      // The setNavigationDelegate is also part of the controller setup.
      // It's better to set these once the controller is acquired.
      ..setNavigationDelegate( // Set navigation delegate after acquiring
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

    // Once the controller is fully set up and has started loading, mark it as initialized.
    if (mounted) {
      setState(() => _isWebViewInitialized = true);
    }
  }

  @override
  void dispose() {
    _webViewPoolService.releaseController(_controller); // Release controller back to pool
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini App')),
      body: Stack(
        children: [
          // Render WebViewWidget if initialized, otherwise show loading indicator
          _isWebViewInitialized
              ? WebViewWidget(controller: _controller)
              : const Center(child: CircularProgressIndicator()),

          // Show linear progress indicator only if WebView is initialized and loading
          if (_isWebViewInitialized && _loadingPercentage < 100)
            LinearProgressIndicator(
              value: _loadingPercentage / 100.0,
            ),
        ],
      ),
      floatingActionButton: _isWebViewInitialized ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
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
      );
  }

  void _handleJavaScriptMessage(String jsonString) async {
    // Guard against handling messages if the page isn't ready to receive a response.
    if (!_isPageFinished) {
      debugPrint('Page not finished loading. Ignoring message from JS.');
      return;
    }

    Map<String, dynamic> message;
    String? method;
    int? id;

    try {
      message = jsonDecode(jsonString);
      method = message['method'];
      id = message['id'];

      if (method == null || id == null) {
        debugPrint('Invalid message format: method or id missing. Message: $jsonString');
        return; // Cannot send error response as id is missing
      }

      // --- Permissions Check ---
      if (!_allowedPermissions.contains(method)) {
        debugPrint('Permission denied for method: $method in Mini App: ${widget.manifest.name}');
        await _sendErrorResponse(id, 403, 'Permission denied for method: $method');
        return;
      }
      debugPrint('Received method: $method with id: $id');

      switch (method) {
        // --- User Service ---
        case 'user.getUserInfo':
          // Simulate fetching user data from a service
          final user = {
            'name': 'Sokha Pen (from Flutter)',
            'id': '12345',
            'email': 'sokhapen@superapp.com',
          };
          await _sendSuccessResponse(id, user);
          break;
        case 'device.getBatteryLevel':
          try {
            final battery = Battery();
            final batteryLevel = await battery.batteryLevel;
            await _sendSuccessResponse(id, batteryLevel);
          } on PlatformException catch (e) {
            debugPrint('Failed to get battery level: ${e.message}');
            await _sendErrorResponse(
                id, -32000, e.message ?? 'Battery info unavailable');
          } catch (e) {
            debugPrint(
                'An unexpected error occurred while getting battery level: $e');
            await _sendErrorResponse(id, -32603, 'Internal server error');
          }
          break;

        // --- Auth Service ---
        case 'auth.login':
          // Simulate a login process
          // In a real app, this would involve calling an actual auth service
          _isLoggedIn = true;
          await _sendSuccessResponse(id, {'token': 'mock_jwt_token_12345'});
          break;
        case 'auth.logout':
          // Simulate a logout process
          _isLoggedIn = false;
          await _sendSuccessResponse(id, true);
          break;
        case 'auth.getToken':
          if (_isLoggedIn) {
            await _sendSuccessResponse(id, 'mock_jwt_token_12345');
          } else {
            await _sendErrorResponse(id, 401, 'User not logged in');
          }
          break;

        // --- Payment Service ---
        case 'payment.initiatePayment':
          if (!_isLoggedIn) {
            await _sendErrorResponse(id, 401, 'Login required to initiate payment');
            break;
          }

          // Safely parse amount, handling both int and double from JSON
          final dynamic rawAmount = message['params']['amount'];
          final double? amount = rawAmount is num ? rawAmount.toDouble() : null;
          final String? currency = message['params']['currency'];

          if (amount == null || currency == null) {
            await _sendErrorResponse(id, -32602, 'Invalid params: amount and currency are required');
            break;
          }

          if (amount <= 0) {
            await _sendErrorResponse(id, -32001, 'Payment amount must be positive');
            break;
          }

          // Simulate payment processing
          // In a real app, this would integrate with a payment gateway
          debugPrint('Simulating payment for $currency $amount');
          // Simulate a delay for payment processing
          await Future.delayed(const Duration(seconds: 2));

          // Randomly succeed or fail for demonstration
          if (amount > 1000) { // Example: payments over 1000 always fail
             await _sendErrorResponse(id, -32002, 'Payment failed: Amount too high for simulation');
          } else if (amount == 13.37) { // Example: specific amount fails
             await _sendErrorResponse(id, -32003, 'Payment failed: Transaction declined');
          }
          else {
            await _sendSuccessResponse(id, {
              'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
              'status': 'completed',
              'amount': amount,
              'currency': currency,
            });
          }
          break;
        default:
          debugPrint('Unknown method received from JS: $method');
          await _sendErrorResponse(id, -32601, 'Method not found: $method');
      }
    } catch (e) {
      debugPrint('Error parsing JavaScript message: $e');
    }
  }

  // --- Response Helper Methods ---

  Future<void> _sendResponse(Map<String, dynamic> payload) async {
    if (!_isPageFinished) {
      debugPrint('Page not ready, cannot send response.');
      return;
    }
    final responseString = jsonEncode(payload);
    final base64Response = base64Encode(utf8.encode(responseString));
    final script = "window.handleSuperAppResponseFromBase64('$base64Response')";
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('Error sending response to JS: $e');
    }
  }

  Future<void> _sendSuccessResponse(int id, dynamic result) async {
    await _sendResponse({
      'jsonrpc': '2.0',
      'result': result,
      'id': id,
    });
  }

  Future<void> _sendErrorResponse(int id, int code, String message) async {
    await _sendResponse({
      'jsonrpc': '2.0',
      'error': {'code': code, 'message': message},
      'id': id,
    });
  }
}
