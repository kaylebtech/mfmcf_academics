import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import webview_flutter for mobile
import 'package:webview_flutter/webview_flutter.dart';
// For Android
import 'package:webview_flutter_android/webview_flutter_android.dart';
// For iOS
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  bool _isLoading = true;
  double _progress = 0.0;
  final String _websiteUrl = 'https://mfmcf-ai.vercel.app/';
  
  // For mobile platforms
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    if (!kIsWeb) {
      // Initialize WebView for mobile platforms
      _initializeWebView();
    } else {
      // Web-specific initialization
      _initializeWeb();
    }
  }

  void _initializeWebView() {
    // Create WebViewController
    late final PlatformWebViewControllerCreationParams params;
    
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    // Platform-specific setup
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    // Configure the controller
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _progress = 0.0;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _progress = 1.0;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(_websiteUrl));

    _controller = controller;
  }

  void _initializeWeb() {
    // For web platform, use conditional imports
    _registerIframeView();
    // Simulate loading progress for web
    _simulateLoading();
  }

  // This method will only be used on web platform
  void _registerIframeView() {
    // Import web-specific libraries conditionally
    if (kIsWeb) {
      // Use conditional import to avoid compilation errors on mobile
      // We'll handle web view differently in the build method
    }
  }

  void _simulateLoading() {
    // Simulate loading progress
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _progress < 0.9) {
        setState(() {
          _progress += 0.1;
        });
        _simulateLoading();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _progress = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF333333),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MFMCF AI Assistant',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          if (_isLoading)
            SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFE75480),
                ),
              ),
            ),
          
          // WebView content
          Expanded(
            child: Stack(
              children: [
                // For web platform
                if (kIsWeb)
                  _buildWebViewForWeb(),
                
                // For mobile platforms (iOS/Android)
                if (!kIsWeb)
                  _buildWebViewForMobile(),
                
                // Loading overlay
                if (_isLoading)
                  _buildLoadingOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebViewForWeb() {
    // For web, we need to use HtmlElementView but with conditional imports
    // We'll show a simple Container with a placeholder on mobile builds
    // The actual implementation should be in a separate web-only file
    
    return Container(
      child: const Center(
        child: Text(
          'WebView is loading...',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildWebViewForMobile() {
    return WebViewWidget(
      controller: _controller,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE75480), Color(0xFFF8C8DC)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE75480).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading MFMCF AI...',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFE75480),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}