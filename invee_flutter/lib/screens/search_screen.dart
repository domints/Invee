import 'dart:async';

import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import 'category_detail_screen.dart';
import 'item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final ApiService apiService;

  const SearchScreen({super.key, required this.apiService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _query = '';
  List<ItemListEntry> _items = [];
  List<_FlatCategory> _matchedCategories = [];
  bool _loading = false;
  String? _error;

  List<_FlatCategory> _flatCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryTree();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryTree() async {
    try {
      final tree = await widget.apiService.getCategoryTree();
      if (!mounted) return;
      setState(() => _flatCategories = _flattenTree(tree));
    } catch (_) {
      // Category tree is optional for search; items still work
    }
  }

  void _onQueryChanged() {
    final q = _searchController.text.trim();
    if (q == _query) return;
    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _items = [];
        _matchedCategories = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _error = null;
    });
    try {
      final items = await widget.apiService.getAllItems(search: q);
      if (!mounted) return;
      final lowerQ = q.toLowerCase();
      final matchedCats = _flatCategories
          .where((c) => c.name.toLowerCase().contains(lowerQ))
          .toList();
      setState(() {
        _items = items;
        _matchedCategories = matchedCats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static List<_FlatCategory> _flattenTree(List<CategoryTreeResponse> nodes) {
    final result = <_FlatCategory>[];
    void walk(CategoryTreeResponse node) {
      result.add(_FlatCategory(id: node.id, name: node.name));
      for (final child in node.children) {
        walk(child);
      }
    }
    for (final root in nodes) {
      walk(root);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search items and categories…',
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear',
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Type to search items and categories',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

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
                onPressed: () => _search(_query),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final hasResults = _matchedCategories.isNotEmpty || _items.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No results for "$_query"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (_matchedCategories.isNotEmpty) ...[
          _buildSectionHeader(
              context, Icons.folder_special_outlined, 'Categories',
              _matchedCategories.length),
          ..._matchedCategories.map((c) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.folder_special_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                    size: 18,
                  ),
                ),
                title: Text(c.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(
                      categoryId: c.id,
                      categoryName: c.name,
                      apiService: widget.apiService,
                    ),
                  ),
                ),
              )),
        ],
        if (_items.isNotEmpty) ...[
          _buildSectionHeader(
              context, Icons.inventory_2_outlined, 'Items', _items.length),
          ..._items.map((item) => _ItemResultTile(
                item: item,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(
                      itemId: item.id,
                      apiService: widget.apiService,
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, IconData icon, String title, int count) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatCategory {
  final int id;
  final String name;
  const _FlatCategory({required this.id, required this.name});
}

class _ItemResultTile extends StatelessWidget {
  final ItemListEntry item;
  final VoidCallback onTap;

  const _ItemResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.inventory_2_outlined,
            size: 20, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(item.name),
      subtitle: item.tags.isNotEmpty
          ? Text(
              item.tags.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
