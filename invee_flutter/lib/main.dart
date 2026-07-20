import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'active_item.dart';
import 'models/barcode_type.dart';
import 'screens/auth_screen.dart';
import 'screens/create_item_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/main_shell.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/storage_detail_screen.dart';
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
          seedColor: const Color(0xFFFDC434),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFDC434),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
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

  /// Deep-link (invee:// custom scheme) handling.
  StreamSubscription<Uri>? _linkSub;

  /// A link received before the api/session was ready; processed once connected.
  Uri? _pendingLink;

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
    _initDeepLinks();
  }

  /// Subscribes to `invee://` custom-scheme links used for short-link handoff
  /// from the phone's browser (e.g. `invee://item?slug=bosch-gbh-228-f`).
  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handleIncomingLink(initial);
    } catch (_) {}
    _linkSub = appLinks.uriLinkStream.listen(_handleIncomingLink, onError: (_) {});
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme != 'invee') return;
    final api = _api;
    if (api == null) {
      // Buffer until the app is connected and authenticated.
      _pendingLink = uri;
      return;
    }
    _resolveAndNavigate(api, uri);
  }

  /// Processes a buffered link once [_api] is available and a navigable shell
  /// is mounted.
  void _processPendingLink() {
    final pending = _pendingLink;
    final api = _api;
    if (pending == null || api == null) return;
    _pendingLink = null;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resolveAndNavigate(api, pending),
    );
  }

  /// Resolves the slug encoded in [uri] to an item (preferred) or storage and
  /// navigates to the matching detail screen. Silently ignores unresolved links.
  Future<void> _resolveAndNavigate(ApiService api, Uri uri) async {
    final slug = uri.queryParameters['slug']?.trim();
    if (slug == null || slug.isEmpty) return;
    final kind = uri.host;

    Future<void> pushStorage() async {
      final storage = await api.getStorageBySlug(slug);
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => StorageDetailScreen(
            storageId: storage.id,
            storageName: storage.name,
            apiService: api,
          ),
        ),
      );
    }

    try {
      if (kind == 'storage') {
        await pushStorage();
        return;
      }
      // 'item' (or unspecified): try item first, then fall back to storage.
      try {
        final item = await api.getItemBySlug(slug);
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item.id, apiService: api),
          ),
        );
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
        await pushStorage();
      }
    } catch (_) {
      // Unresolved link — ignore.
    }
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

    await PreferencesService.setShortLinkConfig(
      shortHost: health.shortHost,
      canonicalBaseUrl: health.canonicalBaseUrl,
    );

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
      _processPendingLink();
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
        _processPendingLink();
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
      final config = _tryExtractConfig(data);
      if (config != null) {
        final token = config['token'] as String?;
        if (token != null && token.isNotEmpty) {
          // Pre-store the token so verifyAuth() succeeds without the OIDC flow.
          AuthService.setJwtToken(token);
        }
        _externalScanUrl.value = config['url'] as String;
      }
      // Ignore non-config scans while on setup screen.
      return;
    }

    final api = _api;
    if (api != null) _onScan(api, event);
  }

  /// Tries to parse a config QR payload. Returns the full map if `url` is
  /// present (may also contain `token`), otherwise null.
  Map<String, dynamic>? _tryExtractConfig(String data) {
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final url = map['url'] as String?;
      if (url != null && url.isNotEmpty) return map;
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

    final apiInt = BarcodeType.fromCipherlab(codeType);
    dev.log(
      '[scan] barcode="$contents"  codeType="$codeType"  → apiInt=$apiInt',
      name: 'BarcodeType',
    );

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

    final activeId = ActiveItemState.itemId;
    final activeName = ActiveItemState.itemName;
    final codeTypeInt = BarcodeType.fromCipherlab(codeType);
    final canAddToActive = activeId != null && codeTypeInt != null;

    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Barcode not recognized'),
        content: Text(
          canAddToActive
              ? 'No item found for:\n$contents\n\nAdd it to "${activeName ?? 'current item'}"?'
              : 'No item found for barcode:\n$contents\n\nWould you like to create a new item with this barcode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          if (canAddToActive)
            OutlinedButton(
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
              child: const Text('Create new'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              if (canAddToActive) {
                try {
                  await api.addItemCode(activeId, codeTypeInt, contents);
                  ActiveItemState.onReload?.call();
                } catch (e) {
                  final errCtx = _navigatorKey.currentContext;
                  if (errCtx != null && errCtx.mounted) {
                    ScaffoldMessenger.of(errCtx).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add barcode: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } else {
                _navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => CreateItemScreen(
                      apiService: api,
                      prefillBarcode: contents,
                      prefillCodeType: codeType,
                    ),
                  ),
                );
              }
            },
            child: Text(canAddToActive ? 'Add to item' : 'Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _linkSub?.cancel();
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
