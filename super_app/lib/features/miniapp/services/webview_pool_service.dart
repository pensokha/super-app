import 'dart:collection';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A service to manage a pool of WebViewController instances for performance optimization.
///
/// This helps reduce Mini App load times by pre-warming WebViews in the background.
class WebViewPoolService {
  // Singleton instance
  static final WebViewPoolService _instance = WebViewPoolService._internal();
  factory WebViewPoolService() => _instance;
  WebViewPoolService._internal();

  // The pool of idle WebViewController instances
  final Queue<WebViewController> _pool = Queue<WebViewController>();
  final int _maxPoolSize = 2; // Maximum number of WebViews to keep in the pool

  /// Initializes the WebView pool by pre-warming a specified number of WebViews.
  ///
  /// This should be called early in the application lifecycle (e.g., in main.dart).
  Future<void> init() async {
    if (_pool.isEmpty) {
      debugPrint('WebViewPoolService: Initializing pool with $_maxPoolSize WebViews...');
      for (int i = 0; i < _maxPoolSize; i++) {
        await _createAndAddControllerToPool();
      }
      debugPrint('WebViewPoolService: Pool initialized.');
    }
  }

  /// Acquires a WebViewController from the pool.
  /// If the pool is empty, a new controller is created.
  /// The acquired controller is guaranteed to be in a clean state (loaded with 'about:blank').
  Future<WebViewController> acquireController() async {
    if (_pool.isNotEmpty) {
      debugPrint('WebViewPoolService: Acquiring controller from pool.');
      return _pool.removeFirst();
    } else {
      debugPrint('WebViewPoolService: Pool empty, creating new controller.');
      return await _createCleanController();
    }
  }

  /// Releases a WebViewController back to the pool.
  /// The controller's content is cleared by loading 'about:blank' before returning it to the pool.
  Future<void> releaseController(WebViewController controller) async {
    // Clear the WebView's content to prevent state leakage between Mini Apps
    await controller.loadRequest(Uri.parse('about:blank'));
    if (_pool.length < _maxPoolSize) {
      debugPrint('WebViewPoolService: Releasing controller to pool.');
      _pool.addLast(controller);
    } else {
      debugPrint('WebViewPoolService: Pool full, disposing controller.');
      // If the pool is full, dispose of the controller to free up resources
      // Note: webview_flutter does not expose a direct dispose method for WebViewController
      // The controller will eventually be garbage collected when no longer referenced.
      // For now, simply dropping it from the pool is the best we can do.
    }
  }

  /// Disposes all WebViewController instances currently in the pool.
  ///
  /// This should be called when the application is shutting down.
  void dispose() {
    debugPrint('WebViewPoolService: Disposing all controllers in pool.');
    _pool.clear(); // Controllers will be garbage collected
  }

  /// Creates a new WebViewController and loads 'about:blank' to ensure a clean state.
  Future<WebViewController> _createCleanController() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    await controller.loadRequest(Uri.parse('about:blank'));
    return controller;
  }

  Future<void> _createAndAddControllerToPool() async {
    final controller = await _createCleanController();
    _pool.addLast(controller);
  }
}