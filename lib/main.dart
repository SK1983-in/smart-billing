import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _lastUrl = "https://bookmyyaatra.com/smart/billing/index.php";

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _lastUrl = url;
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // External links handling
            if (url.startsWith("tel:") ||
                url.startsWith("mailto:") ||
                url.startsWith("whatsapp:") ||
                url.contains("wa.me") ||
                url.endsWith(".pdf") ||
                url.endsWith(".doc") ||
                url.endsWith(".xls")) {
              _launchExternal(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Show custom offline / error HTML
            _controller.loadHtmlString(_offlinePage());
          },
        ),
      )
      ..loadRequest(Uri.parse(_lastUrl), headers: {"Cache-Control": "no-cache"});
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  String _offlinePage() {
    return """
      <html>
        <body style="text-align:center; padding-top:50px; font-family:Arial;">
          <h2>Oops! Something went wrong</h2>
          <p>Check your internet connection or try again.</p>
          <button 
            style="padding:10px 20px; background:#007bff; color:white; border:none; border-radius:5px;"
            onclick="window.location.href='$_lastUrl'">
            Retry
          </button>
        </body>
      </html>
    """;
  }

  Future<bool> _handleBackPressed() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // don't exit app
    }
    return true; // exit app
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) {
            final shouldExit = await _handleBackPressed();
            if (shouldExit) {
              Navigator.of(context).maybePop();
            }
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              SafeArea(child: WebViewWidget(controller: _controller)),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}