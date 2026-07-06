import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import 'add_category_screen.dart';
import 'add_storage_screen.dart';
import 'category_browser_screen.dart';
import 'search_screen.dart';
import 'setup_screen.dart';
import 'storage_browser_screen.dart';

enum _NavTab { categories, storages }

/// Top-level shell with a hamburger drawer for navigation between
/// "Browse by Category", "Browse by Storage", and "Search".
class MainShell extends StatefulWidget {
  final ApiService apiService;

  const MainShell({super.key, required this.apiService});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  _NavTab _tab = _NavTab.categories;

  final _catKey = GlobalKey<CategoryBrowserBodyState>();
  final _stoKey = GlobalKey<StorageBrowserBodyState>();

  String get _title =>
      _tab == _NavTab.categories ? 'Categories' : 'Storages';

  void _switchTab(_NavTab tab) {
    Navigator.of(context).pop(); // close drawer
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  Future<void> _refresh() async {
    if (_tab == _NavTab.categories) {
      await _catKey.currentState?.reload();
    } else {
      await _stoKey.currentState?.reload();
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(apiService: widget.apiService),
      ),
    );
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text(
            'Remove the saved server URL and return to setup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await PreferencesService.clearServerUrl();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      }
    }
  }

  Future<void> _onFabPressed() async {
    if (_tab == _NavTab.categories) {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddCategoryScreen(apiService: widget.apiService),
        ),
      );
      if (created == true) _catKey.currentState?.reload();
    } else {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddStorageScreen(apiService: widget.apiService),
        ),
      );
      if (created == true) _stoKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _tab.index,
        children: [
          CategoryBrowserBody(key: _catKey, apiService: widget.apiService),
          StorageBrowserBody(key: _stoKey, apiService: widget.apiService),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_shell_fab',
        onPressed: _onFabPressed,
        tooltip: _tab == _NavTab.categories
            ? 'Add category'
            : 'Add storage',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.inventory_2_rounded,
                  size: 44,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Invee',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Inventory Manager',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.folder_special_outlined,
            label: 'Browse by Category',
            selected: _tab == _NavTab.categories,
            onTap: () => _switchTab(_NavTab.categories),
          ),
          _DrawerItem(
            icon: Icons.warehouse_outlined,
            label: 'Browse by Storage',
            selected: _tab == _NavTab.storages,
            onTap: () => _switchTab(_NavTab.storages),
          ),
          _DrawerItem(
            icon: Icons.search,
            label: 'Search',
            selected: false,
            onTap: () {
              Navigator.of(context).pop();
              _openSearch();
            },
          ),
          const Divider(height: 1),
          _DrawerItem(
            icon: Icons.link_off,
            label: 'Disconnect',
            selected: false,
            onTap: () {
              Navigator.of(context).pop();
              _disconnect();
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: selected
            ? TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              )
            : null,
      ),
      selected: selected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
