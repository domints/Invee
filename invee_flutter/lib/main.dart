import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/auth_screen.dart';
import 'screens/category_browser_screen.dart';
import 'screens/create_item_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/setup_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/preferences_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  runApp(const InveeApp());
}

class InveeApp extends StatelessWidget {
  const InveeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invee',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _AppEntry(),
    );
  }
}

/// Resolves startup state and attaches the global barcode scanner listener.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  static const _scannerChannel =
      EventChannel('com.example.invee_flutter/scanner');

  bool _ready = false;
  Widget? _home;
  StreamSubscription<dynamic>? _scanSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = await PreferencesService.getServerUrl();
    if (!mounted) return;

    if (url == null || url.isEmpty) {
      setState(() {
        _home = SetupScreen(onConnected: _onConnected);
        _ready = true;
      });
      return;
    }

    final api = ApiService(url);

    // Verify server is reachable
    final health = await api.checkHealth();
    if (!mounted) return;

    if (health == null) {
      // Server unreachable – go back to setup
      setState(() {
        _home = SetupScreen(onConnected: _onConnected);
        _ready = true;
      });
      return;
    }

    // Check if session is still valid
    final authed = await api.verifyAuth();
    if (!mounted) return;

    if (!authed) {
      setState(() {
        _home = _buildAuthGate(url, api);
        _ready = true;
      });
    } else {
      _startScanListener(api);
      setState(() {
        _home = CategoryBrowserScreen(apiService: api);
        _ready = true;
      });
    }
  }

  /// Shows the auth screen and, on success, transitions to the main content.
  Widget _buildAuthGate(String url, ApiService api) {
    return AuthScreen(
      baseUrl: url,
      onAuthenticated: () {
        if (!mounted) return;
        _startScanListener(api);
        setState(() => _home = CategoryBrowserScreen(apiService: api));
      },
    );
  }

  void _onConnected(ApiService api) {
    _startScanListener(api);
  }

  void _startScanListener(ApiService api) {
    _scanSub?.cancel();
    _scanSub = _scannerChannel.receiveBroadcastStream().listen(
      (event) => _onScan(api, event),
      onError: (_) {},
    );
  }

  Future<void> _onScan(ApiService api, dynamic event) async {
    if (event is! Map) return;
    final contents = event['data'] as String?;
    final codeType = event['codeType'] as String?;
    if (contents == null || contents.isEmpty) return;

    try {
      final itemId = await api.lookupByCode(contents, codeType: codeType);
      if (itemId == null) {
        _showScanNotFound(api, contents, codeType);
        return;
      }
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ItemDetailScreen(itemId: itemId, apiService: api),
        ),
      );
    } catch (_) {
      _showScanNotFound(api, contents, codeType);
    }
  }

  void _showScanNotFound(ApiService api, String contents, String? codeType) {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Barcode not recognized'),
        content: Text(
          'No item found for barcode:\n$contents\n\nWould you like to create a new item with this barcode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => CreateItemScreen(
                    apiService: api,
                    prefillBarcode: contents,
                    prefillCodeType: codeType,
                  ),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _home!;
  }
}
