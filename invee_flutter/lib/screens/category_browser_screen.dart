import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import 'item_list_screen.dart';
import 'setup_screen.dart';

class CategoryBrowserScreen extends StatefulWidget {
  final ApiService apiService;

  const CategoryBrowserScreen({super.key, required this.apiService});

  @override
  State<CategoryBrowserScreen> createState() => _CategoryBrowserScreenState();
}

class _CategoryBrowserScreenState extends State<CategoryBrowserScreen> {
  List<CategoryTreeResponse>? _tree;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tree = await widget.apiService.getCategoryTree();
      if (mounted) setState(() => _tree = tree);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Remove the saved server URL and return to setup?'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadTree,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server settings',
            onPressed: _disconnect,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadTree,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_tree == null || _tree!.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }
    return RefreshIndicator(
      onRefresh: _loadTree,
      child: ListView.builder(
        itemCount: _tree!.length,
        itemBuilder: (ctx, i) => _CategoryNode(
          category: _tree![i],
          apiService: widget.apiService,
          depth: 0,
        ),
      ),
    );
  }
}

class _CategoryNode extends StatelessWidget {
  final CategoryTreeResponse category;
  final ApiService apiService;
  final int depth;

  const _CategoryNode({
    required this.category,
    required this.apiService,
    required this.depth,
  });

  void _openItems(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemListScreen(
          categoryId: category.id,
          categoryName: category.name,
          apiService: apiService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = category.children.isNotEmpty;
    final indent = depth * 16.0;

    if (hasChildren) {
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: ExpansionTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(category.name),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.list_alt, size: 20),
                tooltip: 'View items',
                onPressed: () => _openItems(context),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: category.children
              .map(
                (child) => _CategoryNode(
                  category: child,
                  apiService: apiService,
                  depth: depth + 1,
                ),
              )
              .toList(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ListTile(
        leading: const Icon(Icons.folder_open_outlined),
        title: Text(category.name),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: () => _openItems(context),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
