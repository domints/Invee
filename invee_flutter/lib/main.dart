import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/auth_screen.dart';
import 'screens/create_item_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/main_shell.dart';
import 'screens/qr_scanner_screen.dart';
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
  static const _scannerChannel = EventChannel('io.szymanski.invee/scanner');

  bool _ready = false;
  Widget? _home;
  StreamSubscription<dynamic>? _scanSub;

  /// Whether the setup screen is currently active.
  bool _isSetup = false;

  /// Non-null api once connected and authenticated.
  ApiService? _api;

  /// Signals the SetupScreen to fill its URL field with a scanned config URL.
  final _externalScanUrl = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    // Always subscribe to the hardware scanner from the start so the
    // setup screen can receive config QR codes without needing a connection.
    _scanSub = _scannerChannel.receiveBroadcastStream().listen(
      _onScanRaw,
      onError: (_) {},
    );
    _init();
  }

  Future<void> _init() async {
    final url = await PreferencesService.getServerUrl();
    if (!mounted) return;

    if (url == null || url.isEmpty) {
      setState(() {
        _isSetup = true;
        _home = _buildSetupScreen();
        _ready = true;
      });
      return;
    }

    final api = ApiService(url);

    final health = await api.checkHealth();
    if (!mounted) return;

    if (health == null) {
      setState(() {
        _isSetup = true;
        _home = _buildSetupScreen();
        _ready = true;
      });
      return;
    }

    final authed = await api.verifyAuth();
    if (!mounted) return;

    if (!authed) {
      setState(() {
        _home = _buildAuthGate(url, api);
        _ready = true;
      });
    } else {
      _api = api;
      setState(() {
        _isSetup = false;
        _home = MainShell(apiService: api);
        _ready = true;
      });
    }
  }

  Widget _buildSetupScreen() {
    return SetupScreen(
      onConnected: _onConnected,
      externalScanUrl: _externalScanUrl,
      onScanQr: _openCameraScanner,
    );
  }

  Widget _buildAuthGate(String url, ApiService api) {
    return AuthScreen(
      baseUrl: url,
      onAuthenticated: () {
        if (!mounted) return;
        _api = api;
        setState(() {
          _isSetup = false;
          _home = MainShell(apiService: api);
        });
      },
    );
  }

  void _onConnected(ApiService api) {
    _api = api;
    _isSetup = false;
  }

  /// Central scan handler for both the RK25 hardware scanner and the camera.
  ///
  /// Events have the shape `{'data': String, 'codeType': String?}` —
  /// matching the RK25 EventChannel broadcast and the value returned by
  /// [QrScannerScreen].
  void _onScanRaw(dynamic event) {
    if (event is! Map) return;
    final data = (event['data'] as String?)?.trim();
    if (data == null || data.isEmpty) return;

    if (_isSetup) {
      final url = _tryExtractConfigUrl(data);
      if (url != null) {
        _externalScanUrl.value = url;
      }
      // Ignore non-config scans while on setup screen.
      return;
    }

    final api = _api;
    if (api != null) _onScan(api, event);
  }

  /// Tries to parse a config QR payload and returns the server URL, or null.
  String? _tryExtractConfigUrl(String data) {
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final url = map['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  /// Opens the camera QR scanner and feeds the result through [_onScanRaw].
  Future<void> _openCameraScanner() async {
    final result = await Navigator.of(_navigatorKey.currentContext!).push<Map>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null) _onScanRaw(result);
  }

  Future<void> _onScan(ApiService api, dynamic event) async {
    if (event is! Map) return;
    final contents = (event['data'] as String?)?.trim();
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
    _externalScanUrl.dispose();
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
