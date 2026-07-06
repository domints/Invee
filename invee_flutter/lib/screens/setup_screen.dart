import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import 'auth_screen.dart';
import 'category_browser_screen.dart';

class SetupScreen extends StatefulWidget {
  /// Called with the ready [ApiService] after URL is saved and auth succeeds.
  final void Function(ApiService api)? onConnected;

  const SetupScreen({super.key, this.onConnected});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  String? _error;
  HealthResponse? _health;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testAndConnect() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Please enter a server URL.');
      return;
    }

    final url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;

    setState(() {
      _testing = true;
      _error = null;
      _health = null;
    });

    try {
      final api = ApiService(url);
      final health = await api.checkHealth();
      if (!mounted) return;

      if (health == null) {
        setState(() => _error = 'Could not reach the server. Check the URL and try again.');
        return;
      }

      if (health.database != 'ok') {
        setState(() => _error = 'Server is reachable but the database is unavailable.');
        return;
      }

      setState(() => _health = health);
      await PreferencesService.setServerUrl(url);
      if (!mounted) return;

      // Proceed to auth
      final authed = await _ensureAuth(url, api);
      if (!mounted) return;

      if (authed) {
        widget.onConnected?.call(api);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CategoryBrowserScreen(apiService: api),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  /// Opens [AuthScreen] if not already authenticated; returns true on success.
  Future<bool> _ensureAuth(String url, ApiService api) async {
    final alreadyAuthed = await api.verifyAuth();
    if (alreadyAuthed) return true;

    if (!mounted) return false;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AuthScreen(baseUrl: url)),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect to Invee',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the root URL of your Invee server to get started.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _testAndConnect(),
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'https://invee.example.com',
                    prefixIcon: const Icon(Icons.link),
                    border: const OutlineInputBorder(),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _testing ? null : _testAndConnect,
                  icon: _testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cable),
                  label: Text(_testing ? 'Connecting…' : 'Test & Connect'),
                ),
                if (_health != null) ...[
                  const SizedBox(height: 20),
                  _ServerInfoChip(health: _health!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerInfoChip extends StatelessWidget {
  final HealthResponse health;

  const _ServerInfoChip({required this.health});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = health.isHealthy
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final textColor = health.isHealthy
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            health.isHealthy ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Text(
            'v${health.version}  •  DB ${health.database}',
            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
