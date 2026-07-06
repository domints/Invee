import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/auth_service.dart';

/// Full-screen WebView that drives the OIDC login flow.
///
/// Opens `{baseUrl}/api/auth?redirect={baseUrl}/` in an in-app browser.
/// After the server completes the OIDC round-trip it redirects back to the
/// base URL.  The WebView then has the short-lived `.AspNetCore.Cookies`
/// session cookie.  We extract it, call `/api/auth/mobile-token` to exchange
/// it for a long-lived JWT, store the JWT in secure storage via [AuthService],
/// and pop with `true`.
///
/// Popping with `false` means the user cancelled or the exchange failed.
class AuthScreen extends StatefulWidget {
  final String baseUrl;

  /// Called after the JWT has been stored successfully.
  final VoidCallback? onAuthenticated;

  const AuthScreen({super.key, required this.baseUrl, this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = true;
  bool _completing = false;

  String get _authUrl {
    final base = widget.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/api/auth?redirect=$base/';
  }

  bool _isPostLoginUrl(String url) {
    final base = widget.baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (!url.startsWith(base)) return false;
    final path = url.substring(base.length);
    return path == '/' || path == '' || path == '/index.html';
  }

  Future<void> _onAuthComplete() async {
    if (_completing) return;
    _completing = true;

    try {
      final base = widget.baseUrl.replaceAll(RegExp(r'/+$'), '');
      final cookieManager = CookieManager.instance();
      final cookie = await cookieManager.getCookie(
        url: WebUri(base),
        name: '.AspNetCore.Cookies',
      );

      if (cookie == null) {
        _completing = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sign-in did not complete. Please try again.')),
          );
        }
        return;
      }

      final cookieHeader = '${cookie.name}=${cookie.value}';
      final ok = await AuthService.exchangeCookieForJwt(base, cookieHeader);

      if (ok && mounted) {
        widget.onAuthenticated?.call();
        Navigator.of(context).pop(true);
      } else if (mounted) {
        _completing = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to obtain access token. Please try again.')),
        );
      }
    } catch (e) {
      _completing = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing sign-in: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_authUrl)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              javaScriptEnabled: true,
            ),
            onLoadStart: (controller, url) {
              if (mounted) setState(() => _loading = true);
            },
            onLoadStop: (controller, url) {
              if (mounted) setState(() => _loading = false);
              // Fallback: if shouldOverrideUrlLoading was not fired for a redirect
              if (url != null && _isPostLoginUrl(url.toString())) {
                _onAuthComplete();
              }
            },
            shouldOverrideUrlLoading: (controller, action) async {
              final url = action.request.url?.toString() ?? '';
              if (_isPostLoginUrl(url)) {
                _onAuthComplete();
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
